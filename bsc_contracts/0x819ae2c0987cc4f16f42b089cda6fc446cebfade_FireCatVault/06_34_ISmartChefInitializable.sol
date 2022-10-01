// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10;

/**
 * @title ISmartChefInitializable contract interface
 */
interface ISmartChefInitializable {
    /**
     * @notice Deposit staked tokens and collect reward tokens (if any)
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function deposit(uint256 _amount) external;

    /**
     * @notice return user staked and rewardDebt
     * @param user_: user_address
     */
    function userInfo(address user_) external returns(uint256, uint256);
    
    /**
     * @notice Withdraw staked tokens and collect reward tokens
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function withdraw(uint256 _amount) external;

    /**
     * @notice Withdraw staked tokens without caring about rewards rewards
     * @dev Needs to be for emergency.
     */
    function emergencyWithdraw() external;

    /**
     * @notice View function to see pending reward on frontend.
     * @param _user: user address
     * @return Pending reward for a given user
     */
    function pendingReward(address _user) external view returns (uint256);

    /**
     * @notice Return user limit is set or zero.
     */
    function hasUserLimit() external view returns (bool);

    /**
     * @notice Get reward tokens
     */
    function rewardToken() external view returns (address);

}