// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {MessageHashUtils} from "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";

contract SendPackedUserOps is Script {
    using MessageHashUtils for bytes32;
    function run() public {}

    function createSignedUserOps(
            bytes memory data, 
            HelperConfig.NetworkConfig memory config,
            address smartAccount,
            address paymaster,
            bytes memory paymasterData
        ) public view returns(PackedUserOperation memory) {
        // generate unsigned data
        uint256 nonce = vm.getNonce(smartAccount) - 1;
        PackedUserOperation memory userOp = _generateUnsignedUserOps(data, smartAccount, nonce, paymaster, paymasterData);
        // get user op hash 
        bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(userOp);
        bytes32 digest = userOpHash.toEthSignedMessageHash();
        // sign it, return it
        uint8 v; bytes32 r; bytes32 s;
        uint256 ANVIL_DEFAULT_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        if(block.chainid == 31337) {
            (v, r, s) = vm.sign(ANVIL_DEFAULT_PRIVATE_KEY, digest);
        } else {
            (v, r, s) = vm.sign(config.burner, digest);
        }
        userOp.signature = abi.encodePacked(r,s,v);
        return userOp;
    }

    function _generateUnsignedUserOps(
            bytes memory data, 
            address sender, 
            uint256 nonce,
            address paymaster,
            bytes memory paymasterData
        ) internal pure returns (PackedUserOperation memory) {
        uint128 verificationGasLimit = 16777216;
        uint128 callGasLimit = 16777216;
        uint128 maxPriorityFeePerGas = 256;  
        uint128 maxFeePerGas = 256;

        // Concatenate paymaster address with its associated data
        bytes memory paymasterAndData = paymaster != address(0) 
        ? bytes.concat(abi.encodePacked(paymaster), paymasterData)
        : bytes("");
    
        return PackedUserOperation({
            sender: sender,
            nonce: nonce,
            initCode: hex"",
            callData: data,
            accountGasLimits: bytes32(uint256(verificationGasLimit) << 128 | callGasLimit),
            preVerificationGas: verificationGasLimit,
            gasFees: bytes32(uint256(maxPriorityFeePerGas) << 128 | maxFeePerGas),
            paymasterAndData: paymasterData,
            signature: hex""
        });
    }
}