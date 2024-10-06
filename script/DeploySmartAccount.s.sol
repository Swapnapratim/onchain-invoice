// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {SmartAccount} from "../src/SmartAccount.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeploySmartAccount is Script {
    function run() public {}

    function deploySmartAccount() public returns(HelperConfig, SmartAccount) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        vm.startBroadcast(config.burner);
        SmartAccount smartAccount = new SmartAccount(config.entryPoint);
        smartAccount.transferOwnership(config.burner);
        vm.stopBroadcast();

        return (helperConfig, smartAccount);
    }
}