// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";

// address constant ARBITRUM_WETH = 0x1980A588fA420E874fC5fB1e0E68FBE39c34672f;
address constant MUMBAI_WMATIC = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;
// address constant ARBITRUM_ETH_USD_AGGREGATOR = 0x62CAe0FA2da220f43a51F86Db2EDb36DcA9A5A08;
address constant MUMBAI_ETH_USD_AGGREGATOR = 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada;
uint256 constant CHAINLINK_STALE_RATE_THRESHOLD = 10 minutes;

contract Deploy is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address vaultFactoryAddress = deployCode("VaultFactory.sol");
        address vauleEvaluatorAddress = deployCode("ValueEvaluator.sol", abi.encode(vaultFactoryAddress, MUMBAI_WMATIC, CHAINLINK_STALE_RATE_THRESHOLD));
        address integrationManagerAddress = deployCode("IntegrationManager.sol", abi.encode(vaultFactoryAddress, vauleEvaluatorAddress));
        address globalSharedAddress = deployCode("GlobalShared.sol", abi.encode(vaultFactoryAddress, integrationManagerAddress, vauleEvaluatorAddress, MUMBAI_WMATIC));
        vm.stopBroadcast();
    }
}
 