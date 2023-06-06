// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IProtocolRevenueManager {
    struct AuctionRevenueSplit {
        uint64 treasurySplit;
        uint64 nodeOperatorSplit;
        uint64 tnftHolderSplit;
        uint64 bnftHolderSplit;
    }

    function globalRevenueIndex() external view returns (uint256);

    function auctionFeeVestingPeriodForStakersInDays()
        external
        view
        returns (uint128);

    function getAccruedAuctionRevenueRewards(
        uint256 _validatorId
    ) external view returns (uint256);

    function addAuctionRevenue(uint256 _validatorId) external payable;

    function distributeAuctionRevenue(
        uint256 _validatorId
    ) external returns (uint256);

    function setEtherFiNodesManagerAddress(
        address _etherFiNodesManager
    ) external;

    function setAuctionManagerAddress(address _auctionManager) external;

    function setAuctionRewardVestingPeriod(uint128 _periodInDays) external;

    function setAuctionRewardSplitForStakers(uint128 _split) external;
}