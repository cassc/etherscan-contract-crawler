// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

import "./RewardProfile.sol";
import "./Percentage.sol";
import "./Math.sol";

struct Node {
    //--- Base attributes
    address owner;
    uint256 creationTime;
    uint256 lastClaimTime;
    uint256 obtainingTime;
    string feature;
    //--- Reward computation related
    uint256 accumulatedRewards;
    uint256 lastRewardUpdateTime;
    uint256 lastLifetime;
    uint256[] fertilizerCreationTime;
    uint256[] fertilizerDuration;
    uint256[] fertilizerBoost;
    uint256 plotAdditionalLifetime;
    uint256 totalClaimedRewards;
    bool hasAdjustedClaimRewards;
    uint8 ammosUsed;
}

abstract contract NodeRewards {
    using Percentages for uint256;

    function _price() internal view virtual returns (uint256);

    function _baseRewardsPerSecond(string memory feature) internal view virtual returns (uint256);

    function _timeToGRP(string memory feature) internal view returns (uint256) {
        return _price() / _baseRewardsPerSecond(feature);
    }

    function _initialLifetime(string memory feature) internal view returns (uint256) {
        // 2,5x GRP : 1 + 0,5 GRP at 100%, 1 GRP at 50%
        return (5 * _timeToGRP(feature)) / 2;
    }

    function _newNode(address owner, string memory feature) internal view returns (Node memory) {
        return
            Node({
                owner: owner,
                creationTime: block.timestamp,
                lastClaimTime: block.timestamp,
                obtainingTime: block.timestamp,
                feature: feature,
                accumulatedRewards: 0,
                lastRewardUpdateTime: block.timestamp,
                lastLifetime: _initialLifetime(feature),
                fertilizerCreationTime: new uint256[](0),
                fertilizerDuration: new uint256[](0),
                fertilizerBoost: new uint256[](0),
                plotAdditionalLifetime: 0,
                totalClaimedRewards: 0,
                hasAdjustedClaimRewards: false,
                ammosUsed: 0
            });
    }

    function _persistRewards(Node storage node) internal {
        node.accumulatedRewards +=
            _calculateBaseNodeRewards(node) -
            node.accumulatedRewards;
        node.lastLifetime = Math.subOrZero(
            node.lastLifetime,
            Math.subOrZero(block.timestamp, node.lastRewardUpdateTime)
        );
        node.lastRewardUpdateTime = block.timestamp;
    }

    function _extendLifetime(
        Node storage node,
        uint256 ratioOfGRPExtended,
        uint256 amount
    ) internal {
        _persistRewards(node);
            node.lastLifetime +=
            Percentages.times(ratioOfGRPExtended, _timeToGRP(node.feature)) *
            amount;
    }

    function _addFertilizer(
        Node storage node,
        uint256 durationEffect,
        uint256 rewardBoost,
        uint256 amount
    ) internal {
        _persistRewards(node);
        for (uint256 i = 0; i < amount; i++) {
            node.fertilizerCreationTime.push(block.timestamp);
            node.fertilizerDuration.push(durationEffect);
            node.fertilizerBoost.push(rewardBoost);
        }
    }

    function _calculateBaseNodeRewards(Node storage node)
        internal
        view
        returns (uint256)
    {
        uint256 baseRewards = GRPDependantRewardProfile
            .integrateRewardsFromLifetime(
                _price(),
                _baseRewardsPerSecond(node.feature),
                node.lastLifetime + node.plotAdditionalLifetime,
                Math.subOrZero(block.timestamp, node.lastRewardUpdateTime)
            );

        // for (uint256 i = 0; i < node.fertilizerBoost.length; i++) {
        //     // Each fertilizer has a duration effect that is not dependant
        //     // on the lifetime of the node. However, the rewards might have
        //     // been accumulated from a previous operation. Therefore, we
        //     // need to remove the accumulated rewards from the fertilizer
        //     // boost calculation, hence computing the rewards from
        //     // now until the known end time of the fertilizer.
        //     uint256 fertilizerBoost = GRPDependantRewardProfile
        //         .integrateFertilizerAdditionalRewards(
        //             _baseRewardsPerSecond(node.feature),
        //             node.fertilizerBoost[i],
        //             Math.subOrZero(
        //                 node.fertilizerDuration[i] +
        //                     node.fertilizerCreationTime[i],
        //                 node.lastRewardUpdateTime
        //             ),
        //             Math.subOrZero(block.timestamp, node.lastRewardUpdateTime)
        //         );

        //     baseRewards += fertilizerBoost;
        // }

        return baseRewards + node.accumulatedRewards;
    }

    function _getCurrentRewardsPerSeconds(Node storage node)
        internal
        view
        returns (uint256 rewardsPerSeconds, uint256 currentTime)
    {
        rewardsPerSeconds = GRPDependantRewardProfile
            .getRewardsPerSecondsAtGivenLifetime(
                _price(),
                _baseRewardsPerSecond(node.feature),
                _getCurrentNodeLifetime(node)
            );
        currentTime = block.timestamp;
    }

    function _getCurrentNodeLifetime(Node storage node)
        internal
        view
        returns (uint256 lifetime)
    {
        return Math.subOrZero(node.lastLifetime + node.plotAdditionalLifetime, Math.subOrZero(block.timestamp, node.lastRewardUpdateTime));
    }
}