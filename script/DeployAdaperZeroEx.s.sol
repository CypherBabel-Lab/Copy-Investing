// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";

address constant MUMBAI_INTEGRATION = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;
address constant MUMBAI_ZERO_EX_EXCHANGE = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;
address constant MUMBAI_ADDRESS_LIST_REGISTRY = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;

contract DeployAdapterZeroEx is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address adapterZeroEXAddress = deployCode("ZeroExV4Adapter.sol", abi.encode(MUMBAI_INTEGRATION, MUMBAI_ZERO_EX_EXCHANGE, MUMBAI_ADDRESS_LIST_REGISTRY,0));
        vm.stopBroadcast();
    }
}
 