// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

import './MathUtils.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';

library LordLib {

    using SafeMath for uint256;
    using MathUtils for uint256;

    /// @notice The slope of the bonding curve.
    uint256 public constant DIVIDER = 1000000; // 1 / multiplier 0.000001 (so that we don't deal with decimals)

    /**
     * Supply (s), reserve (r) and token price (p) are in a relationship defined by the bonding curve:
     *      p = m * s
     * The reserve equals to the area below the bonding curve
     *      r = s^2 / 2
     * The formula for the supply becomes
     *      s = sqrt(2 * r / m)
     *
     * In solidity computations, we are using divider instead of multiplier (because its an integer).
     * All values are decimals with 18 decimals (represented as uints), which needs to be compensated for in
     * multiplications and divisions
     */

    /// @notice Computes the increased supply given an amount of reserve.
    /// @param _reserveDelta The amount of reserve in wei to be used in the calculation.
    /// @param _totalReserve The current reserve state to be used in the calculation.
    /// @param _supply The current supply state to be used in the calculation.
    /// @return token amount in wei.
    function calculateReserveToTokens(
        uint256 _reserveDelta,
        uint256 _totalReserve,
        uint256 _supply
    ) internal pure returns (uint256) {
        uint256 _reserve = _totalReserve;
        uint256 _newReserve = _reserve.add(_reserveDelta);
        // s = sqrt(2 * r / m)
        uint256 _newSupply = MathUtils.sqrt(
            _newReserve
            .mul(2)
            .mul(DIVIDER) // inverse the operation (Divider instead of multiplier)
            .mul(1e18) // compensation for the squared unit
        );

        uint256 _supplyDelta = _newSupply.sub(_supply);
        return _supplyDelta;
    }

    /// @notice Computes the decrease in reserve given an amount of tokens.
    /// @param _supplyDelta The amount of tokens in wei to be used in the calculation.
    /// @param _supply The current supply state to be used in the calculation.
    /// @param _totalReserve The current reserve state to be used in the calculation.
    /// @return Reserve amount in wei.
    function calculateTokensToReserve(
        uint256 _supplyDelta,
        uint256 _supply,
        uint256 _totalReserve
    ) internal pure returns (uint256) {
        require(_supplyDelta <= _supply, 'Token amount must be less than the supply');

        uint256 _newSupply = _supply.sub(_supplyDelta);

        uint256 _newReserve = calculateReserveFromSupply(_newSupply);

        uint256 _reserveDelta = _totalReserve.sub(_newReserve);

        return _reserveDelta;
    }

    /// @notice Calculates reserve given a specific supply.
    /// @param _supply The token supply in wei to be used in the calculation.
    /// @return Reserve amount in wei.
    function calculateReserveFromSupply(uint256 _supply) internal pure returns (uint256) {
        // r = s^2 * m / 2
        uint256 _reserve = _supply
        .mul(_supply)
        .div(DIVIDER) // inverse the operation (Divider instead of multiplier)
        .div(2);

        return _reserve.roundedDiv(1e18);
        // correction of the squared unit
    }
}