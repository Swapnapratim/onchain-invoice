// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GasStation {
    address public owner;

    event GasSponsorship(address indexed user, uint256 gasUsed, address indexed targetContract, bytes data);

    receive() external payable {}

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    // Function to sponsor any transaction
    function sponsorTransaction(
        address targetContract,
        bytes calldata data,
        uint256 gasLimit
    ) external {
        uint256 initialGas = gasleft();

        // Execute the target function call
        (bool success, ) = targetContract.call{gas: gasLimit}(data);
        require(success, "Transaction failed");

        // Calculate gas used
        uint256 gasUsed = initialGas - gasleft();
        require(gasUsed <= gasLimit, "Gas used exceeds gas limit");

        // Pay the gas fee (this contract must have sufficient balance)
        (bool reimbursementSuccess, ) = msg.sender.call{value: gasUsed * tx.gasprice}("");
        require(reimbursementSuccess, "Failed to reimburse gas");

        emit GasSponsorship(msg.sender, gasUsed, targetContract, data);
    }

    // Function to add native token balance to sponsor gas
    function deposit() external payable {}

    // Withdraw funds from gas station
    function withdraw(uint256 amount) external onlyOwner {
        payable(owner).transfer(amount);
    }
}
