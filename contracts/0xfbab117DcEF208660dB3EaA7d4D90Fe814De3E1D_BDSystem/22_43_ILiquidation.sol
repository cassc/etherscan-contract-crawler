// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/IAccessControl.sol";

import "./IMToken.sol";
import "./IDeadDrop.sol";
import "./ILinkageLeaf.sol";
import "./IPriceOracle.sol";

/**
 * This contract provides the liquidation functionality.
 */
interface ILiquidation is IAccessControl, ILinkageLeaf {
    event HealthyFactorLimitChanged(uint256 oldValue, uint256 newValue);
    event NewDeadDrop(IDeadDrop oldDeadDrop, IDeadDrop newDeadDrop);
    event NewInsignificantLoanThreshold(uint256 oldValue, uint256 newValue);
    event ReliableLiquidation(
        bool isManualLiquidation,
        bool isDebtHealthy,
        address liquidator,
        address borrower,
        IMToken[] marketAddresses,
        uint256[] seizeIndexes,
        uint256[] debtRates
    );

    /**
     * @dev Local accountState for avoiding stack-depth limits in calculating liquidation amounts.
     */
    struct AccountLiquidationAmounts {
        uint256 accountTotalSupplyUsd;
        uint256 accountTotalCollateralUsd;
        uint256 accountPresumedTotalSeizeUsd;
        uint256 accountTotalBorrowUsd;
        uint256[] repayAmounts;
        uint256[] seizeAmounts;
    }

    /**
     * @notice GET The maximum allowable value of a healthy factor after liquidation, scaled by 1e18
     */
    function healthyFactorLimit() external view returns (uint256);

    /**
     * @notice GET Maximum sum in USD for internal liquidation. Collateral for loans that are less
     * than this parameter will be counted as protocol interest, scaled by 1e18
     */
    function insignificantLoanThreshold() external view returns (uint256);

    /**
     * @notice get keccak-256 hash of TRUSTED_LIQUIDATOR role
     */
    function TRUSTED_LIQUIDATOR() external view returns (bytes32);

    /**
     * @notice get keccak-256 hash of MANUAL_LIQUIDATOR role
     */
    function MANUAL_LIQUIDATOR() external view returns (bytes32);

    /**
     * @notice get keccak-256 hash of TIMELOCK role
     */
    function TIMELOCK() external view returns (bytes32);

    /**
     * @notice Liquidate insolvent debt position
     * @param borrower_ Account which is being liquidated
     * @param seizeIndexes_ An array with market indexes that will be used as collateral.
     *        Each element corresponds to the market index in the accountAssets array
     * @param debtRates_  An array of debt redemption rates for each debt markets (scaled by 1e18).
     * @dev RESTRICTION: Trusted liquidator only
     */
    function liquidateUnsafeLoan(
        address borrower_,
        uint256[] memory seizeIndexes_,
        uint256[] memory debtRates_
    ) external;

    /**
     * @notice Accrues interest for all required borrower's markets
     * @dev Accrue is required if market is used as borrow (debtRate > 0)
     *      or collateral (seizeIndex arr contains market index)
     *      The caller must ensure that the lengths of arrays 'accountAssets' and 'debtRates' are the same,
     *      array 'seizeIndexes' does not contain duplicates and none of the indexes exceeds the value
     *      (accountAssets.length - 1).
     * @param accountAssets An array with addresses of markets where the debtor is in
     * @param seizeIndexes_ An array with market indexes that will be used as collateral
     *        Each element corresponds to the market index in the accountAssets array
     * @param debtRates_ An array of debt redemption rates for each debt markets (scaled by 1e18)
     */
    function accrue(
        IMToken[] memory accountAssets,
        uint256[] memory seizeIndexes_,
        uint256[] memory debtRates_
    ) external;

    /**
     * @notice For each market calculates the liquidation amounts based on borrower's state.
     * @param account_ The address of the borrower
     * @param marketAddresses An array with addresses of markets where the debtor is in
     * @param seizeIndexes_ An array with market indexes that will be used as collateral
     *        Each element corresponds to the market index in the accountAssets array
     * @param debtRates_ An array of debt redemption rates for each debt markets (scaled by 1e18)
     * @return accountState Struct that contains all balance parameters
     *         All arrays calculated in underlying assets, all total values calculated in USD.
     *         (the array indexes match each other)
     */
    function calculateLiquidationAmounts(
        address account_,
        IMToken[] memory marketAddresses,
        uint256[] memory seizeIndexes_,
        uint256[] memory debtRates_
    ) external view returns (AccountLiquidationAmounts memory);

    /**
     * @notice Sets a new value for healthyFactorLimit
     * @dev RESTRICTION: Timelock only
     */
    function setHealthyFactorLimit(uint256 newValue_) external;

    /**
     * @notice Sets a new minterest deadDrop
     * @dev RESTRICTION: Admin only
     */
    function setDeadDrop(IDeadDrop newDeadDrop_) external;

    /**
     * @notice Sets a new insignificantLoanThreshold
     * @dev RESTRICTION: Timelock only
     */
    function setInsignificantLoanThreshold(uint256 newValue_) external;
}