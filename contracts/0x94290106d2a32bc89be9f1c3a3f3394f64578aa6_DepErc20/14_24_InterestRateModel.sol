// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

/**
  * @title Vortex's InterestRateModel Interface
  * @author Vortex
  */
abstract contract InterestRateModel {
    /// @notice contract property
    bool public constant isInterestRateModel = true;

    /**
      * @notice Calculates the current borrow interest rate per block
      * @param iur ideal utilisation rate
      * @param cRatePerBlock compound rate
      * @return The borrow rate per block (as a percentage, and scaled by 1e18)
      */
    function getBorrowRate(uint iur, uint cRatePerBlock) virtual external view returns (uint);

    /**
      * @notice Calculates the current supply interest rate per block
      * @param iur ideal utilisation rate
      * @param cRatePerBlock compound rate
      * @return The supply rate per block (as a percentage, and scaled by 1e18)
      */
    function getSupplyRate(uint iur, uint cRatePerBlock) virtual external view returns (uint);
}