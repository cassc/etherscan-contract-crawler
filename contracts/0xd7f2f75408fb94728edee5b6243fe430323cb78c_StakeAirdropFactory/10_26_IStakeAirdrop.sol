// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
* @notice IStakeAirdrop
*/
interface IStakeAirdrop {
    /**
    * @notice the stake time period
    * @return startAt, expiredAt 
    */
    function cycle() external view returns (uint256, uint256);

    /**
    * @notice the release time period
    * @return releaseTimePeriod
    */
    function releaseTimePeriod() external view returns (uint256[] memory);

    /**
    * @notice the release num factor
    * @return releaseNumFactor
    */
    function releaseNumFactor() external view returns (uint256[] memory);

    /**
    * @notice the stake token
    * @return stakeToken
    */
    function stakeToken() external view returns (address);

    /**
    * @notice the airdrop token
    * @return airdropToken
    */
    function airdropToken() external view returns (address);

    /**
    * @notice the airdrop amount, topUp amonut must be equal this value.
    * @return airdropAmount
    */
    function topUpAmount() external view returns (uint256);

    /**
    * @notice the airdrop amount, after topUp(), this value will be equal to topUpAmount.
    * @return totalSupply
    */
    function totalSupply() external view returns (uint256);

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
    * @notice the amout of user who has staked.
    * @dev when user staked, this value will be add 1.
    * @return totalUser
    */
    function totalUser() external view returns (uint256);

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
    * @notice export staked user, staked amount
    * @dev start index of array, end index of array.
    * @param startIndex uint256
    * @param endIndex uint256
    * @return stakedUser, stakedAmount
    */
    function exportStaked(uint256 startIndex, uint256 endIndex) external view returns(address[] memory, uint256[] memory);

    /**
    * @notice check the aridrop of user.
    * @param user_ address
    * @return availableClaim, lockedClaim, totalClaim
    */
    function reviewOf(address user_) external view returns (uint256, uint256, uint256);

    /**
    * @notice the stake switch, default is false
    * @param isStakeOn_ bool
    */
    function setStakeOn(bool isStakeOn_) external;

    /**
    * @notice the claim switch, default is false
    * @param isClaimOn_ bool
    */
    function setClaimOn(bool isClaimOn_) external;

    /**
    * @notice the import staked switch, default is false
    * @param isImportOn_ bool
    */
    function setImportOn(bool isImportOn_) external;

    /**
    * @notice set the airdrop amount
    * @param topUpAmount_ uint256
    */
    function setTopUpAmount(uint256 topUpAmount_) external;

    /**
    * @notice set the stake time period
    * @param startAt_ uint256
    * @param expiredAt_ uint256
    */
    function setCycleTime(uint256 startAt_, uint256 expiredAt_) external;

    /**
    * @notice set the release time period, release num factor
    * @param releaseTimePeriod_ uint256[]
    * @param releaseNumFactor_ uint256[]
    */
    function setReleaseConfig(uint256[] memory releaseTimePeriod_, uint256[] memory releaseNumFactor_) external;

    /**
    * @notice import staked user, staked amonut.
    * @param userArray_ address[]
    * @param userStaked_ uint256[]
    * @return result
    */
    function importStaked(address[] memory userArray_, uint256[] memory userStaked_) external returns (uint256);

    /**
    * @notice The interface of IERC20 withdrawn.
    * @dev Trasfer token to admin.
    * @param token address.
    * @param amount uint256.
    * @return actualSubAmount.
    */
    function withdrawRemaining(address token, uint256 amount) external returns (uint256);

    /**
    * @notice topUp the airdrop amount.
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
    function claim() external  returns (uint256);
}