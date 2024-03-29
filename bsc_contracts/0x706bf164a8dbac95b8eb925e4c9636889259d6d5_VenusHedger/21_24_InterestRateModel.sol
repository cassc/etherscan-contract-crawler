pragma solidity >=0.8.10;

/**
 * @title Venus's InterestRateModel Interface
 * @author Venus
 */
interface InterestRateModel {
  /// @notice Indicator that this is an InterestRateModel contract (for inspection)
  function isInterestRateModel() external returns (bool);

  /**
   * @notice Calculates the current borrow interest rate per block
   * @param cash The total amount of cash the market has
   * @param borrows The total amount of borrows the market has outstanding
   * @param reserves The total amnount of reserves the market has
   * @return The borrow rate per block (as a percentage, and scaled by 1e18)
   */
  function getBorrowRate(uint cash, uint borrows, uint reserves) external view returns (uint);

  /**
   * @notice Calculates the current supply interest rate per block
   * @param cash The total amount of cash the market has
   * @param borrows The total amount of borrows the market has outstanding
   * @param reserves The total amnount of reserves the market has
   * @param reserveFactorMantissa The current reserve factor the market has
   * @return The supply rate per block (as a percentage, and scaled by 1e18)
   */
  function getSupplyRate(
    uint cash,
    uint borrows,
    uint reserves,
    uint reserveFactorMantissa
  ) external view returns (uint);
}