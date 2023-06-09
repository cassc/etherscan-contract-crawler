// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IERC20, SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {IController} from "./interfaces/IController.sol";
import {IControllerOwner} from "./interfaces/IControllerOwner.sol";
import {IAdapter} from "./interfaces/IAdapter.sol";
import {ICoordinator} from "./interfaces/ICoordinator.sol";
import {INodeStaking} from "Staking-v0.1/interfaces/INodeStaking.sol";
import {BLS} from "./libraries/BLS.sol";
import {GroupLib} from "./libraries/GroupLib.sol";
import {Coordinator} from "./Coordinator.sol";

contract Controller is Initializable, IController, IControllerOwner, OwnableUpgradeable {
    using SafeERC20 for IERC20;
    using GroupLib for GroupLib.GroupData;

    // *Constants*
    uint16 private constant _BALANCE_BASE = 1;

    // *Controller Config*
    ControllerConfig private _config;
    IERC20 private _arpa;

    // *Node State Variables*
    mapping(address => Node) private _nodes; // maps node address to Node Struct
    mapping(address => uint256) private _withdrawableEths; // maps node address to withdrawable eth amount
    mapping(address => uint256) private _arpaRewards; // maps node address to arpa rewards

    // *DKG Variables*
    mapping(uint256 => address) private _coordinators; // maps group index to coordinator address

    // *Group Variables*
    GroupLib.GroupData internal _groupData;

    // *Task Variables*
    uint256 private _lastOutput;

    // *Structs*
    struct ControllerConfig {
        address stakingContractAddress;
        address adapterContractAddress;
        uint256 nodeStakingAmount;
        uint256 disqualifiedNodePenaltyAmount;
        uint256 defaultDkgPhaseDuration;
        uint256 pendingBlockAfterQuit;
        uint256 dkgPostProcessReward;
    }

    // *Events*
    event NodeRegistered(address indexed nodeAddress, bytes dkgPublicKey, uint256 groupIndex);
    event NodeActivated(address indexed nodeAddress, uint256 groupIndex);
    event NodeQuit(address indexed nodeAddress);
    event DkgPublicKeyChanged(address indexed nodeAddress, bytes dkgPublicKey);
    event NodeSlashed(address indexed nodeIdAddress, uint256 stakingRewardPenalty, uint256 pendingBlock);
    event NodeRewarded(address indexed nodeAddress, uint256 ethAmount, uint256 arpaAmount);
    event ControllerConfigSet(
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
    event DkgTask(
        uint256 indexed globalEpoch,
        uint256 indexed groupIndex,
        uint256 indexed groupEpoch,
        uint256 size,
        uint256 threshold,
        address[] members,
        uint256 assignmentBlockHeight,
        address coordinatorAddress
    );

    // *Errors*
    error NodeNotRegistered();
    error NodeAlreadyRegistered();
    error NodeAlreadyActive();
    error NodeStillPending(uint256 pendingUntilBlock);
    error GroupNotExist(uint256 groupIndex);
    error CoordinatorNotFound(uint256 groupIndex);
    error DkgNotInProgress(uint256 groupIndex);
    error DkgStillInProgress(uint256 groupIndex, int8 phase);
    error EpochMismatch(uint256 groupIndex, uint256 inputGroupEpoch, uint256 currentGroupEpoch);
    error NodeNotInGroup(uint256 groupIndex, address nodeIdAddress);
    error PartialKeyAlreadyRegistered(uint256 groupIndex, address nodeIdAddress);
    error SenderNotAdapter();
    error InvalidZeroAddress();

    function initialize(address arpa, uint256 lastOutput) public initializer {
        _arpa = IERC20(arpa);
        _lastOutput = lastOutput;

        __Ownable_init();
    }

    // =============
    // IControllerOwner
    // =============
    function setControllerConfig(
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
    ) external override(IControllerOwner) onlyOwner {
        _config = ControllerConfig({
            stakingContractAddress: stakingContractAddress,
            adapterContractAddress: adapterContractAddress,
            nodeStakingAmount: nodeStakingAmount,
            disqualifiedNodePenaltyAmount: disqualifiedNodePenaltyAmount,
            defaultDkgPhaseDuration: defaultDkgPhaseDuration,
            pendingBlockAfterQuit: pendingBlockAfterQuit,
            dkgPostProcessReward: dkgPostProcessReward
        });

        _groupData.setConfig(idealNumberOfGroups, groupMaxCapacity, defaultNumberOfCommitters);

        emit ControllerConfigSet(
            stakingContractAddress,
            adapterContractAddress,
            nodeStakingAmount,
            disqualifiedNodePenaltyAmount,
            defaultNumberOfCommitters,
            defaultDkgPhaseDuration,
            groupMaxCapacity,
            idealNumberOfGroups,
            pendingBlockAfterQuit,
            dkgPostProcessReward
        );
    }

    // =============
    // IController
    // =============
    function nodeRegister(bytes calldata dkgPublicKey) external override(IController) {
        if (_nodes[msg.sender].idAddress != address(0)) {
            revert NodeAlreadyRegistered();
        }

        uint256[4] memory publicKey = BLS.fromBytesPublicKey(dkgPublicKey);
        if (!BLS.isValidPublicKey(publicKey)) {
            revert BLS.InvalidPublicKey();
        }
        // Lock staking amount in Staking contract
        INodeStaking(_config.stakingContractAddress).lock(msg.sender, _config.nodeStakingAmount);

        // Populate Node struct and insert into nodes
        Node storage n = _nodes[msg.sender];
        n.idAddress = msg.sender;
        n.dkgPublicKey = dkgPublicKey;
        n.state = true;

        // Initialize withdrawable eths and arpa rewards to save gas for adapter call
        _withdrawableEths[msg.sender] = _BALANCE_BASE;
        _arpaRewards[msg.sender] = _BALANCE_BASE;

        (uint256 groupIndex, uint256[] memory groupIndicesToEmitEvent) = _groupData.nodeJoin(msg.sender, _lastOutput);

        for (uint256 i = 0; i < groupIndicesToEmitEvent.length; i++) {
            _emitGroupEvent(groupIndicesToEmitEvent[i]);
        }

        emit NodeRegistered(msg.sender, dkgPublicKey, groupIndex);
    }

    function nodeActivate() external override(IController) {
        Node storage node = _nodes[msg.sender];
        if (node.idAddress != msg.sender) {
            revert NodeNotRegistered();
        }

        if (node.state) {
            revert NodeAlreadyActive();
        }

        if (node.pendingUntilBlock > block.number) {
            revert NodeStillPending(node.pendingUntilBlock);
        }

        // lock up to staking amount in Staking contract
        uint256 lockedAmount = INodeStaking(_config.stakingContractAddress).getLockedAmount(msg.sender);
        if (lockedAmount < _config.nodeStakingAmount) {
            INodeStaking(_config.stakingContractAddress).lock(msg.sender, _config.nodeStakingAmount - lockedAmount);
        }

        node.state = true;

        (uint256 groupIndex, uint256[] memory groupIndicesToEmitEvent) = _groupData.nodeJoin(msg.sender, _lastOutput);

        for (uint256 i = 0; i < groupIndicesToEmitEvent.length; i++) {
            _emitGroupEvent(groupIndicesToEmitEvent[i]);
        }

        emit NodeActivated(msg.sender, groupIndex);
    }

    function nodeQuit() external override(IController) {
        Node storage node = _nodes[msg.sender];

        if (node.idAddress != msg.sender) {
            revert NodeNotRegistered();
        }
        uint256[] memory groupIndicesToEmitEvent = _groupData.nodeLeave(msg.sender, _lastOutput);

        for (uint256 i = 0; i < groupIndicesToEmitEvent.length; i++) {
            _emitGroupEvent(groupIndicesToEmitEvent[i]);
        }

        _freezeNode(msg.sender, _config.pendingBlockAfterQuit);

        // unlock staking amount in Staking contract
        INodeStaking(_config.stakingContractAddress).unlock(msg.sender, _config.nodeStakingAmount);

        emit NodeQuit(msg.sender);
    }

    function changeDkgPublicKey(bytes calldata dkgPublicKey) external override(IController) {
        Node storage node = _nodes[msg.sender];
        if (node.idAddress != msg.sender) {
            revert NodeNotRegistered();
        }

        if (node.state) {
            revert NodeAlreadyActive();
        }

        uint256[4] memory publicKey = BLS.fromBytesPublicKey(dkgPublicKey);
        if (!BLS.isValidPublicKey(publicKey)) {
            revert BLS.InvalidPublicKey();
        }

        node.dkgPublicKey = dkgPublicKey;

        emit DkgPublicKeyChanged(msg.sender, dkgPublicKey);
    }

    function commitDkg(CommitDkgParams memory params) external override(IController) {
        if (params.groupIndex >= _groupData.groupCount) revert GroupNotExist(params.groupIndex);

        // require coordinator exists
        if (_coordinators[params.groupIndex] == address(0)) {
            revert CoordinatorNotFound(params.groupIndex);
        }

        // Ensure DKG Proccess is in Phase
        ICoordinator coordinator = ICoordinator(_coordinators[params.groupIndex]);
        if (coordinator.inPhase() == -1) {
            revert DkgNotInProgress(params.groupIndex);
        }

        // Ensure epoch is correct, node is in group, and has not already submitted a partial key
        Group storage g = _groupData.groups[params.groupIndex];
        if (params.groupEpoch != g.epoch) {
            revert EpochMismatch(params.groupIndex, params.groupEpoch, g.epoch);
        }

        if (_groupData.getMemberIndexByAddress(params.groupIndex, msg.sender) == -1) {
            revert NodeNotInGroup(params.groupIndex, msg.sender);
        }

        // check to see if member has called commitdkg in the past.
        if (isPartialKeyRegistered(params.groupIndex, msg.sender)) {
            revert PartialKeyAlreadyRegistered(params.groupIndex, msg.sender);
        }

        // require publickey and partial public key are not empty  / are the right format
        uint256[4] memory partialPublicKey = BLS.fromBytesPublicKey(params.partialPublicKey);
        if (!BLS.isValidPublicKey(partialPublicKey)) {
            revert BLS.InvalidPartialPublicKey();
        }

        uint256[4] memory publicKey = BLS.fromBytesPublicKey(params.publicKey);
        if (!BLS.isValidPublicKey(publicKey)) {
            revert BLS.InvalidPublicKey();
        }

        // Populate CommitResult / CommitCache
        CommitResult memory commitResult = CommitResult({
            groupEpoch: params.groupEpoch,
            publicKey: publicKey,
            disqualifiedNodes: params.disqualifiedNodes
        });

        if (!_groupData.tryAddToExistingCommitCache(params.groupIndex, commitResult)) {
            CommitCache memory commitCache = CommitCache({commitResult: commitResult, nodeIdAddress: new address[](1)});

            commitCache.nodeIdAddress[0] = msg.sender;
            g.commitCacheList.push(commitCache);
        }

        // no matter consensus previously reached, update the partial public key of the given node's member entry in the group
        g.members[uint256(_groupData.getMemberIndexByAddress(params.groupIndex, msg.sender))].partialPublicKey =
            partialPublicKey;

        // if not.. call get StrictlyMajorityIdenticalCommitmentResult for the group and check if consensus has been reached.
        if (!g.isStrictlyMajorityConsensusReached) {
            (bool success, address[] memory disqualifiedNodes) =
                _groupData.tryEnableGroup(params.groupIndex, _lastOutput);

            if (success) {
                // Iterate over disqualified nodes and call slashNode on each.
                for (uint256 i = 0; i < disqualifiedNodes.length; i++) {
                    _slashNode(disqualifiedNodes[i], _config.disqualifiedNodePenaltyAmount, 0);
                }
            }
        }
    }

    function postProcessDkg(uint256 groupIndex, uint256 groupEpoch) external override(IController) {
        if (groupIndex >= _groupData.groupCount) revert GroupNotExist(groupIndex);

        // require calling node is in group
        if (_groupData.getMemberIndexByAddress(groupIndex, msg.sender) == -1) {
            revert NodeNotInGroup(groupIndex, msg.sender);
        }

        // require correct epoch
        Group storage g = _groupData.groups[groupIndex];
        if (groupEpoch != g.epoch) {
            revert EpochMismatch(groupIndex, groupEpoch, g.epoch);
        }

        // require coordinator exists
        if (_coordinators[groupIndex] == address(0)) {
            revert CoordinatorNotFound(groupIndex);
        }

        // Ensure DKG Proccess is out of phase
        ICoordinator coordinator = ICoordinator(_coordinators[groupIndex]);
        if (coordinator.inPhase() != -1) {
            revert DkgStillInProgress(groupIndex, coordinator.inPhase());
        }

        // delete coordinator
        coordinator.selfDestruct(); // coordinator self destructs
        _coordinators[groupIndex] = address(0); // remove coordinator from mapping

        if (!g.isStrictlyMajorityConsensusReached) {
            (address[] memory nodesToBeSlashed, uint256[] memory groupIndicesToEmitEvent) =
                _groupData.handleUnsuccessfulGroupDkg(groupIndex, _lastOutput);

            for (uint256 i = 0; i < nodesToBeSlashed.length; i++) {
                _slashNode(nodesToBeSlashed[i], _config.disqualifiedNodePenaltyAmount, 0);
            }
            for (uint256 i = 0; i < groupIndicesToEmitEvent.length; i++) {
                _emitGroupEvent(groupIndicesToEmitEvent[i]);
            }
        }

        // update rewards for calling node
        _arpaRewards[msg.sender] += _config.dkgPostProcessReward;

        emit NodeRewarded(msg.sender, 0, _config.dkgPostProcessReward);
    }

    function nodeWithdraw(address recipient) external override(IController) {
        if (recipient == address(0)) {
            revert InvalidZeroAddress();
        }
        uint256 ethAmount = _withdrawableEths[msg.sender];
        uint256 arpaAmount = _arpaRewards[msg.sender];
        if (arpaAmount > _BALANCE_BASE) {
            _arpaRewards[msg.sender] = _BALANCE_BASE;
            _arpa.safeTransfer(recipient, arpaAmount - _BALANCE_BASE);
        }
        if (ethAmount > _BALANCE_BASE) {
            _withdrawableEths[msg.sender] = _BALANCE_BASE;
            IAdapter(_config.adapterContractAddress).nodeWithdrawETH(recipient, ethAmount - _BALANCE_BASE);
        }
    }

    function addReward(address[] memory nodes, uint256 ethAmount, uint256 arpaAmount) public override(IController) {
        if (msg.sender != _config.adapterContractAddress) {
            revert SenderNotAdapter();
        }
        for (uint256 i = 0; i < nodes.length; i++) {
            _withdrawableEths[nodes[i]] += ethAmount;
            _arpaRewards[nodes[i]] += arpaAmount;
            emit NodeRewarded(nodes[i], ethAmount, arpaAmount);
        }
    }

    function setLastOutput(uint256 lastOutput) external override(IController) {
        if (msg.sender != _config.adapterContractAddress) {
            revert SenderNotAdapter();
        }
        _lastOutput = lastOutput;
    }

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
        )
    {
        return (
            _config.stakingContractAddress,
            _config.adapterContractAddress,
            _config.nodeStakingAmount,
            _config.disqualifiedNodePenaltyAmount,
            _groupData.defaultNumberOfCommitters,
            _config.defaultDkgPhaseDuration,
            _groupData.groupMaxCapacity,
            _groupData.idealNumberOfGroups,
            _config.pendingBlockAfterQuit,
            _config.dkgPostProcessReward
        );
    }

    function getValidGroupIndices() public view override(IController) returns (uint256[] memory) {
        return _groupData.getValidGroupIndices();
    }

    function getGroupEpoch() external view returns (uint256) {
        return _groupData.epoch;
    }

    function getGroupCount() external view override(IController) returns (uint256) {
        return _groupData.groupCount;
    }

    function getGroup(uint256 groupIndex) public view override(IController) returns (Group memory) {
        return _groupData.groups[groupIndex];
    }

    function getGroupThreshold(uint256 groupIndex) public view override(IController) returns (uint256, uint256) {
        return (_groupData.groups[groupIndex].threshold, _groupData.groups[groupIndex].size);
    }

    function getNode(address nodeAddress) public view override(IController) returns (Node memory) {
        return _nodes[nodeAddress];
    }

    function getMember(uint256 groupIndex, uint256 memberIndex)
        public
        view
        override(IController)
        returns (Member memory)
    {
        return _groupData.groups[groupIndex].members[memberIndex];
    }

    function getBelongingGroup(address nodeAddress) external view override(IController) returns (int256, int256) {
        return _groupData.getBelongingGroupByMemberAddress(nodeAddress);
    }

    function getCoordinator(uint256 groupIndex) public view override(IController) returns (address) {
        return _coordinators[groupIndex];
    }

    function getNodeWithdrawableTokens(address nodeAddress)
        public
        view
        override(IController)
        returns (uint256, uint256)
    {
        return (
            _withdrawableEths[nodeAddress] == 0 ? 0 : (_withdrawableEths[nodeAddress] - _BALANCE_BASE),
            _arpaRewards[nodeAddress] == 0 ? 0 : (_arpaRewards[nodeAddress] - _BALANCE_BASE)
        );
    }

    function getLastOutput() external view returns (uint256) {
        return _lastOutput;
    }

    /// Check to see if a group has a partial public key registered for a given node.
    function isPartialKeyRegistered(uint256 groupIndex, address nodeIdAddress)
        public
        view
        override(IController)
        returns (bool)
    {
        Group memory g = _groupData.groups[groupIndex];
        for (uint256 i = 0; i < g.members.length; i++) {
            if (g.members[i].nodeIdAddress == nodeIdAddress) {
                return g.members[i].partialPublicKey[0] != 0;
            }
        }
        return false;
    }

    // =============
    // Internal
    // =============

    function _emitGroupEvent(uint256 groupIndex) internal {
        _groupData.prepareGroupEvent(groupIndex);

        Group memory g = _groupData.groups[groupIndex];

        // Deploy coordinator, add to coordinators mapping
        Coordinator coordinator;
        coordinator = new Coordinator(g.threshold, _config.defaultDkgPhaseDuration);
        _coordinators[groupIndex] = address(coordinator);

        // Initialize Coordinator
        address[] memory groupNodes = new address[](g.size);
        bytes[] memory groupKeys = new bytes[](g.size);

        for (uint256 i = 0; i < g.size; i++) {
            groupNodes[i] = g.members[i].nodeIdAddress;
            groupKeys[i] = _nodes[g.members[i].nodeIdAddress].dkgPublicKey;
        }

        coordinator.initialize(groupNodes, groupKeys);

        emit DkgTask(
            _groupData.epoch, g.index, g.epoch, g.size, g.threshold, groupNodes, block.number, address(coordinator)
        );
    }

    // Give node staking reward penalty and freezeNode
    function _slashNode(address nodeIdAddress, uint256 stakingRewardPenalty, uint256 pendingBlock) internal {
        // slash staking reward in Staking contract
        INodeStaking(_config.stakingContractAddress).slashDelegationReward(nodeIdAddress, stakingRewardPenalty);

        // remove node from group if handleGroup is true and deactivate it
        _freezeNode(nodeIdAddress, pendingBlock);

        emit NodeSlashed(nodeIdAddress, stakingRewardPenalty, pendingBlock);
    }

    function _freezeNode(address nodeIdAddress, uint256 pendingBlock) internal {
        // set node state to false for frozen node
        _nodes[nodeIdAddress].state = false;

        uint256 currentBlock = block.number;
        // if the node is already pending, add the pending block to the current pending block
        if (_nodes[nodeIdAddress].pendingUntilBlock > currentBlock) {
            _nodes[nodeIdAddress].pendingUntilBlock += pendingBlock;
            // else set the pending block to the current block + pending block
        } else {
            _nodes[nodeIdAddress].pendingUntilBlock = currentBlock + pendingBlock;
        }
    }
}