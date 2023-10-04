// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface ICurveStakingHelper {
    /**
     * @notice Deposit `value` LP tokens, curve type take pools
     * @param value Number of tokens to deposit
     */
    function deposit(uint256 value) external;

    /**
     * @notice Withdraw `value` LP tokens, curve type take pools
     * @dev This withdraw function is for gauges v1 and v2
     * @param value Number of tokens to withdraw
     */
    function withdraw(uint256 value) external;

    /**
     * @notice Withdraw `value` LP tokens, curve type take pools
     * @dev This withdraw function is for gauges v3, v4 and v5
     * @param value Number of tokens to withdraw
     * @param withdrawRewards true if withdrawing rewards
     */
    function withdraw(uint256 value, bool withdrawRewards) external;

    /**
     * @notice Claim all available reward tokens for msg.sender
     */
    function claim_rewards() external;

    /**
     * @notice Mint allocated tokens for the caller based on a single gauge.
     * @param gaugeAddr address to get mintable amount from
     */
    function mint(address gaugeAddr) external;

    /**
     * @notice returns lpToken address for gauge
     */
    function lp_token() external view returns (address);

    /**
     * @notice returns reward token address for liquidity gauge by index
     * @param index index of particular token address in the reward token array
     */
    function reward_tokens(uint256 index) external view returns (address);

    /**
     * @notice returns gauge address by index from gaugeController
     * @param index index in gauge controller array that returns liquidity gauge address
     */
    function gauges(uint256 index) external view returns (address);
}