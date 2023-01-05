// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10;

/**
* @notice IFireCatYieldBoots
*/
interface IFireCatYieldBoots {

    /**
    * @notice the total staked amount.
    * @return totalStaked
    */
    function totalStaked() external view returns (uint256);

    /**
    * @notice the total claimed amount.
    * @return totalClaimed
    */
    function totalClaimed() external view returns (uint256);

    /**
    * @notice the rewardRate of stake amount.
    * @return rewardRate
    */
    function rewardRate(uint256 amount_) external view returns (uint256);

    /**
    * @notice the yield of each stake amount.
    * @return yield_amount
    */
    function yieldOf(uint256 amount_) external view returns (uint256);

    /**
    * @notice the staked amount of user.
    * @param user_ address
    * @return stakedAmount
    */
    function stakedOf(address user_) external view returns (uint256);

    /**
    * @notice the claimed amount of user.
    * @param user_ address
    * @return claimedAmount
    */
    function claimedOf(address user_) external view returns (uint256);

    /**
    * @notice check whether the user's stake amount is qualified.
    * @param user_ address
    * @param amount_ uint256
    * @return bool
    */
    function isStakeable(address user_, uint256 amount_) external view returns (bool);

    /**
    * @notice check the claim of user.
    * @param user_ address
    * @return availableClaim, lockedClaim, userClaimed, userTotalClaim
    */
    function reviewOf(address user_) external view returns (uint256, uint256, uint256, uint256);
    
    /**
    * @notice set the max stake amonut limit of user.
    * @param maxStakeAmount_ uint256
    * @param maxStakeTotalAmount_ uint256
    */
    function setMaxStakeAmount(uint256 maxStakeAmount_, uint256 maxStakeTotalAmount_) external;
    
    /**
    * @notice set the require stake amonut of FireCatVault.
    * @param vaultRequireAmount_ uint256
    */
    function setVaultRequireAmount(uint256 vaultRequireAmount_) external;

    /**
    * @notice set the stake time period
    * @param cycleTime_ uint256
    */
    function setCycleTime(uint256 cycleTime_) external ;

    /**
    * @notice set the rewardRate of each stake amount.
    * @param rewardRatePerToken_ uint256
    */
    function setRewardRatePerToken(uint256 rewardRatePerToken_) external;

    /**
    * @notice set the FireCatVault address.
    * @param fireCatVault_ address
    */
    function setFireCatVault(address fireCatVault_) external;

    /**
    * @notice The interface of IERC20 withdrawn.
    * @dev Trasfer token to admin.
    * @param token address.
    * @param amount uint256.
    * @return actualSubAmount.
    */
    function withdrawRemaining(address token, address to, uint256 amount) external returns (uint256);

    /**
    * @notice topUp the reward amount.
    * @param addAmount uint256
    * @return actualTopUpAmount
    */
    function topUp(uint256 addAmount) external returns (uint256);

    /**
    * @notice the interface of stake.
    * @param amount_ uint256
    * @return actualStakedAmount
    */
    function stake(uint256 amount_) external returns (uint256);

    /**
    * @notice the interface of claim.
    * @return actualClaimedAmount
    */
    function claim() external returns (uint256);
}