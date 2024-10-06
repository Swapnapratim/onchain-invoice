// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IInvoiceContract {
    function payInvoice(address merchant, uint256 amountUSDT) external;
}