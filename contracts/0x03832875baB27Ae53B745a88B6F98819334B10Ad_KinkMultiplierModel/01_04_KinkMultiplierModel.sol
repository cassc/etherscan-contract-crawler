// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "./interfaces/IKinkMultiplierModel.sol";
import "./interfaces/IInterestRateModel.sol";

contract KinkMultiplierModel is IKinkMultiplierModel, IInterestRateModel {
    uint256 public constant blocksPerYear = 2628000; // 12 second block interval

    uint256 public immutable interestRateMultiplierPerBlock;
    uint256 public immutable initialRatePerBlock;
    uint256 public immutable kinkCurveMultiplierPerBlock;
    uint256 public immutable kinkPoint;

    /// @param initialRatePerYear The approximate target initial APR, as a mantissa (scaled by 1e18)
    /// @param interestRateMultiplierPerYear Interest rate to utilisation rate increase ratio (scaled by 1e18)
    /// @param kinkCurveMultiplierPerYear The multiplier per year after hitting a kink point
    /// @param kinkPoint_ The utilisation point at which the kink curve multiplier is applied
    constructor(
        uint256 initialRatePerYear,
        uint256 interestRateMultiplierPerYear,
        uint256 kinkCurveMultiplierPerYear,
        uint256 kinkPoint_
    ) {
        require(kinkPoint_ > 0);
        initialRatePerBlock = initialRatePerYear / blocksPerYear;
        interestRateMultiplierPerBlock = interestRateMultiplierPerYear / blocksPerYear;
        kinkCurveMultiplierPerBlock = kinkCurveMultiplierPerYear / blocksPerYear;
        kinkPoint = kinkPoint_;
    }

    /// @inheritdoc IInterestRateModel
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 protocolInterest
    ) public view returns (uint256) {
        uint256 util = utilisationRate(cash, borrows, protocolInterest);
        if (util <= kinkPoint) {
            return (util * interestRateMultiplierPerBlock) / 1e18 + initialRatePerBlock;
        } else {
            uint256 normalRate = (kinkPoint * interestRateMultiplierPerBlock) / 1e18 + initialRatePerBlock;
            uint256 excessUtil = util - kinkPoint;
            return (excessUtil * kinkCurveMultiplierPerBlock) / 1e18 + normalRate;
        }
    }

    /// @inheritdoc IInterestRateModel
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 protocolInterest,
        uint256 protocolInterestFactorMantissa
    ) external view returns (uint256) {
        uint256 oneMinusProtocolInterestFactor = 1e18 - protocolInterestFactorMantissa;
        uint256 borrowRate = getBorrowRate(cash, borrows, protocolInterest);
        uint256 rateToPool = (borrowRate * oneMinusProtocolInterestFactor) / 1e18;
        return (utilisationRate(cash, borrows, protocolInterest) * rateToPool) / 1e18;
    }

    /// @inheritdoc IKinkMultiplierModel
    function utilisationRate(
        uint256 cash,
        uint256 borrows,
        uint256 protocolInterest
    ) public pure returns (uint256) {
        // Utilisation rate is 0 when there are no borrows
        if (borrows == 0) return 0;
        return (borrows * 1e18) / (cash + borrows - protocolInterest);
    }
}