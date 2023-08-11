// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

/**
 * @notice Interface for adapters that allow interactions with the lending protocols
 */
interface IAdapter {
    /**
     * @notice Returns the adapter's ID
     */
    function id() external view returns (uint256);

    /**
     * @notice Sets the necessary approvals (allowances) for interacting with the lending protocol
     */
    function setApprovals() external;

    /**
     * @notice Removes the given approvals (allowances) for interacting with the lending protocol
     */
    function revokeApprovals() external;

    /**
     * @notice Supplies the given amount of collateral to the lending protocol
     * @param amount The amount of collateral to supply
     */
    function supply(uint256 amount) external;

    /**
     * @notice Borrows the given amount of debt from the lending protocol
     * @param amount The amount of debt to borrow
     */
    function borrow(uint256 amount) external;

    /**
     * @notice Repays the given amount of debt to the lending protocol
     * @param amount The amount of debt to repay
     */
    function repay(uint256 amount) external;

    /**
     * @notice Withdraws the given amount of collateral from the lending protocol
     * @param amount The amount of collateral to withdraw
     */
    function withdraw(uint256 amount) external;

    /**
     * @notice Claims rewards awarded by the lending protocol
     * @param data Any data needed for the claim process
     */
    function claimRewards(bytes calldata data) external;

    /**
     * @notice Returns the amount of collateral currently supplied to the lending protocol
     * @param account The account to check
     */
    function getCollateral(address account) external view returns (uint256);

    /**
     * @notice Returns the amount of debt currently borrowed from the lending protocol
     * @param account The account to check
     */
    function getDebt(address account) external view returns (uint256);

    /**
     * @notice Returns the maximum loan-to-value (LTV) ratio for the lending protocol
     */
    function getMaxLtv() external view returns (uint256);
}