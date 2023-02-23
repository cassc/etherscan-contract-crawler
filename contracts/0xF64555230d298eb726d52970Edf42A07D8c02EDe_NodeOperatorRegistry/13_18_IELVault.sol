// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.8;

/**
 * @title Interface for IELVault
 * @notice Vault will manage methods for rewards, commissions, tax
 */
interface IELVault {
    struct RewardMetadata {
        uint256 value;
        uint256 height;
    }

    /**
     * @notice Computes the reward a nft has
     * @param _tokenId - tokenId of the validator nft
     */
    function rewards(uint256 _tokenId) external view returns (uint256);

    /**
     * @notice get liquidStaking pool reward
     */
    function getLiquidStakingRewards() external view returns (uint256);

    /**
     * @notice Gets the last recorded height which rewards was last dispersed + 1
     */
    function rewardsHeight() external view returns (uint256);

    /**
     * @notice Returns an array of recent `RewardMetadata`
     * @param _amt - The amount of `RewardMetdata` to return, ordered according to the most recent
     */
    function rewardsAndHeights(uint256 _amt) external view returns (RewardMetadata[] memory);

    function dao() external view returns (address);

    /**
     * @notice Settles outstanding rewards
     * @dev Current active validator nft will equally recieve all rewards earned in this era
     */
    function settle() external;

    /**
     * @notice Settles outstanding rewards in the event there is no change in amount of validators
     * @dev Current active validator nft will equally recieve  all rewards earned in this era
     */
    function publicSettle() external;

    /**
     * @notice Reinvesting rewards belonging to the liquidStaking pool
     */
    function reinvestmentOfLiquidStaking() external returns (uint256);

    /**
     * @notice Claims the rewards belonging to a validator nft and transfer it to the owner
     * @param _tokenId - tokenId of the validator nft
     */
    function claimRewardsOfUser(uint256 _tokenId) external returns (uint256);

    /**
     * @notice Set the gas height of user nft
     */
    function setUserNft(uint256 _tokenId, uint256 _number) external;

    /**
     * @notice Set the gas height of liquidStaking nft
     */
    function setLiquidStakingGasHeight(uint256 _gasHeight) external;

    /**
     * @notice Operater Claims the rewards
     */
    function claimOperatorRewards() external returns (uint256);

    /**
     * @notice Dao Claims the rewards
     */
    function claimDaoRewards(address _to) external returns (uint256);

    event ComissionRateChanged(uint256 _before, uint256 _after);
    event LiquidStakingChanged(address _before, address _after);
    event PublicSettleLimitChanged(uint256 _before, uint256 _after);
    event RewardClaimed(address _owner, uint256 _amount);
    event RewardReinvestment(address _liquidStakingContract, uint256 _nftRewards);
    event Transferred(address _to, uint256 _amount);
    event Settle(uint256 _blockNumber, uint256 _settleRewards, uint256 _operatorNftCounts, uint256 _averageRewards);
    event DaoAddressChanged(address _oldDao, address _dao);
    event OperatorRewardsClaimed(uint256 _rewards);
    event DaoRewardsClaimed(uint256 _rewards, address _to);
}