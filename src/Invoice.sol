// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {SmartAccount} from "./SmartAccount.sol";

import { Test, console2 } from "forge-std/Test.sol";

contract Invoice is Ownable {
    IERC20 public immutable usdt; // USDT token contract
    address public gasSponsor; // Gas sponsor wallet/contract
    SmartAccount public smartAccount; // User's smart wallet

    event InvoicePaid(address indexed customer, address indexed merchant, uint256 amount);
    event GasSponsorChanged(address indexed newSponsor);

    modifier onlyGasSponsor() {
        console2.log(msg.sender);
        require(msg.sender == gasSponsor, "Only gas sponsor allowed");
        _;
    }

    constructor(address _usdt, address _gasSponsor, SmartAccount _smartAccount) Ownable(msg.sender){
        require(_usdt != address(0), "Invalid USDT address");
        require(_gasSponsor != address(0), "Invalid gas sponsor address");

        usdt = IERC20(_usdt);
        gasSponsor = _gasSponsor;
        smartAccount = _smartAccount;
    }

    /**
     * @notice Customer pays an invoice to the merchant in USDT.
     *         The payment transaction is sponsored by the gas sponsor through a relayer.
     * @param customer The customer (smart wallet) paying the invoice.
     * @param merchant The merchant receiving the payment.
     * @param amount The amount of USDT to be paid.
     */
    function payInvoice(
        address customer,
        address merchant,
        uint256 amount
    ) external onlyGasSponsor {
        console2.log("payInvoice called");
        require(merchant != address(0), "Invalid merchant address");
        require(amount > 0, "Amount must be greater than 0");
        
        // Transfer directly using USDT contract
        bool success = usdt.transferFrom(customer, merchant, amount);
        require(success, "Transfer failed");

        emit InvoicePaid(customer, merchant, amount);
    }

    /**
     * @notice Sponsor gas fees for the transaction.
     *         This allows the gas sponsor to pre-fund or pay the gas costs.
     *         The relayer submits the final transaction.
     * @param user The customer whose transaction is sponsored.
     * @param gasAmount The amount of gas to sponsor.
     */
    function sponsorGas(address user, uint256 gasAmount) external payable onlyGasSponsor {
        require(user != address(0), "Invalid user address");
        require(msg.value >= gasAmount, "Insufficient sponsorship");

        // Send Ether to the user's smart wallet for covering gas fees
        smartAccount.execute(user, msg.value, "");
    }

    /**
     * @notice Change the gas sponsor.
     * @param _newSponsor The new gas sponsor address.
     */
    function setGasSponsor(address _newSponsor) external onlyOwner {
        require(_newSponsor != address(0), "Invalid new sponsor address");
        gasSponsor = _newSponsor;

        emit GasSponsorChanged(_newSponsor);
    }
}
