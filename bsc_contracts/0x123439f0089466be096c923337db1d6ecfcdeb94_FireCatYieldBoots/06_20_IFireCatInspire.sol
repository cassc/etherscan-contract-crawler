// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10;

/**
* @notice IFireCatInspire
*/
interface IFireCatInspire {

    /**
    * @notice the yield booster reward of user.
    * @param user_ address
    * @return (availableReward, claimed, totalReward)
    */
    function yieldRewardOf(address user_) external view returns (uint256, uint256, uint256);

     /**
    * @notice the NFT level up reward of user.
    * @param user_ address
    * @return (availableReward, claimed, totalReward)
    */
    function nftLevelUpRewardOf(address user_) external view returns (uint256, uint256, uint256);

    /**
    * @notice set the inviter share rate.
    * @param inviterRate_ uint256
    */
    function setInviterRate(uint256 inviterRate_) external;

    /**
    * @notice set the superior share rate.
    * @param superiorRate_ uint256
    */
    function setSuperiorRate(uint256 superiorRate_) external;

    /**
    * @notice set the rewardToken_ address.
    * @param rewardToken_ address
    */
    function setRewardToken(address rewardToken_) external;

    /**
    * @notice set the fireCatNFT address.
    * @param fireCatNFTAddress_ address
    */
    function setFireCatNFT(address fireCatNFTAddress_) external;

    /**
    * @notice set the fireCatNFTStake address.
    * @param fireCatNFTStakeAddress_ address
    */
    function setFireCatNFTStake(address fireCatNFTStakeAddress_) external;

    /**
    * @notice set the fireCatReserves address.
    * @param fireCatReservesAddress_ address
    */
    function setFireCatReserves(address fireCatReservesAddress_) external;

    /**
    * @notice set the fireCatRegistryProxy address.
    * @param fireCatRegistryProxyAddress_ address
    */
    function setFireCatRegistryProxy(address fireCatRegistryProxyAddress_) external;

    /**
    * @notice set the fireCatYieldBoots address.
    * @param fireCatYieldBootsAddress_ address
    */
    function setFireCatYieldBoots(address fireCatYieldBootsAddress_) external;

    /**
    * @notice The interface of IERC20 withdrawn.
    * @dev Trasfer token to admin.
    * @param token address.
    * @param amount uint256.
    * @return actualSubAmount.
    */
    function withdrawRemaining(address token, address to, uint256 amount) external returns (uint256);

    /**
    * @notice The interface of yield Booster share.
    * @dev Trasfer token to here
    * @param user_ address.
    * @param amount_ uint256.
    * @return restAmount.
    */
    function yieldBootsShare(address user_, uint256 amount_) external returns (uint256);

    /**
    * @notice The interface of NFT level up share.
    * @dev Trasfer token to here
    * @param user_ address.
    * @param tokenId_ uint256.
    * @param amount_ uint256.
    * @return restAmount.
    */
    function nftLevelUpShare(address user_, uint256 tokenId_, uint256 amount_) external returns (uint256);

    /**
    * @notice the interface of claim.
    * @return actualClaimedAmount
    */
    function claim() external returns (uint256);
}