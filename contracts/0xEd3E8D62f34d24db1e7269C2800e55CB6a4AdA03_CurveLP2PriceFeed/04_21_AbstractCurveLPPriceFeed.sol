// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import { LPPriceFeed } from "@gearbox-protocol/core-v2/contracts/oracles/LPPriceFeed.sol";
import { ICurvePool } from "../../integrations/curve/ICurvePool.sol";

// EXCEPTIONS
import { ZeroAddressException, NotImplementedException } from "@gearbox-protocol/core-v2/contracts/interfaces/IErrors.sol";

uint256 constant RANGE_WIDTH = 200; // 2%

/// @title Abstract CurveLP pricefeed
abstract contract AbstractCurveLPPriceFeed is LPPriceFeed {
    /// @dev The Curve pool associated with the evaluated LP token
    ICurvePool public immutable curvePool;

    /// @dev Format of pool's virtual_price
    int256 public immutable decimalsDivider;

    /// @dev Contract version
    uint256 public constant override version = 1;

    /// @dev Whether to skip price sanity checks.
    /// @notice Always set to true for LP price feeds,
    ///         since they perform their own sanity checks
    bool public constant override skipPriceCheck = true;

    constructor(
        address addressProvider,
        address _curvePool,
        string memory _description
    ) LPPriceFeed(addressProvider, RANGE_WIDTH, _description) {
        if (_curvePool == address(0)) revert ZeroAddressException();

        curvePool = ICurvePool(_curvePool); // F:[OCLP-1]
        decimalsDivider = 10**18;

        uint256 virtualPrice = ICurvePool(_curvePool).get_virtual_price();
        _setLimiter(virtualPrice);
    }

    function _checkCurrentValueInBounds(
        uint256 _lowerBound,
        uint256 _upperBound
    ) internal view override returns (bool) {
        uint256 virtualPrice = curvePool.get_virtual_price();
        if (virtualPrice < _lowerBound || virtualPrice > _upperBound) {
            return false;
        }
        return true;
    }
}