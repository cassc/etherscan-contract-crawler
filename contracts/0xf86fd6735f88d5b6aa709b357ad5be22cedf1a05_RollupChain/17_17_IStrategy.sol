// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title Interface for DeFi strategies
 *
 * @notice Strategy provides abstraction for a DeFi strategy. A single type of asset token can be committed to or
 * uncommitted from a strategy per instructions from L2. Periodically, the yield is reflected in the asset balance and
 * synced back to L2.
 */
interface IStrategy {
    event Committed(uint256 commitAmount);

    event UnCommitted(uint256 uncommitAmount);

    event ControllerChanged(address previousController, address newController);

    /**
     * @dev Returns the address of the asset token.
     */
    function getAssetAddress() external view returns (address);

    /**
     * @dev Harvests protocol tokens and update the asset balance.
     */
    function harvest() external;

    /**
     * @dev Returns the asset balance. May sync with the protocol to update the balance.
     */
    function syncBalance() external returns (uint256);

    /**
     * @dev Commits to strategy per instructions from L2.
     *
     * @param commitAmount The aggregated asset amount to commit.
     */
    function aggregateCommit(uint256 commitAmount) external;

    /**
     * @dev Uncommits from strategy per instructions from L2.
     *
     * @param uncommitAmount The aggregated asset amount to uncommit.
     */
    function aggregateUncommit(uint256 uncommitAmount) external;
}