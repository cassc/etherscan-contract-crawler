// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IController {
    struct Group {
        uint256 index;
        uint256 epoch;
        uint256 size;
        uint256 threshold;
        Member[] members;
        address[] committers;
        CommitCache[] commitCacheList;
        bool isStrictlyMajorityConsensusReached;
        uint256[4] publicKey;
    }

    struct Member {
        address nodeIdAddress;
        uint256[4] partialPublicKey;
    }

    struct CommitResult {
        uint256 groupEpoch;
        uint256[4] publicKey;
        address[] disqualifiedNodes;
    }

    struct CommitCache {
        address[] nodeIdAddress;
        CommitResult commitResult;
    }

    struct Node {
        address idAddress;
        bytes dkgPublicKey;
        bool state;
        uint256 pendingUntilBlock;
    }

    struct CommitDkgParams {
        uint256 groupIndex;
        uint256 groupEpoch;
        bytes publicKey;
        bytes partialPublicKey;
        address[] disqualifiedNodes;
    }

    // node transaction
    function nodeRegister(bytes calldata dkgPublicKey) external;

    function nodeActivate() external;

    function nodeQuit() external;

    function changeDkgPublicKey(bytes calldata dkgPublicKey) external;

    function commitDkg(CommitDkgParams memory params) external;

    function postProcessDkg(uint256 groupIndex, uint256 groupEpoch) external;

    function nodeWithdraw(address recipient) external;

    // adapter transaction
    function addReward(address[] memory nodes, uint256 ethAmount, uint256 arpaAmount) external;

    function setLastOutput(uint256 lastOutput) external;

    // view
    function getControllerConfig()
        external
        view
        returns (
            address stakingContractAddress,
            address adapterContractAddress,
            uint256 nodeStakingAmount,
            uint256 disqualifiedNodePenaltyAmount,
            uint256 defaultNumberOfCommitters,
            uint256 defaultDkgPhaseDuration,
            uint256 groupMaxCapacity,
            uint256 idealNumberOfGroups,
            uint256 pendingBlockAfterQuit,
            uint256 dkgPostProcessReward
        );

    /// @notice Get list of all group indexes where group.isStrictlyMajorityConsensusReached == true
    /// @return uint256[] List of valid group indexes
    function getValidGroupIndices() external view returns (uint256[] memory);

    function getGroupEpoch() external view returns (uint256);

    function getGroupCount() external view returns (uint256);

    function getGroup(uint256 index) external view returns (Group memory);

    function getGroupThreshold(uint256 groupIndex) external view returns (uint256, uint256);

    function getNode(address nodeAddress) external view returns (Node memory);

    function getMember(uint256 groupIndex, uint256 memberIndex) external view returns (Member memory);

    /// @notice Get the group index and member index of a given node.
    function getBelongingGroup(address nodeAddress) external view returns (int256, int256);

    function getCoordinator(uint256 groupIndex) external view returns (address);

    function getNodeWithdrawableTokens(address nodeAddress) external view returns (uint256, uint256);

    function getLastOutput() external view returns (uint256);

    /// @notice Check to see if a group has a partial public key registered for a given node.
    /// @return bool True if the node has a partial public key registered for the group.
    function isPartialKeyRegistered(uint256 groupIndex, address nodeIdAddress) external view returns (bool);
}