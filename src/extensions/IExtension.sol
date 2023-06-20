// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.19;

/// @title IExtension Interface
/// @notice Interface for all extensions
interface IExtension {

    function receiveCallFromGuardian(address _caller, uint256 _actionId, bytes calldata _callArgs) external;

}
