// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test, console2 } from "forge-std/Test.sol";
import { SmartAccount } from "src/SmartAccount.sol";
import { DeploySmartAccount, HelperConfig } from "script/DeploySmartAccount.s.sol";
import { MockERC20 } from "./mocks/MockERC20.sol";
import { PackedUserOperation } from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import { IEntryPoint } from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { ValidationData } from "lib/account-abstraction/contracts/core/Helpers.sol";
import { SendPackedUserOps } from "script/SendPackedUserOps.s.sol";
import { Invoice } from "src/Invoice.sol";
import { GasStation } from "src/GasStation.sol";

contract TestInvoice is Test {
    using MessageHashUtils for bytes32;

    SmartAccount smartAccount;
    HelperConfig config;
    DeploySmartAccount deploySmartAccount;
    SendPackedUserOps sendPackedUserOps;
    MockERC20 usdt;
    IEntryPoint entryPoint;
    Invoice invoice;
    GasStation gasStation;
    address user;
    uint256 userKey;
    address payable randomUser;
    address payable merchant;

    function setUp() public {
        config = new HelperConfig();
        deploySmartAccount = new DeploySmartAccount();
        sendPackedUserOps = new SendPackedUserOps();
        usdt = new MockERC20();
        entryPoint = IEntryPoint(config.getConfigByChainId(block.chainid).entryPoint);
        
        // Deploy gas station contract
        gasStation = new GasStation(); // Initialize with Invoice contract address
        
        // Fund the test contract first
        vm.deal(address(this), 100 ether);
        
        // Fund the gas station directly
        (bool success,) = address(gasStation).call{value: 20 ether}("");
        require(success, "Failed to send ETH to gas station");

        (user, userKey) = makeAddrAndKey("user");
        randomUser = payable(makeAddr("randomUser"));
        merchant = payable(makeAddr("merchant"));
        (config, smartAccount) = deploySmartAccount.deploySmartAccount();
        invoice = new Invoice(address(usdt), address(gasStation), smartAccount);
        vm.deal(address(smartAccount), 100 ether);
    } 


    // function test_EntryPointExecutePayInvoice() public {
    //     // SmartAccount -> Invoice.payInvoice() -> USDT.transferFrom() -> Merchant
    //     // Setup amounts
    //     uint256 amount = 1e18;
        
    //     // Mint tokens to smart account
    //     vm.prank(address(smartAccount));
    //     usdt.mint();
        
    //     // Smart account approves the Invoice contract for transfers
    //     vm.prank(address(smartAccount));
    //     usdt.approve(address(invoice), amount);
        
    //     // Create the call to Invoice.payInvoice()
    //     bytes memory data = abi.encodeWithSelector(
    //         Invoice.payInvoice.selector,
    //         address(smartAccount), // customer
    //         merchant,             // merchant
    //         amount               // amount
    //     );
        
    //     // Create execution call
    //     bytes memory executeCallData = abi.encodeWithSelector(
    //         smartAccount.execute.selector,
    //         address(invoice),  // target is now Invoice contract
    //         0,                // no value sent
    //         data
    //     );

    //     // Create paymaster data (in this case, empty bytes since our mock paymaster accepts everything)
    //     bytes memory paymasterData = abi.encodePacked(address(paymaster));
        
    //     // Create and sign user operation
    //     PackedUserOperation memory packedUserOp = sendPackedUserOps.createSignedUserOps(
    //         executeCallData,
    //         config.getConfig(),
    //         address(smartAccount),
    //         address(paymaster),
    //         paymasterData
    //     );
        
    //     // Execute via EntryPoint
    //     vm.startPrank(randomUser);  // randomUser is our gas sponsor
    //     PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
    //     userOps[0] = packedUserOp;
    //     IEntryPoint(config.getConfig().entryPoint).handleOps(userOps, randomUser);
        
    //     // Verify transfer
    //     assertEq(usdt.balanceOf(merchant), amount);
    // }

    function test_GasStationExecutePayInvoice() public {
        // SmartAccount -> Invoice.payInvoice() -> USDT.transferFrom() -> Merchant
        // Setup amounts
        uint256 amount = 1e18;
        
        // Mint tokens to smart account
        vm.prank(address(smartAccount));
        usdt.mint();
        
        // Smart account approves the Invoice contract for transfers
        vm.prank(address(smartAccount));
        usdt.approve(address(invoice), amount);
        
        // Create the call to Invoice.payInvoice()
        bytes memory data = abi.encodeWithSelector(
            Invoice.payInvoice.selector,
            address(smartAccount), // customer
            merchant,             // merchant
            amount                // amount
        );

        // Sponsor the transaction via the gas station
        vm.startPrank(address(gasStation));  // randomUser sponsors gas
        gasStation.sponsorTransaction(address(invoice), data, 100000); // Adjust gas limit as needed
        vm.stopPrank();

        // Verify transfer
        assertEq(usdt.balanceOf(merchant), amount);
    }
}
