// SPDX-License-Identifier: MIT 
pragma solidity 0.8.19;
pragma experimental ABIEncoderV2;

import { UpgradeableBeacon } from "openzeppelin/proxy/beacon/UpgradeableBeacon.sol";
import  { IGuardianLogic } from "../guardian/IGuardianLogic.sol";
import  {GuardianLogic}  from "../guardian/GuardianLogic.sol";
import  { GuardianProxy } from "../guardian/GuardianProxy.sol";
import  { IVaultLogic } from "../vault/IVaultLogic.sol";
import  { VaultLogic } from "../vault/VaultLogic.sol";
import { IGlobalShared } from "../utils/IGlobalShared.sol";

/// @title A title that should describe the contract/interface
/// @author The name of the author
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
contract VaultFactory {
    event GuardianLibSet(address guardianLibSet);

    event GuardianProxyDeployed(
        address indexed creator,
        address guardianProxy,
        address indexed denominationAsset,
        uint256 sharesActionTimelock
    );

    event NewVaultCreated(address indexed creator, address vaultProxy, address guardianProxy);

    event Activated();

    event GlobalSharedSet(address globalShared);

    // Constants
    address private immutable _creator;
    
    // pseudoConstant(can only be set once)
    address private _globalShared;

    // Storage
    bool internal _activated;
    address private _beaconGuardianLogic;
    address private _beaconVaultLogic;

    modifier onlyCreator() {
        require(msg.sender == _creator, "Only Creator can call this function");
        _;
    }

    modifier onlyActivated() {
        require(isActivated(), "contract is not yet activate");
        _;
    }

    modifier pseudoConstant(address _storageValue) {
        require(_storageValue == address(0), "This value can only be set once");
        _;
    }

    constructor() {
        _creator = msg.sender;

        _beaconGuardianLogic = address(new UpgradeableBeacon(address(new GuardianLogic())));
        _beaconVaultLogic = address(new UpgradeableBeacon(address(new VaultLogic())));
    }

    /// PSEUDO-CONSTANTS (only set once)

    /// @notice Sets the GlobalShared contract address
    /// @param globalShared_ The address of the GlobalShared contract
    function setGlobalShared(address globalShared_) external onlyCreator pseudoConstant(getGlobalShared()) {
        _globalShared = globalShared_;
        emit GlobalSharedSet(globalShared_);
    }

    /// PUBLIC FUNCTIONS

    /// @notice Gets the current owner of the contract
    /// @return owner_ The contract owner address
    function getOwner() public view override returns (address owner_) {
        return getCreator();
    }

    /// @notice Set vaultFactory activated
    function activate() external onlyCreator {
        require(!isActivated(), "activate: Already Activated");

        // All pseudo-constants should be set
        require(getGlobalShared() != address(0), "activate: globalShared is not set");

        _activated = true;

        emit Activated();
    }

    /// CREATE VAULT FUNCTIONS

    /// @notice Creates a new vault
    /// @param _vaultName The name of the vault
    /// @param _vaultSymbol The symbol of the vault
    /// @param _denominationAsset The address of the denomination asset
    /// @param _sharesActionTimelock The timelock for shares actions
    /// @param _feeManagerConfigData The encoded config data for the FeeManager
    /// @param _policyManagerConfigData The encoded config data for the PolicyManager
    /// @return guardianProxy_ The address of the GuardianProxy contract
    /// @return vaultProxy_ The address of the VaultProxy contract
    function createNewVault(
        string calldata _vaultName,
        string calldata _vaultSymbol,
        address _denominationAsset,
        uint256 _sharesActionTimelock,
        bytes calldata _feeManagerConfigData,
        bytes calldata _policyManagerConfigData
    ) external onlyActivated returns (address guardianProxy_, address vaultProxy_) {

        address canonicalSender = msg.sender;

        guardianProxy_ = __deployGuardianProxy(canonicalSender, _denominationAsset, _sharesActionTimelock);

        vaultProxy_ = __deployVaultProxy(canonicalSender, guardianProxy_, _vaultName, _vaultSymbol);

        IGuardianLogic guardianProxyContract = IGuardianLogic(guardianProxy_);
        guardianProxyContract.setVaultProxy(vaultProxy_);

        __configureExtensions(guardianProxy_, vaultProxy_, _feeManagerConfigData, _policyManagerConfigData);

        guardianProxyContract.activate();

        emit NewVaultCreated(canonicalSender, vaultProxy_, guardianProxy_);

        return (guardianProxy_, vaultProxy_);
    }

    /// @dev Helper function to deploy a configured GuardianProxy
    function __deployGuardianProxy(
        address _canonicalSender,
        address _denominationAsset,
        uint256 _sharesActionTimelock
    ) private returns (address guardianProxy_) {
        bytes memory constructData =
            abi.encodeWithSelector(IGuardianLogic.initialize.selector, getGlobalShared(), _denominationAsset, _sharesActionTimelock);
        guardianProxy_ = address(new GuardianProxy(getGuardianLib(), constructData));

        emit GuardianProxyDeployed(_canonicalSender, guardianProxy_, _denominationAsset, _sharesActionTimelock);

        return guardianProxy_;
    }

    /// @dev Helper to deploy a new VaultProxy instance during vault creation.
    /// Avoids stack-too-deep error.
    function __deployVaultProxy(
        address _vaultOwner,
        address _guardianProxy,
        string calldata _vaultName,
        string calldata _vaultSymbol
    ) private returns (address vaultProxy_) {
        vaultProxy_ =
            IDispatcher(IGlobalShared(getGlobalShared()).getDispatcher()).deployVaultProxy(getVaultLib(), _vaultOwner, _guardianProxy, _vaultName);
        if (bytes(_vaultSymbol).length != 0) {
            IVaultLogic(vaultProxy_).setSymbol(_vaultSymbol);
        }

        return vaultProxy_;
    }

    /// @dev Helper function to configure the Extensions for a given GuardianProxy
    function __configureExtensions(
        address _guardianProxy,
        address _vaultProxy,
        bytes memory _feeManagerConfigData,
        bytes memory _policyManagerConfigData
    ) private {
        // Since fees can only be set in this step, if there are no fees, there is no need to set the validated VaultProxy
        if (_feeManagerConfigData.length > 0) {
            IExtension(IGlobalShared(getGlobalShared()).getFeeManager()).setConfigForVault(
                _guardianProxy, _vaultProxy, _feeManagerConfigData
            );
        }

        // For all other extensions, we call to cache the validated VaultProxy, for simplicity.
        // In the future, we can consider caching conditionally.
        IExtension(IGlobalShared(getGlobalShared()).getExternalPositionManager()).setConfigForVault(
            _guardianProxy, _vaultProxy, ""
        );
        IExtension(IGlobalShared(getGlobalShared()).getIntegrationManager()).setConfigForVault(
            _guardianProxy, _vaultProxy, ""
        );
        IExtension(IGlobalShared(getGlobalShared()).getPolicyManager()).setConfigForVault(
            _guardianProxy, _vaultProxy, _policyManagerConfigData
        );
    }

    // VAULT CALLS

    /// @notice De-registers allowed arbitrary contract calls that can be sent from the VaultProxy
    /// @param _contracts The contracts of the calls to de-register
    /// @param _selectors The selectors of the calls to de-register
    /// @param _dataHashes The keccak call data hashes of the calls to de-register
    /// @dev ANY_VAULT_CALL is a wildcard that allows any payload
    function deregisterVaultCalls(
        address[] calldata _contracts,
        bytes4[] calldata _selectors,
        bytes32[] memory _dataHashes
    ) external onlyCreator {
        require(_contracts.length > 0, "deregisterVaultCalls: Empty _contracts");
        require(
            _contracts.length == _selectors.length && _contracts.length == _dataHashes.length,
            "deregisterVaultCalls: Uneven input arrays"
        );

        for (uint256 i; i < _contracts.length; i++) {
            require(
                isRegisteredVaultCall(_contracts[i], _selectors[i], _dataHashes[i]),
                "deregisterVaultCalls: Call not registered"
            );

            _vaultCallToPayloadToIsAllowed[keccak256(abi.encodePacked(_contracts[i], _selectors[i]))][_dataHashes[i]] =
                false;

            emit VaultCallDeregistered(_contracts[i], _selectors[i], _dataHashes[i]);
        }
    }

    /// @notice Registers allowed arbitrary contract calls that can be sent from the VaultProxy
    /// @param _contracts The contracts of the calls to register
    /// @param _selectors The selectors of the calls to register
    /// @param _dataHashes The keccak call data hashes of the calls to register
    /// @dev ANY_VAULT_CALL is a wildcard that allows any payload
    function registerVaultCalls(
        address[] calldata _contracts,
        bytes4[] calldata _selectors,
        bytes32[] memory _dataHashes
    ) external onlyCreator {
        require(_contracts.length > 0, "registerVaultCalls: Empty _contracts");
        require(
            _contracts.length == _selectors.length && _contracts.length == _dataHashes.length,
            "registerVaultCalls: Uneven input arrays"
        );

        for (uint256 i; i < _contracts.length; i++) {
            require(
                !isRegisteredVaultCall(_contracts[i], _selectors[i], _dataHashes[i]),
                "registerVaultCalls: Call already registered"
            );

            _vaultCallToPayloadToIsAllowed[keccak256(abi.encodePacked(_contracts[i], _selectors[i]))][_dataHashes[i]] =
                true;

            emit VaultCallRegistered(_contracts[i], _selectors[i], _dataHashes[i]);
        }
    }

    /// public getters

    /// @notice Gets the address of the contract creator
    /// @return creator_ The address of the contract creator
    function getCreator() public view returns (address creator_) {
        return _creator;
    }

    /// @notice Gets the address of the GlobalShared contract
    /// @return globalShared_ The address of the GlobalShared contract
    function getGlobalShared() public view returns (address globalShared_) {
        return _globalShared;
    }

    /// @notice Checks if factory is activated
    /// @return activated_ True if factory is activated
    function isActivated() public view returns (bool activated_) {
        return _activated;
    }

    /// @notice Gets the address of the VaultLogic contract
    /// @return vaultLib_ The address of the VaultLogic contract
    function getVaultLib() public view returns (address vaultLib_) {
        return _beaconVaultLogic;
    }

    /// @notice Gets the address of the GuardianLogic contract
    /// @return guardianLib_ The address of the GuardianLogic contract
    function getGuardianLib() public view returns (address guardianLib_) {
        return _beaconGuardianLogic;
    }
}

