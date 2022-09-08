//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "../../external/IERC677Token.sol";

interface ITradingFeeIncentives {
    /// @notice Add incentives on trading fee based on the amount of fees generated.
    function addFee(address user, uint256 amount) external;

    /// @notice The rewards token that this contract uses
    function rewardsToken() external view returns (IERC677Token);

    /// @notice The contract that holds the tokens for the lockup period.
    function tokenLocker() external view returns (address);

    /// @notice The contract that calculates the incentives.
    function feeUpdater() external view returns (address);

    /// @notice Single period length in seconds.
    function periodLength() external view returns (uint256);

    /// @notice Rewards distributed in the current period.
    function currentPeriodRewards() external view returns (uint256);

    /// @notice Returns the amount of tokens that the account can claim
    /// @param account The account to claim for
    function getClaimableTokens(address account) external view returns (uint256);

    /// @notice Event emitted on calls to addFee.
    /// @param user Address of the trader paying the trade fee.
    /// @param amount The fee paid which determines the proportion of the rewards
    /// @param rewardsAccumulated The total rewards accumulated from previous periods.
    /// @param shares The total shares accumulated in this period.
    event FeeAdded(address user, uint256 amount, uint256 rewardsAccumulated, uint256 shares);

    /// @notice Event emited when rewards are added.
    /// @param amount Amount of rewards added.
    /// @param rewardsLeft Amount of rewards distrubuted over the next periods.
    /// @param currentPeriod Period the rewards were added.
    /// @param endPeriod Period the rewards will end.
    event RewardsAdded(
        uint256 amount,
        uint256 rewardsLeft,
        uint256 currentPeriod,
        uint256 endPeriod
    );

    /// @notice Event emited when rewards are ended.
    /// @param refund Amount of rewards refunded.
    /// @param period Period when the rewards were ended.
    event RewardsEnded(uint256 refund, uint256 period);

    /// @notice Event emitted when the FeeUpdater contract is changed.
    /// @param oldFeeUpdaterAddress old FeeUpdater.
    /// @param newFeeUpdaterAddress new FeeUpdater.
    event FeeUpdaterChanged(address oldFeeUpdaterAddress, address newFeeUpdaterAddress);

    /// @notice Event emitted the rewards token is updated.
    /// @param oldRewardsToken The rewards token before the update.
    /// @param newRewardsToken The rewards token after the update.
    event RewardsTokenUpdated(address oldRewardsToken, address newRewardsToken);
}