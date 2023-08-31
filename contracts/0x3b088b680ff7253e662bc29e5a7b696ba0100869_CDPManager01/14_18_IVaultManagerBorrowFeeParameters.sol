// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2021 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.7.6;

interface IVaultManagerBorrowFeeParameters {

    /**
     * @notice 1 = 100% = 10000 basis points
     **/
    function BASIS_POINTS_IN_1() external view returns (uint);

    /**
     * @notice Borrow fee receiver
     **/
    function feeReceiver() external view returns (address);

    /**
     * @notice Sets the borrow fee receiver. Only manager is able to call this function
     * @param newFeeReceiver The address of fee receiver
     **/
    function setFeeReceiver(address newFeeReceiver) external;

    /**
     * @notice Sets the base borrow fee in basis points (1bp = 0.01% = 0.0001). Only manager is able to call this function
     * @param newBaseBorrowFeeBasisPoints The borrow fee in basis points
     **/
    function setBaseBorrowFee(uint16 newBaseBorrowFeeBasisPoints) external;

    /**
     * @notice Sets the borrow fee for a particular collateral in basis points (1bp = 0.01% = 0.0001). Only manager is able to call this function
     * @param asset The address of the main collateral token
     * @param newEnabled Is custom fee enabled for asset
     * @param newFeeBasisPoints The borrow fee in basis points
     **/
    function setAssetBorrowFee(address asset, bool newEnabled, uint16 newFeeBasisPoints) external;

    /**
     * @notice Returns borrow fee for particular collateral in basis points (1bp = 0.01% = 0.0001)
     * @param asset The address of the main collateral token
     * @return feeBasisPoints The borrow fee in basis points
     **/
    function getBorrowFee(address asset) external view returns (uint16 feeBasisPoints);

    /**
     * @notice Returns borrow fee for usdp amount for particular collateral
     * @param asset The address of the main collateral token
     * @return The borrow fee
     **/
    function calcBorrowFeeAmount(address asset, uint usdpAmount) external view returns (uint);
}