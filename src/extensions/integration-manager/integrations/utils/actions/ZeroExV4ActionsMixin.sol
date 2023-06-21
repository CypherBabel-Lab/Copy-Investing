// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.19;
pragma experimental ABIEncoderV2;

import "../../../../../external-interfaces/IZeroExV4.sol";
import "../../../../../utils/AssetHelpers.sol";

/// @title ZeroExV4ActionsMixin Contract
/// @notice Mixin contract for interacting with the ZeroExV4 exchange functions
abstract contract ZeroExV4ActionsMixin is AssetHelpers {
    using SafeMath for uint256;
    address internal immutable ZERO_EX_V4_EXCHANGE;

    constructor(address _exchange) {
        ZERO_EX_V4_EXCHANGE = _exchange;
    }

    /// @dev Helper to execute fillLimitOrder
    function __zeroExV4TakeLimitOrder(
        IZeroExV4.LimitOrder memory _order,
        IZeroExV4.Signature memory _signature,
        uint128 _takerAssetFillAmount
    ) internal {
        // Approve spend assets as needed
        __approveAssetMaxAsNeeded({
            _asset: _order.takerToken,
            _target: ZERO_EX_V4_EXCHANGE,
            _neededAmount: uint256(_takerAssetFillAmount).add(_order.takerTokenFeeAmount)
        });

        // Execute order
        IZeroExV4(ZERO_EX_V4_EXCHANGE).fillOrKillLimitOrder({
            _order: _order,
            _signature: _signature,
            _takerTokenFillAmount: _takerAssetFillAmount
        });
    }

    /// @dev Helper to execute fillRfqOrder
    function __zeroExV4TakeRfqOrder(
        IZeroExV4.RfqOrder memory _order,
        IZeroExV4.Signature memory _signature,
        uint128 _takerAssetFillAmount
    ) internal {
        // Approve spend assets as needed
        __approveAssetMaxAsNeeded({
            _asset: _order.takerToken,
            _target: ZERO_EX_V4_EXCHANGE,
            _neededAmount: _takerAssetFillAmount
        });

        // Execute order
        IZeroExV4(ZERO_EX_V4_EXCHANGE).fillOrKillRfqOrder({
            _order: _order,
            _signature: _signature,
            _takerTokenFillAmount: _takerAssetFillAmount
        });
    }
}
