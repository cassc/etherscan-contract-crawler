// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/access/Ownable.sol';
import './interfaces/IOpenSkyInterestRateStrategy.sol';
import './libraries/math/WadRayMath.sol';
import './libraries/math/PercentageMath.sol';

/**
 * @title OpenSkyInterestRateStrategy contract
 * @author OpenSky Labs
 * @notice Implements the calculation of the interest rates depending on the reserve state
 * @dev The model of interest rate is based on 2 slopes, one before the `OPTIMAL_UTILIZATION_RATE`
 * point of usage and another from that one to 100%.
 **/
contract OpenSkyInterestRateStrategy is IOpenSkyInterestRateStrategy, Ownable {
    using WadRayMath for uint256;
    using PercentageMath for uint256;

    uint256 public immutable OPTIMAL_UTILIZATION_RATE; 
    uint256 public immutable EXCESS_UTILIZATION_RATE; 

    // Slope of the stable interest curve when utilization rate > 0 and <= OPTIMAL_UTILIZATION_RATE. Expressed in ray
    uint256 internal immutable _rateSlope1;

    // Slope of the stable interest curve when utilization rate > OPTIMAL_UTILIZATION_RATE. Expressed in ray
    uint256 internal immutable _rateSlope2;

    uint256 internal immutable _baseBorrowRate;

    mapping(uint256 => uint256) internal _baseBorrowRates;
    
    constructor(
        uint256 optimalUtilizationRate,
        uint256 rateSlope1_,
        uint256 rateSlope2_,
        uint256 baseBorrowRate
    ) Ownable() {
        OPTIMAL_UTILIZATION_RATE = optimalUtilizationRate;
        EXCESS_UTILIZATION_RATE = WadRayMath.ray() - optimalUtilizationRate;
        _rateSlope1 = rateSlope1_;
        _rateSlope2 = rateSlope2_;
        _baseBorrowRate = baseBorrowRate;
    }

    function rateSlope1() external view returns (uint256) {
        return _rateSlope1;
    }

    function rateSlope2() external view returns (uint256) {
        return _rateSlope2;
    }

    /**
     * @notice Sets the base borrow rate of a reserve
     * @param reserveId The id of the reserve
     * @param rate The rate to be set
     **/
    function setBaseBorrowRate(uint256 reserveId, uint256 rate) external onlyOwner {
        _baseBorrowRates[reserveId] = rate;
        emit SetBaseBorrowRate(reserveId, rate);
    }

    /**
     * @notice Returns the base borrow rate of a reserve
     * @param reserveId The id of the reserve
     * @return The borrow rate, expressed in ray
     **/
    function getBaseBorrowRate(uint256 reserveId) public view returns (uint256) {
        return _baseBorrowRates[reserveId] > 0 ? _baseBorrowRates[reserveId] : _baseBorrowRate;
    }

    /// @inheritdoc IOpenSkyInterestRateStrategy
    function getBorrowRate(uint256 reserveId, uint256 totalDeposits, uint256 totalBorrows) external override view returns (uint256) {
        uint256 utilizationRate = totalBorrows == 0 ? 0 : totalBorrows.rayDiv(totalDeposits);
        uint256 currentBorrowRate = 0;
        uint256 baseBorrowRate = getBaseBorrowRate(reserveId);
        if (utilizationRate > OPTIMAL_UTILIZATION_RATE) {
            uint256 excessUtilizationRateRatio = (utilizationRate - OPTIMAL_UTILIZATION_RATE).rayDiv(EXCESS_UTILIZATION_RATE);
            currentBorrowRate = baseBorrowRate + _rateSlope1 + _rateSlope2.rayMul(excessUtilizationRateRatio);
        } else {
            currentBorrowRate = baseBorrowRate + _rateSlope1.rayMul(utilizationRate).rayDiv(OPTIMAL_UTILIZATION_RATE);
        }
        return currentBorrowRate;
    }
}