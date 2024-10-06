// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {EntryPoint} from "lib/account-abstraction/contracts/core/EntryPoint.sol";

contract HelperConfig is Script {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        address entryPoint;
        address burner;
    }

    address constant BURNER_WALLET_ADDRESS = 0x11e9890626D6cC378d1c9B845B44e6AA77503e46; // op sepolia testnet address
    address constant FOUNDRY_DEFAULT_ACCOUNT = address(uint160(uint256(keccak256("foundry default caller"))));
    address constant ANVIL_DEFAULT_ACCOUNT = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    uint256 public constant OPTIMISM_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ANVIL_CHAIN_ID = 31337;
    
    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[OPTIMISM_SEPOLIA_CHAIN_ID] = getOpSepoliaConfig();
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if(chainId == ANVIL_CHAIN_ID) {
            return getOrCreateAnvilNetworkConfig();
        } else if(networkConfigs[chainId].burner == address(0)) {
            return getOpSepoliaConfig();
        }
        revert HelperConfig__InvalidChainId();

    }

    function getOpSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            entryPoint: 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789,
            burner: BURNER_WALLET_ADDRESS
        });
    }

    function getOrCreateAnvilNetworkConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.burner != address(0)) {
            return localNetworkConfig;
        }
        // deploy a mock entrypoint
        vm.startBroadcast(ANVIL_DEFAULT_ACCOUNT);
        EntryPoint entryPoint = new EntryPoint();
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            entryPoint: address(entryPoint),
            burner: ANVIL_DEFAULT_ACCOUNT
        });
        return localNetworkConfig;
    }
}