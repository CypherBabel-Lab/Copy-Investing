// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { IVaultFactory } from "../src/vault-factory/IVaultFactory.sol";
import { IValueEvaluator } from "./interfaces/IValueEvaluator.sol";
import { ChainlinkPriceFeedMixin } from "../src/price-feeds/primitives/ChainlinkPriceFeedMixin.sol";

// address constant ARBITRUM_WETH = 0x1980A588fA420E874fC5fB1e0E68FBE39c34672f;
address constant MUMBAI_WMATIC = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;
uint256 constant CHAINLINK_STALE_RATE_THRESHOLD = 300 minutes;
// address constant ARBITRUM_ETH_USD_AGGREGATOR = 0x62CAe0FA2da220f43a51F86Db2EDb36DcA9A5A08;
address constant MUMBAI_ETH_USD_AGGREGATOR = 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada;

// address primitive asset
address constant MUMBAI_USDC_USD_AGGREGATOR = 0x572dDec9087154dC5dfBB1546Bb62713147e0Ab0;
address constant MUMBAI_SAND_USD_AGGREGATOR = 0x9dd18534b8f456557d11B9DDB14dA89b2e52e308;
address constant MUMBAI_DAI_USD_AGGREGATOR = 0x0FCAa9c899EC5A91eBc3D5Dd869De833b06fB046;
address constant MUMBAI_LINK_ETH_AGGREGATOR = 0x12162c3E810393dEC01362aBf156D7ecf6159528;

//ox v4 exchange proxy
address constant MUMBAI_ZERO_EX_EXCHANGE = 0xF471D32cb40837bf24529FCF17418fC1a4807626;

enum ChainlinkRateAsset {
    ETH,
    USD
}
contract Deploy is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address vaultFactoryAddress = deployCode("VaultFactory.sol");
        address vauleEvaluatorAddress = deployCode("ValueEvaluator.sol", abi.encode(vaultFactoryAddress, MUMBAI_WMATIC, CHAINLINK_STALE_RATE_THRESHOLD));
        address integrationManagerAddress = deployCode("IntegrationManager.sol", abi.encode(vaultFactoryAddress, vauleEvaluatorAddress));
        address globalSharedAddress = deployCode("GlobalShared.sol", abi.encode(vaultFactoryAddress, integrationManagerAddress, vauleEvaluatorAddress, MUMBAI_WMATIC));
        // set vault factory global shared
        IVaultFactory(vaultFactoryAddress).setGlobalShared(globalSharedAddress);
        // active vault factory
        IVaultFactory(vaultFactoryAddress).activate();
        // set value evaluator eth usd aggregator
        IValueEvaluator(vauleEvaluatorAddress).setEthUsdAggregator(MUMBAI_ETH_USD_AGGREGATOR);
        // set value evaluator primitives aggregator
        address[] memory erc20AddressList = new address[](4);
        erc20AddressList[0] = 0xE03489D4E90b22c59c5e23d45DFd59Fc0dB8a025;
        erc20AddressList[1] = 0xd393b1E02dA9831Ff419e22eA105aAe4c47E1253;
        erc20AddressList[2] = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
        erc20AddressList[3] = 0xe6b8a5CF854791412c1f6EFC7CAf629f5Df1c747;
        // address[] memory chainlinkAggregatorAddressList = [MUMBAI_USDC_USD_AGGREGATOR,MUMBAI_SAND_USD_AGGREGATOR,MUMBAI_DAI_USD_AGGREGATOR,MUMBAI_LINK_ETH_AGGREGATOR];
        address[] memory chainlinkAggregatorAddressList = new address[](4);
        chainlinkAggregatorAddressList[0] = MUMBAI_SAND_USD_AGGREGATOR;
        chainlinkAggregatorAddressList[1] = MUMBAI_DAI_USD_AGGREGATOR;
        chainlinkAggregatorAddressList[2] = MUMBAI_LINK_ETH_AGGREGATOR;
        chainlinkAggregatorAddressList[3] = MUMBAI_USDC_USD_AGGREGATOR;
        // ChainlinkPriceFeedMixin.RateAsset[]  memory rateAssetList = [ChainlinkPriceFeedMixin.RateAsset.USD,ChainlinkPriceFeedMixin.RateAsset.USD,ChainlinkPriceFeedMixin.RateAsset.USD,ChainlinkPriceFeedMixin.RateAsset.ETH];
        uint8[] memory rateAssetList = new uint8[](4);
        rateAssetList[0] = uint8(ChainlinkRateAsset.USD);
        rateAssetList[1] = uint8(ChainlinkRateAsset.USD);
        rateAssetList[2] = uint8(ChainlinkRateAsset.ETH);
        rateAssetList[3] = uint8(ChainlinkRateAsset.USD);
        IValueEvaluator(vauleEvaluatorAddress).addPrimitives(erc20AddressList,chainlinkAggregatorAddressList,rateAssetList);
        // deploy ox adapter
        address addressListRegistry = deployCode("AddressListRegistry.sol");
        address adapterZeroEXAddress = deployCode("ZeroExV4Adapter.sol", abi.encode(integrationManagerAddress, MUMBAI_ZERO_EX_EXCHANGE, addressListRegistry,0));
        vm.stopBroadcast();
    }
}
 