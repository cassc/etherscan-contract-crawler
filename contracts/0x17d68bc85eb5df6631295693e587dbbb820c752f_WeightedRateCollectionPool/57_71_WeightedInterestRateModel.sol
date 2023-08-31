// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "../InterestRateModel.sol";
import "../Tick.sol";

/**
 * @title Weighted Interest Rate Model
 * @author MetaStreet Labs
 */
contract WeightedInterestRateModel is InterestRateModel {
    using SafeCast for uint256;

    /**************************************************************************/
    /* Constants */
    /**************************************************************************/

    /**
     * @notice Fixed point scale
     */
    uint256 internal constant FIXED_POINT_SCALE = 1e18;

    /**
     * @notice Maximum tick threshold (0.5)
     */
    uint256 internal constant MAX_TICK_THRESHOLD = 0.5 * 1e18;

    /**
     * @notice Minimum tick exponential (0.25)
     */
    uint256 internal constant MIN_TICK_EXPONENTIAL = 0.25 * 1e18;

    /**
     * @notice Maximum tick exponential (4.0)
     */
    uint256 internal constant MAX_TICK_EXPONENTIAL = 4.0 * 1e18;

    /**************************************************************************/
    /* Structures */
    /**************************************************************************/

    /**
     * @notice Parameters
     * @param tickThreshold Tick interest threshold
     * @param tickExponential Tick exponential base
     */
    struct Parameters {
        uint64 tickThreshold;
        uint64 tickExponential;
    }

    /**************************************************************************/
    /* Errors */
    /**************************************************************************/

    /**
     * @notice Invalid Tick Parameter
     */
    error InvalidParameters();

    /**
     * @notice Insufficient utilization
     */
    error InsufficientUtilization();

    /**************************************************************************/
    /* Immutable State */
    /**************************************************************************/

    /**
     * @notice Tick interest threshold
     */
    uint64 internal immutable _tickThreshold;

    /**
     * @notice Tick exponential base
     */
    uint64 internal immutable _tickExponential;

    /**************************************************************************/
    /* Constructor */
    /**************************************************************************/

    /**
     * @notice WeightedInterestRateModel constructor
     */
    constructor(Parameters memory parameters) {
        if (parameters.tickThreshold > MAX_TICK_THRESHOLD) revert InvalidParameters();
        if (parameters.tickExponential < MIN_TICK_EXPONENTIAL || parameters.tickExponential > MAX_TICK_EXPONENTIAL)
            revert InvalidParameters();

        _tickThreshold = parameters.tickThreshold;
        _tickExponential = parameters.tickExponential;
    }

    /**************************************************************************/
    /* Implementation */
    /**************************************************************************/

    /**
     * @inheritdoc InterestRateModel
     */
    function INTEREST_RATE_MODEL_NAME() external pure override returns (string memory) {
        return "WeightedInterestRateModel";
    }

    /**
     * @inheritdoc InterestRateModel
     */
    function INTEREST_RATE_MODEL_VERSION() external pure override returns (string memory) {
        return "1.0";
    }

    /**
     * @inheritdoc InterestRateModel
     */
    function _rate(
        uint256 amount,
        uint64[] memory rates,
        ILiquidity.NodeSource[] memory nodes,
        uint16 count
    ) internal pure override returns (uint256) {
        uint256 weightedRate;

        /* Accumulate weighted rate */
        for (uint256 i; i < count; i++) {
            (, , uint256 rateIndex, ) = Tick.decode(nodes[i].tick);
            weightedRate += (uint256(nodes[i].used) * rates[rateIndex]) / FIXED_POINT_SCALE;
        }

        /* Return normalized weighted rate */
        return Math.mulDiv(weightedRate, FIXED_POINT_SCALE, amount);
    }

    /**
     * @inheritdoc InterestRateModel
     */
    function _distribute(
        uint256 amount,
        uint256 interest,
        ILiquidity.NodeSource[] memory nodes,
        uint16 count
    ) internal view override returns (uint128[] memory) {
        /* Interest threshold for tick to receive interest */
        uint256 threshold = Math.mulDiv(_tickThreshold, amount, FIXED_POINT_SCALE);

        /* Interest weight starting at final tick */
        uint256 base = _tickExponential;
        uint256 weight = (FIXED_POINT_SCALE * FIXED_POINT_SCALE) / base;

        /* Assign weighted interest to ticks backwards */
        uint128[] memory pending = new uint128[](count);
        uint256 normalization;
        uint256 index = count;
        for (uint256 i; i < count; i++) {
            /* Skip tick if it's below threshold */
            if (nodes[--index].used <= threshold) continue;

            /* Compute scaled weight */
            uint256 scaledWeight = Math.mulDiv(weight, nodes[index].used, amount);

            /* Assign weighted interest */
            pending[index] = Math.mulDiv(scaledWeight, interest, FIXED_POINT_SCALE).toUint128();

            /* Accumulate scaled weight for later normalization */
            normalization += scaledWeight;

            /* Adjust interest weight for next tick */
            weight = Math.mulDiv(weight, FIXED_POINT_SCALE, base);
        }

        /* Validate normalization is non-zero */
        if (normalization == 0) revert InsufficientUtilization();

        /* Normalize weighted interest */
        for (uint256 i; i < count; i++) {
            /* Calculate normalized interest to tick */
            pending[i] = ((pending[i] * FIXED_POINT_SCALE) / normalization).toUint128();

            /* Track remaining interest */
            interest -= pending[i];
        }

        /* Drop off remaining dust at lowest tick */
        pending[0] += interest.toUint128();

        return pending;
    }
}