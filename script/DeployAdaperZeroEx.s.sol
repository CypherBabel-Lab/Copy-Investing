// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";

address constant MUMBAI_INTEGRATION = 0xEfe7e3aa4ea617f7553b1D17B2112984A576602b;
address constant MUMBAI_ZERO_EX_EXCHANGE = 0xF471D32cb40837bf24529FCF17418fC1a4807626;

contract DeployAdapterZeroEx is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address addressListRegistry = deployCode("AddressListRegistry.sol");
        address adapterZeroEXAddress = deployCode("ZeroExV4Adapter.sol", abi.encode(MUMBAI_INTEGRATION, MUMBAI_ZERO_EX_EXCHANGE, addressListRegistry,0));
        vm.stopBroadcast();
    }
}
 