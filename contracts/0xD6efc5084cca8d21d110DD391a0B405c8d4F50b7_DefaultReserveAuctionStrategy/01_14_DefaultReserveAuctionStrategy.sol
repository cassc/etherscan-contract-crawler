// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IERC20} from "../../dependencies/openzeppelin/contracts/IERC20.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {PercentageMath} from "../libraries/math/PercentageMath.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {IReserveAuctionStrategy} from "../../interfaces/IReserveAuctionStrategy.sol";
import {IPoolAddressesProvider} from "../../interfaces/IPoolAddressesProvider.sol";
import {IToken} from "../../interfaces/IToken.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {PRBMathUD60x18} from "../../dependencies/math/PRBMathUD60x18.sol";
import {PRBMath} from "../../dependencies/math/PRBMath.sol";

/**
 * @title DefaultReserveAuctionStrategy contract
 *
 * @notice Implements the calculation of the current dutch auction price
 **/
contract DefaultReserveAuctionStrategy is IReserveAuctionStrategy {
    using PRBMathUD60x18 for uint256;

    /**
     * Expressed in PRBMath.SCALE
     **/
    uint256 internal immutable _maxPriceMultiplier;

    /**
     * Expressed in PRBMath.SCALE
     **/
    uint256 internal immutable _minExpPriceMultiplier;

    /**
     * Expressed in PRBMath.SCALE
     **/
    uint256 internal immutable _minPriceMultiplier;

    /**
     * Expressed in PRBMath.SCALE
     **/
    uint256 internal immutable _stepLinear;

    /**
     * Expressed in PRBMath.SCALE
     **/
    uint256 internal immutable _stepExp;

    uint256 internal immutable _tickLength;

    constructor(
        uint256 maxPriceMultiplier,
        uint256 minExpPriceMultiplier,
        uint256 minPriceMultiplier,
        uint256 stepLinear,
        uint256 stepExp,
        uint256 tickLength
    ) {
        _maxPriceMultiplier = maxPriceMultiplier;
        _minExpPriceMultiplier = minExpPriceMultiplier;
        _minPriceMultiplier = minPriceMultiplier;
        _stepLinear = stepLinear;
        _stepExp = stepExp;
        _tickLength = tickLength;
    }

    function getMaxPriceMultiplier() external view returns (uint256) {
        return _maxPriceMultiplier;
    }

    function getMinExpPriceMultiplier() external view returns (uint256) {
        return _minExpPriceMultiplier;
    }

    function getMinPriceMultiplier() external view returns (uint256) {
        return _minPriceMultiplier;
    }

    function getStepLinear() external view returns (uint256) {
        return _stepLinear;
    }

    function getStepExp() external view returns (uint256) {
        return _stepExp;
    }

    function getTickLength() external view returns (uint256) {
        return _tickLength;
    }

    function calculateAuctionPriceMultiplier(
        uint256 auctionStartTimestamp,
        uint256 currentTimestamp
    ) external view override returns (uint256) {
        uint256 ticks = PRBMathUD60x18.div(
            currentTimestamp - auctionStartTimestamp,
            _tickLength
        );
        return _calculateAuctionPriceMultiplierByTicks(ticks);
    }

    function _calculateAuctionPriceMultiplierByTicks(uint256 ticks)
        internal
        view
        returns (uint256)
    {
        if (ticks < PRBMath.SCALE) {
            return _maxPriceMultiplier;
        }

        uint256 ticksMinExp = (_maxPriceMultiplier.ln() -
            _minExpPriceMultiplier.ln()).div(_stepExp);
        if (ticks <= ticksMinExp) {
            return _maxPriceMultiplier.div(_stepExp.mul(ticks).exp());
        }

        uint256 priceMinExpEffective = _maxPriceMultiplier.div(
            _stepExp.mul(ticksMinExp).exp()
        );
        uint256 ticksMin = ticksMinExp +
            (priceMinExpEffective - _minPriceMultiplier).div(_stepLinear);

        if (ticks <= ticksMin) {
            return priceMinExpEffective - _stepLinear.mul(ticks - ticksMinExp);
        }

        return _minPriceMultiplier;
    }
}