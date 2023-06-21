// SPDX-License-Identifier: MIT 
pragma solidity 0.8.19;

contract GlobalShared {
    address private immutable _vaultFactory;
    address private immutable _integrationManager;
    address private immutable _valueInterpreter;
    address private immutable _wethToken;

    constructor(
        address vaultFactory_,
        address integrationManager_,
        address valueInterpreter_,
        address wethToken_
    ) {
        _vaultFactory = vaultFactory_;
        _integrationManager = integrationManager_;
        _valueInterpreter = valueInterpreter_;
        _wethToken = wethToken_;
    }
    
    /// @notice returns the address of the vaultFactory contract
    /// @return vaultFactory_ The address of the vaultFactory contract
    function getvaultFactory() external view returns (address vaultFactory_) {
        return _vaultFactory;
    }

    /// @notice Returns the address of the IntegrationManager contract
    /// @return integrationManager_ The address of the IntegrationManager contract
    function getIntegrationManager() external view returns (address integrationManager_) {
        return _integrationManager;
    }

    /// @notice Returns the address of the ValueInterpreter contract
    /// @return valueInterpreter_ The address of the ValueInterpreter contract
    function getValueInterpreter() external view returns (address valueInterpreter_) {
        return _valueInterpreter;
    }

    /// @notice Returns the address of the WETH token
    /// @return wethToken_ The address of the WETH token
    function getWethToken() external view returns (address wethToken_) {
        return _wethToken;
    }

}