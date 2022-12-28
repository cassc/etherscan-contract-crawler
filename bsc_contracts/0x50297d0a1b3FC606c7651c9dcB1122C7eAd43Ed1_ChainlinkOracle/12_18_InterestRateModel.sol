pragma solidity ^0.5.16;

/**
  * @title Venus's InterestRateModel Interface
  * @author Venus
  *
  *** Modifications ***
  * getBorrowRate() replaced cash to availableCash
  * getSupplyRate() replaced cash to availableCash
  *                 added new parameter exchangeCash
  */
contract InterestRateModel {
    /// @notice Indicator that this is an InterestRateModel contract (for inspection)
    bool public constant isInterestRateModel = true;

    /**
      * @notice Calculates the current borrow interest rate per block
      * @param availableCash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amnount of reserves the market has
      * @return The borrow rate per block (as a percentage, and scaled by 1e18)
      */
    function getBorrowRate(uint availableCash, uint borrows, uint reserves) external view returns (uint);


    /**
     * @notice Calculates the current supply rate per block
     * @param availableCash cashPlusUsdMultRate (lower cash when abs(iUSD) large)
     * @param exchangeCash cashPlusUsdPrior (the total real cash in market 
     * @param borrows The amount of borrows in the market
     * @param reserves The amount of reserves in the market
     * @param reserveFactorMantissa The current reserve factor for the market
     * @return The supply rate percentage per block as a mantissa (scaled by 1e18)
     */
    function getSupplyRate(uint availableCash, uint exchangeCash, uint borrows, uint reserves, uint reserveFactorMantissa) public view returns (uint);

}