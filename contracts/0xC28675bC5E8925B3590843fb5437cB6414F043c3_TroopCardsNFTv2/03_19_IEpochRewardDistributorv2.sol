interface IEpochRewardDistributorv2 {
    function beforeTransferRewards(uint256 nftID, address user) external;

    function claimRewardsOfUser(address user, uint256[] calldata nftsOfUser)
        external
        returns (uint256 reward);
}