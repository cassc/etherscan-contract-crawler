// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10;

/**
* @notice IFireCatIssuePool
*/
interface IFireCatIssuePool {
    /**
    * @notice the total earnings amount
    * @return totalEarnings
    */
    function totalEarnings() external view returns (uint256);

    /**
    * @dev Rewards per token
    * @return Returns the reward amount for staked tokens
    */
    function rewardPerToken() external view returns (uint256);

    /**
    * @dev View user revenue
    * @param tokenId_ uint256
    * @return Returns the revenue the user has already earned
    */
    function earned(uint256 tokenId_) external view returns (uint256);

    /**
    * @dev Rewards that users can already claim
    * @param account_ User address
    * @return Returns the reward that the user has moderated
    */
    function userAward(address account_) external view returns (uint256);
    /**
    * @notice check the claim of user.
    * @param user_ address
    * @return availableClaim, claimed, locked
    */
    function reviewOf(address user_) external view returns (uint256, uint256, uint256);

    /**
    * @dev User earned reward, received reward
    * @param tokenId_ uint256
    * @return User data
    */
    function issueUserData(uint256 tokenId_) external view returns (uint256, uint256);

    /**
    * @notice set harvest rewardRate.
    * @param startingTime_ uint256
    * @param rewardRate_ uint256
    */
    function setRewardRate(uint256 startingTime_, uint256 rewardRate_) external;

    /**
    * @notice set reward LockTime.
    * @param newLockTime_ uint256
    */
    function setLockTime(uint256 newLockTime_) external;

    /**
    * @notice set the fireCatNFTStake contract.
    * @dev set to fireCatNFTStake.
    * @param fireCatNFTStake_ address.
    */
    function setFireCatNFTStake(address fireCatNFTStake_) external;

    /**
    * @notice The interface of token withdrawn.
    * @dev Trasfer token to to_address.
    * @param token address.
    * @param to address.
    * @param amount uint256.
    */
    function claimTokens(address token, address to, uint256 amount) external;

    /**
    * @notice topUp the reward amount.
    * @param addAmount uint256
    * @return actualAddAmount
    */
    function topUp(uint256 addAmount) external returns (uint256);

    /**
    * @notice the interface of stake
    * @param tokenId_ uint256
    * @param amount_ uint256
    */
    function stake(uint256 tokenId_, uint256 amount_) external;
    
    /**
    * @notice the interface of withdrawn
    * @param user_ address
    * @param tokenId_ uint256
    * @param amount_ uint256
    */
    function withdrawn(address user_, uint256 tokenId_, uint256 amount_) external;
    /**
    * @notice the interface of harvest
    * @param tokenId_ uint256
    */
    function harvest(uint256 tokenId_) external;

    /**
    * @notice the interface of claim
    */
    function claim() external;
}