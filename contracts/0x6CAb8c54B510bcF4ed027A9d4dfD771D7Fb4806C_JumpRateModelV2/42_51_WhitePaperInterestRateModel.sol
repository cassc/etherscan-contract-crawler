// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "./InterestRateModel.sol";

/**
 * @title Compound's WhitePaperInterestRateModel Contract
 * @author Compound
 * @notice The parameterized model described in section 2.4 of the original Compound Protocol whitepaper
 */
contract WhitePaperInterestRateModel is InterestRateModel {
  event NewInterestParams(uint256 baseRatePerBlock, uint256 multiplierPerBlock);

  uint256 private constant BASE = 1e18;

  /**
   * @notice The approximate number of blocks per year that is assumed by the interest rate model
   */
  uint256 public constant blocksPerYear = 2629800;

  /**
   * @notice The multiplier of utilization rate that gives the slope of the interest rate
   */
  uint256 public multiplierPerBlock;

  /**
   * @notice The base interest rate which is the y-intercept when utilization rate is 0
   */
  uint256 public baseRatePerBlock;

  /**
   * @notice Construct an interest rate model
   * @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by BASE)
   * @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by BASE)
   */
  constructor(uint256 baseRatePerYear, uint256 multiplierPerYear) public {
    baseRatePerBlock = baseRatePerYear / blocksPerYear;
    multiplierPerBlock = multiplierPerYear / blocksPerYear;

    emit NewInterestParams(baseRatePerBlock, multiplierPerBlock);
  }

  /**
   * @notice Calculates the utilization rate of the market: `borrows / (cash + borrows - reserves)`
   * @param cash The amount of cash in the market
   * @param borrows The amount of borrows in the market
   * @param reserves The amount of reserves in the market (currently unused)
   * @return The utilization rate as a mantissa between [0, BASE]
   */
  function utilizationRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves
  ) public pure returns (uint256) {
    // Utilization rate is 0 when there are no borrows
    if (borrows == 0) {
      return 0;
    }

    return (borrows * BASE) / (cash + borrows - reserves);
  }

  /**
   * @notice Calculates the current borrow rate per block, with the error code expected by the market
   * @param cash The amount of cash in the market
   * @param borrows The amount of borrows in the market
   * @param reserves The amount of reserves in the market
   * @return The borrow rate percentage per block as a mantissa (scaled by BASE)
   */
  function getBorrowRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves
  ) public view override returns (uint256) {
    uint256 ur = utilizationRate(cash, borrows, reserves);
    return ((ur * multiplierPerBlock) / BASE) + baseRatePerBlock;
  }

  /**
   * @notice Calculates the current supply rate per block
   * @param cash The amount of cash in the market
   * @param borrows The amount of borrows in the market
   * @param reserves The amount of reserves in the market
   * @param reserveFactorMantissa The current reserve factor for the market
   * @return The supply rate percentage per block as a mantissa (scaled by BASE)
   */
  function getSupplyRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves,
    uint256 reserveFactorMantissa
  ) public view override returns (uint256) {
    uint256 oneMinusReserveFactor = BASE - reserveFactorMantissa;
    uint256 borrowRate = getBorrowRate(cash, borrows, reserves);
    uint256 rateToPool = (borrowRate * oneMinusReserveFactor) / BASE;
    return (utilizationRate(cash, borrows, reserves) * rateToPool) / BASE;
  }
}