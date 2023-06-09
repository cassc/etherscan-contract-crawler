// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IController} from "../interfaces/IController.sol";
// solhint-disable-next-line no-global-import
import "../utils/Utils.sol" as Utils;

library GroupLib {
    // *Constants*
    uint256 public constant DEFAULT_MINIMUM_THRESHOLD = 3;

    struct GroupData {
        uint256 epoch;
        uint256 groupCount;
        mapping(uint256 => IController.Group) groups; // group_index => Group struct
        uint256 idealNumberOfGroups;
        uint256 groupMaxCapacity;
        uint256 defaultNumberOfCommitters;
    }

    event GroupRebalanced(uint256 indexed groupIndex1, uint256 indexed groupIndex2);

    // =============
    // Transaction
    // =============

    function setConfig(
        GroupData storage groupData,
        uint256 idealNumberOfGroups,
        uint256 groupMaxCapacity,
        uint256 defaultNumberOfCommitters
    ) public {
        groupData.idealNumberOfGroups = idealNumberOfGroups;
        groupData.groupMaxCapacity = groupMaxCapacity;
        groupData.defaultNumberOfCommitters = defaultNumberOfCommitters;
    }

    function nodeJoin(GroupData storage groupData, address idAddress, uint256 lastOutput)
        public
        returns (uint256 groupIndex, uint256[] memory groupIndicesToEmitEvent)
    {
        groupIndicesToEmitEvent = new uint256[](0);

        bool needRebalance;
        (groupIndex, needRebalance) = findOrCreateTargetGroup(groupData);

        bool needEmitGroupEvent = addToGroup(groupData, idAddress, groupIndex);
        if (needEmitGroupEvent) {
            groupIndicesToEmitEvent = new uint256[](1);
            groupIndicesToEmitEvent[0] = groupIndex;
            return (groupIndex, groupIndicesToEmitEvent);
        }

        if (needRebalance) {
            (bool rebalanceSuccess, uint256 groupIndexToRebalance) =
                tryRebalanceGroup(groupData, groupIndex, lastOutput);
            if (rebalanceSuccess) {
                groupIndicesToEmitEvent = new uint256[](2);
                groupIndicesToEmitEvent[0] = groupIndex;
                groupIndicesToEmitEvent[1] = groupIndexToRebalance;
            }
        }
    }

    function nodeLeave(GroupData storage groupData, address idAddress, uint256 lastOutput)
        public
        returns (uint256[] memory groupIndicesToEmitEvent)
    {
        groupIndicesToEmitEvent = new uint256[](0);

        (int256 groupIndex, int256 memberIndex) = getBelongingGroupByMemberAddress(groupData, idAddress);

        if (groupIndex != -1) {
            (bool needRebalance, bool needEmitGroupEvent) =
                removeFromGroup(groupData, uint256(memberIndex), uint256(groupIndex));
            if (needEmitGroupEvent) {
                groupIndicesToEmitEvent = new uint256[](1);
                groupIndicesToEmitEvent[0] = uint256(groupIndex);
                return groupIndicesToEmitEvent;
            }
            if (needRebalance) {
                return arrangeMembersInGroup(groupData, uint256(groupIndex), lastOutput);
            }
        }
    }

    function tryEnableGroup(GroupData storage groupData, uint256 groupIndex, uint256 lastOutput)
        public
        returns (bool success, address[] memory disqualifiedNodes)
    {
        IController.Group storage g = groupData.groups[groupIndex];
        IController.CommitCache memory identicalCommits =
            getStrictlyMajorityIdenticalCommitmentResult(groupData, groupIndex);

        if (identicalCommits.nodeIdAddress.length != 0) {
            disqualifiedNodes = identicalCommits.commitResult.disqualifiedNodes;

            // Get list of majority members with disqualified nodes excluded
            address[] memory majorityMembers =
                Utils.getNonDisqualifiedMajorityMembers(identicalCommits.nodeIdAddress, disqualifiedNodes);

            if (majorityMembers.length >= g.threshold) {
                // Remove all members from group where member.nodeIdAddress is in the disqualified nodes.
                for (uint256 i = 0; i < disqualifiedNodes.length; i++) {
                    for (uint256 j = 0; j < g.members.length; j++) {
                        if (g.members[j].nodeIdAddress == disqualifiedNodes[i]) {
                            g.members[j] = g.members[g.members.length - 1];
                            g.members.pop();
                            break;
                        }
                    }
                }

                // Update group with new values
                g.isStrictlyMajorityConsensusReached = true;
                g.size -= identicalCommits.commitResult.disqualifiedNodes.length;
                g.publicKey = identicalCommits.commitResult.publicKey;

                // Create indexMemberMap: Iterate through group.members and create mapping: memberIndex -> nodeIdAddress
                // Create qualifiedIndices: Iterate through group, add all member indexes found in majorityMembers.
                uint256[] memory qualifiedIndices = new uint256[](
                        majorityMembers.length
                    );

                for (uint256 j = 0; j < majorityMembers.length; j++) {
                    for (uint256 i = 0; i < g.members.length; i++) {
                        if (g.members[i].nodeIdAddress == majorityMembers[j]) {
                            qualifiedIndices[j] = i;
                            break;
                        }
                    }
                }

                // Compute commiter_indices by calling pickRandomIndex with qualifiedIndices as input.
                uint256[] memory committerIndices =
                    Utils.pickRandomIndex(lastOutput, qualifiedIndices, groupData.defaultNumberOfCommitters);

                // For selected commiter_indices: add corresponding members into g.committers
                g.committers = new address[](committerIndices.length);
                for (uint256 i = 0; i < committerIndices.length; i++) {
                    g.committers[i] = g.members[committerIndices[i]].nodeIdAddress;
                }

                return (true, disqualifiedNodes);
            }
        }
    }

    function handleUnsuccessfulGroupDkg(GroupData storage groupData, uint256 groupIndex, uint256 lastOutput)
        public
        returns (address[] memory nodesToBeSlashed, uint256[] memory groupIndicesToEmitEvent)
    {
        IController.Group storage g = groupData.groups[groupIndex];

        // get strictly majority identical commitment result
        IController.CommitCache memory majorityMembers =
            getStrictlyMajorityIdenticalCommitmentResult(groupData, groupIndex);

        if (majorityMembers.nodeIdAddress.length == 0) {
            // if empty cache: zero out group
            g.size = 0;
            g.threshold = 0;

            nodesToBeSlashed = new address[](g.members.length);
            for (uint256 i = 0; i < g.members.length; i++) {
                nodesToBeSlashed[i] = g.members[i].nodeIdAddress;
            }

            // zero out group members
            delete g.members;

            return (nodesToBeSlashed, new uint256[](0));
        } else {
            address[] memory disqualifiedNodes = majorityMembers.commitResult.disqualifiedNodes;
            g.size -= disqualifiedNodes.length;
            uint256 minimum = Utils.minimumThreshold(g.size);

            // set g.threshold to max (default min threshold / minimum threshold)
            g.threshold = GroupLib.DEFAULT_MINIMUM_THRESHOLD > minimum ? GroupLib.DEFAULT_MINIMUM_THRESHOLD : minimum;

            // Delete disqualified members from group
            for (uint256 j = 0; j < disqualifiedNodes.length; j++) {
                for (uint256 i = 0; i < g.members.length; i++) {
                    if (g.members[i].nodeIdAddress == disqualifiedNodes[j]) {
                        g.members[i] = g.members[g.members.length - 1];
                        g.members.pop();
                        break;
                    }
                }
            }

            return (disqualifiedNodes, arrangeMembersInGroup(groupData, groupIndex, lastOutput));
        }
    }

    function tryAddToExistingCommitCache(
        GroupData storage groupData,
        uint256 groupIndex,
        IController.CommitResult memory commitResult
    ) public returns (bool isExist) {
        IController.Group storage g = groupData.groups[groupIndex];
        for (uint256 i = 0; i < g.commitCacheList.length; i++) {
            if (keccak256(abi.encode(g.commitCacheList[i].commitResult)) == keccak256(abi.encode(commitResult))) {
                g.commitCacheList[i].nodeIdAddress.push(msg.sender);
                return true;
            }
        }
    }

    function prepareGroupEvent(GroupData storage groupData, uint256 groupIndex) internal {
        groupData.epoch++;
        IController.Group storage g = groupData.groups[groupIndex];
        g.epoch++;
        g.isStrictlyMajorityConsensusReached = false;

        delete g.committers;
        delete g.commitCacheList;

        for (uint256 i = 0; i < g.members.length; i++) {
            delete g.members[i].partialPublicKey;
        }
    }

    // =============
    // View
    // =============
    // Find group with member address equals to nodeIdAddress, return -1 if not found.
    function getBelongingGroupByMemberAddress(GroupData storage groupData, address nodeIdAddress)
        public
        view
        returns (int256, int256)
    {
        for (uint256 i = 0; i < groupData.groupCount; i++) {
            int256 memberIndex = getMemberIndexByAddress(groupData, i, nodeIdAddress);
            if (memberIndex != -1) {
                return (int256(i), memberIndex);
            }
        }
        return (-1, -1);
    }

    function getMemberIndexByAddress(GroupData storage groupData, uint256 groupIndex, address nodeIdAddress)
        public
        view
        returns (int256)
    {
        IController.Group memory g = groupData.groups[groupIndex];
        for (uint256 i = 0; i < g.members.length; i++) {
            if (g.members[i].nodeIdAddress == nodeIdAddress) {
                return int256(i);
            }
        }
        return -1;
    }

    function getValidGroupIndices(GroupData storage groupData) public view returns (uint256[] memory) {
        uint256[] memory groupIndices = new uint256[](groupData.groupCount); //max length is group count
        uint256 index = 0;
        for (uint256 i = 0; i < groupData.groupCount; i++) {
            IController.Group memory g = groupData.groups[i];
            if (g.isStrictlyMajorityConsensusReached) {
                groupIndices[index] = i;
                index++;
            }
        }

        return Utils.trimTrailingElements(groupIndices, index);
    }

    // =============
    // Internal
    // =============
    // Tries to rebalance the groups, and if it fails, it collects the IDs of the members in the group and tries to add them to other groups.
    // If a member is added to another group, the group is checked to see if its size meets a threshold; if it does, a group event is emitted.
    function arrangeMembersInGroup(GroupData storage groupData, uint256 groupIndex, uint256 lastOutput)
        internal
        returns (uint256[] memory groupIndicesToEmitEvent)
    {
        groupIndicesToEmitEvent = new uint256[](0);
        IController.Group storage g = groupData.groups[groupIndex];
        if (g.size == 0) {
            return groupIndicesToEmitEvent;
        }

        (bool rebalanceSuccess, uint256 groupIndexToRebalance) = tryRebalanceGroup(groupData, groupIndex, lastOutput);
        if (rebalanceSuccess) {
            groupIndicesToEmitEvent = new uint256[](2);
            groupIndicesToEmitEvent[0] = groupIndex;
            groupIndicesToEmitEvent[1] = groupIndexToRebalance;
            return groupIndicesToEmitEvent;
        }

        // Get group and set isStrictlyMajorityConsensusReached to false
        g.isStrictlyMajorityConsensusReached = false;

        // collect idAddress of members in group
        address[] memory membersLeftInGroup = new address[](g.members.length);
        for (uint256 i = 0; i < g.members.length; i++) {
            membersLeftInGroup[i] = g.members[i].nodeIdAddress;
        }
        uint256[] memory involvedGroups = new uint256[](groupData.groupCount); // max number of groups involved is groupCount
        uint256 currentIndex;

        // for each membersLeftInGroup, call findOrCreateTargetGroup and then add that member to the new group.
        for (uint256 i = 0; i < membersLeftInGroup.length; i++) {
            // find a suitable group for the member
            (uint256 targetGroupIndex,) = findOrCreateTargetGroup(groupData);

            // if the current group index is selected, break
            if (groupIndex == targetGroupIndex) {
                break;
            }

            // add member to target group
            addToGroup(groupData, membersLeftInGroup[i], targetGroupIndex);

            if (groupData.groups[i].size >= DEFAULT_MINIMUM_THRESHOLD) {
                involvedGroups[currentIndex] = targetGroupIndex;
                currentIndex++;
            }
        }

        return Utils.trimTrailingElements(involvedGroups, currentIndex);
    }

    function tryRebalanceGroup(GroupData storage groupData, uint256 groupIndex, uint256 lastOutput)
        internal
        returns (bool rebalanceSuccess, uint256 groupIndexToRebalance)
    {
        // get all group indices excluding the current groupIndex
        uint256[] memory groupIndices = new uint256[](groupData.groupCount -1);
        uint256 index = 0;
        for (uint256 i = 0; i < groupData.groupCount; i++) {
            if (i != groupIndex) {
                groupIndices[index] = i;
                index++;
            }
        }

        // try to reblance each group, if succesful, return true
        for (uint256 i = 0; i < groupIndices.length; i++) {
            if (rebalanceGroup(groupData, groupIndices[i], groupIndex, lastOutput)) {
                return (true, groupIndices[i]);
            }
        }
    }

    function rebalanceGroup(GroupData storage groupData, uint256 groupAIndex, uint256 groupBIndex, uint256 lastOutput)
        internal
        returns (bool)
    {
        IController.Group memory groupA = groupData.groups[groupAIndex];
        IController.Group memory groupB = groupData.groups[groupBIndex];

        if (groupB.size > groupA.size) {
            (groupA, groupB) = (groupB, groupA);
            (groupAIndex, groupBIndex) = (groupBIndex, groupAIndex);
        }

        uint256 expectedSizeToMove = groupA.size - (groupA.size + groupB.size) / 2;
        if (expectedSizeToMove == 0 || groupA.size - expectedSizeToMove < DEFAULT_MINIMUM_THRESHOLD) {
            return false;
        }

        // Move members from group A to group B
        for (uint256 i = 0; i < expectedSizeToMove; i++) {
            uint256 memberIndex = Utils.pickRandomIndex(lastOutput, groupA.members.length - i);
            address memberAddress = getMemberAddressByIndex(groupData, groupAIndex, memberIndex);
            removeFromGroup(groupData, memberIndex, groupAIndex);
            addToGroup(groupData, memberAddress, groupBIndex);
        }

        emit GroupRebalanced(groupAIndex, groupBIndex);

        return true;
    }

    function findOrCreateTargetGroup(GroupData storage groupData)
        internal
        returns (uint256 groupIndex, bool needsRebalance)
    {
        // if group is empty, addgroup.
        if (groupData.groupCount == 0) {
            return (addGroup(groupData), false);
        }

        // get the group index of the group with the minimum size, as well as the min size
        uint256 indexOfMinSize;
        uint256 minSize = groupData.groupMaxCapacity;
        for (uint256 i = 0; i < groupData.groupCount; i++) {
            IController.Group memory g = groupData.groups[i];
            if (g.size < minSize) {
                minSize = g.size;
                indexOfMinSize = i;
            }
        }

        // compute the valid group count
        uint256 validGroupCount = getValidGroupIndices(groupData).length;

        // check if valid group count < ideal_number_of_groups || minSize == group_max_capacity
        // If either condition is met and the number of valid groups == group count, call add group and return (index of new group, true)
        if (
            (validGroupCount < groupData.idealNumberOfGroups && validGroupCount == groupData.groupCount)
                || (minSize == groupData.groupMaxCapacity)
        ) return (addGroup(groupData), true);

        // if none of the above conditions are met:
        return (indexOfMinSize, false);
    }

    function addGroup(GroupData storage groupData) internal returns (uint256) {
        uint256 groupIndex = groupData.groupCount; // groupIndex starts at 0. groupCount is index of next group to be added
        groupData.groupCount++;

        IController.Group storage g = groupData.groups[groupIndex];
        g.index = groupIndex;
        g.size = 0;
        g.threshold = DEFAULT_MINIMUM_THRESHOLD;

        return groupIndex;
    }

    function addToGroup(GroupData storage groupData, address idAddress, uint256 groupIndex)
        internal
        returns (bool needEmitGroupEvent)
    {
        // Get group from group index
        IController.Group storage g = groupData.groups[groupIndex];

        // Add Member Struct to group at group index
        IController.Member memory m;
        m.nodeIdAddress = idAddress;

        // insert (node id address - > member) into group.members
        g.members.push(m);
        g.size++;

        // assign group threshold
        uint256 minimum = Utils.minimumThreshold(g.size); // 51% of group size
        // max of 51% of group size and DEFAULT_MINIMUM_THRESHOLD
        g.threshold = minimum > DEFAULT_MINIMUM_THRESHOLD ? minimum : DEFAULT_MINIMUM_THRESHOLD;

        if (g.size >= 3) {
            return true;
        }
    }

    function removeFromGroup(GroupData storage groupData, uint256 memberIndex, uint256 groupIndex)
        public
        returns (bool needRebalance, bool needEmitGroupEvent)
    {
        IController.Group storage g = groupData.groups[groupIndex];
        g.size--;

        if (g.size == 0) {
            delete g.members;
            g.threshold = 0;
            return (false, false);
        }

        // Remove node from members
        g.members[memberIndex] = g.members[g.members.length - 1];
        g.members.pop();

        uint256 minimum = Utils.minimumThreshold(g.size);
        g.threshold = minimum > DEFAULT_MINIMUM_THRESHOLD ? minimum : DEFAULT_MINIMUM_THRESHOLD;

        if (g.size < 3) {
            return (true, false);
        }

        return (false, true);
    }

    // Get array of majority members with identical commit result. Return commit cache. if no majority, return empty commit cache.
    function getStrictlyMajorityIdenticalCommitmentResult(GroupData storage groupData, uint256 groupIndex)
        internal
        view
        returns (IController.CommitCache memory)
    {
        IController.CommitCache memory emptyCache;

        // If there are no commit caches, return empty commit cache.
        IController.Group memory g = groupData.groups[groupIndex];
        if (g.commitCacheList.length == 0) {
            return (emptyCache);
        }

        // If there is only one commit cache, return it.
        if (g.commitCacheList.length == 1) {
            return (g.commitCacheList[0]);
        }

        // If there are multiple commit caches, check if there is a majority.
        bool isStrictlyMajorityExist = true;
        IController.CommitCache memory majorityCommitCache = g.commitCacheList[0];
        for (uint256 i = 1; i < g.commitCacheList.length; i++) {
            IController.CommitCache memory commitCache = g.commitCacheList[i];
            if (commitCache.nodeIdAddress.length > majorityCommitCache.nodeIdAddress.length) {
                isStrictlyMajorityExist = true;
                majorityCommitCache = commitCache;
            } else if (commitCache.nodeIdAddress.length == majorityCommitCache.nodeIdAddress.length) {
                isStrictlyMajorityExist = false;
            }
        }

        // If no majority, return empty commit cache.
        if (!isStrictlyMajorityExist) {
            return (emptyCache);
        }
        // If majority, return majority commit cache
        return (majorityCommitCache);
    }

    function getMemberAddressByIndex(GroupData storage groupData, uint256 groupIndex, uint256 memberIndex)
        internal
        view
        returns (address nodeIdAddress)
    {
        IController.Group memory g = groupData.groups[groupIndex];
        return g.members[memberIndex].nodeIdAddress;
    }
}