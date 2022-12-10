// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";

interface IHeart {
    // =========  EVENTS ========= //

    event Beat(uint256 timestamp_);
    event RewardIssued(address to_, uint256 rewardAmount_);
    event RewardUpdated(ERC20 token_, uint256 rewardAmount_);

    // =========  ERRORS ========= //

    error Heart_OutOfCycle();
    error Heart_BeatStopped();
    error Heart_InvalidParams();
    error Heart_BeatAvailable();

    // =========  CORE FUNCTIONS ========= //

    /// @notice Beats the heart
    /// @notice Only callable when enough time has passed since last beat (determined by frequency variable)
    /// @notice This function is incentivized with a token reward (see rewardToken and reward variables).
    /// @dev    Triggers price oracle update and market operations
    function beat() external;

    // =========  ADMIN FUNCTIONS ========= //

    /// @notice Unlocks the cycle if stuck on one side, eject function
    /// @notice Access restricted
    function resetBeat() external;

    /// @notice Turns the heart on and resets the beat
    /// @notice Access restricted
    /// @dev    This function is used to restart the heart after a pause
    function activate() external;

    /// @notice Turns the heart off
    /// @notice Access restricted
    /// @dev    Emergency stop function for the heart
    function deactivate() external;

    /// @notice Updates the Operator contract address that the Heart calls on a beat
    /// @notice Access restricted
    /// @param  operator_ The address of the new Operator contract
    function setOperator(address operator_) external;

    /// @notice Sets the reward token and amount for the beat function
    /// @notice Access restricted
    /// @param  token_ - New reward token address
    /// @param  reward_ - New reward amount, in units of the reward token
    function setRewardTokenAndAmount(ERC20 token_, uint256 reward_) external;

    /// @notice Withdraws unspent balance of provided token to sender
    /// @notice Access restricted
    function withdrawUnspentRewards(ERC20 token_) external;

    // =========  VIEW FUNCTIONS ========= //

    /// @notice Heart beat frequency, in seconds
    function frequency() external view returns (uint256);
}