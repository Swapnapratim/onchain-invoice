// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAccount} from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {MessageHashUtils} from "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "lib/account-abstraction/contracts/core/Helpers.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol"; 

contract SmartAccount is IAccount, Ownable {

    IEntryPoint private immutable i_entryPoint;

    modifier onlyEntryPoint() {
        require(msg.sender == address(i_entryPoint), "only entrypoint");
        _;
    }
    modifier onlyEntryPointOrOwner() {
        require(msg.sender == address(i_entryPoint) || msg.sender == owner(), "only entrypoint or owner");
        _;
    }
    constructor(address _entryPoint) Ownable(msg.sender) {
        i_entryPoint = IEntryPoint(_entryPoint);
    }

    receive() external payable {}

    function execute(
        address target,
        uint256 value,
        bytes calldata data
    ) external onlyEntryPointOrOwner {
        (bool success, ) = target.call{value: value}(data);
        if(!success) {
            revert();
        }
    }

    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external onlyEntryPoint returns(uint256 validationData) {
        // validate the signature
        // NOTE: for this task, We are assuming that the signature is valid if its the Smart Account owner
        validationData = _validateSignature(userOp, userOpHash);
        // validateNonce -> done by entrypoint contract
        _payPrefund(missingAccountFunds);
    }

    // EIP-191 version
    function _validateSignature(
        PackedUserOperation calldata userOp, 
        bytes32 userOpHash
    ) internal view returns(uint256 validationData) {
        bytes32 signedMsgHash = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        bool isSigner = owner() == ECDSA.recover(signedMsgHash, userOp.signature);

        if(isSigner) {
            return SIG_VALIDATION_SUCCESS;
        }
        return SIG_VALIDATION_FAILED;
    }

    // payback the entry point contract for the missing funds
    function _payPrefund(uint256 missingAccountFunds) internal {
        if(missingAccountFunds !=0)  {
            (bool success, ) = payable(msg.sender).call{value: missingAccountFunds, gas: type(uint256).max}("");
            (success);
        }
    }

    /*//////////////////////////////////////////////////////////////
                             VIEW AND PURE
    //////////////////////////////////////////////////////////////*/
    function getEntryPoint() public view returns (IEntryPoint) {
        return i_entryPoint;
    }

    /**
     * Return the account nonce.
     * This method returns the next sequential nonce.
     * For a nonce of a specific key, use `entrypoint.getNonce(account, key)`
     */
    function getNonce() public view virtual returns (uint256) {
        return i_entryPoint.getNonce(address(this), 0);
    }

    /**
     * check current account deposit in the entryPoint
     */
    function getDeposit() public view returns (uint256) {
        return i_entryPoint.balanceOf(address(this));
    }

    /**
     * deposit more funds for this account in the entryPoint
     */
    function addDeposit() public payable {
        i_entryPoint.depositTo{ value: msg.value }(address(this));
    }
}