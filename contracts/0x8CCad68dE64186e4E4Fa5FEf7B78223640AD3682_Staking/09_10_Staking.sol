// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "./libraries/Errors.sol";

/*
This contract is used for distributing staking rewards for staking to various nodes.
At each rewards distribution for given node, they are distributed proportionate to "stake powers".

Stake power for a given stake is a value calculated following way:
1. At first distribution (after staking) it is share of stake amount equal to share of time passed between stake 
and this distribution to time passed between previous distribution and this distribution. This is named partial power.
2. At subsequent distributions stake power is equal to staked amount. This is named full power.

Therefore, reward calculations are split into 2 parts: for full stakes and for partial stakes.

Calculations for full stakes is node through increasing node's "rewardPerPower" value 
(that equals to total accrued reward per 1 unit of power, then magnified by MAGNITUDE to calculate small values correct)
Therefore for a stake reward for periods where it was full is it's amount multiplied by difference of
node's current rewardPerPower and value of rewardPerPower at distribution where stake happened (first distribution)

To calculate partial stake reward (happenes only 1 for each stake) other mechanism is used.
At first distribution share of reward for given stake among all rewards for partial stakes in that distribution
is equal to share of product of stake amount and time passed between stake and distribution to sum of such products
for all partial stakes. These products are named "powerXTime" in the codebase;
For correct calculation of sum of powerXTimes we calculate it as difference of maxTotalPowerXTime 
(sum of powerXTimes if all partial stakes were immediately after previous distribution) and sum of powerXTime deltas
(differences between maximal possible powerXTime and real powerXTime for each stake).
Such way allows to calculate all values using O(1) of operations in one transaction
*/

contract Staking is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeCastUpgradeable for uint256;

    /// @notice Magnitude by which values are multiplied in reward calculations
    uint256 private constant MAGNITUDE = 2**128;

    /// @notice Denominator used for decimal calculations
    uint256 public constant DENOMINATOR = 10**18;

    /// @notice One year duration, used for APR calculations
    uint256 public constant YEAR = 365 days;

    /// @notice Token user in staking
    IERC20Upgradeable public token;

    /// @notice Minimal stake required for validator
    uint96 public validatorMinimalStake;

    /// @notice Structure describing one staking node
    struct NodeInfo {
        address validator;
        uint96 totalStaked;
        uint256 rewardPerPower;
        uint256 fee;
        uint256 nextFee;
        uint32 feeUpdateDistributionId;
        uint96 collectedFee;
        uint32 lastDistributionId;
        uint96 stakedByValidator;
    }

    /// @notice Mapping of node ID's to their info
    mapping(uint32 => NodeInfo) public nodeInfo;

    /// @notice Last node ID
    uint32 public lastNodeId;

    /// @notice Structure describing one reward distribution for node
    struct DistributionInfo {
        uint256 rewardPerPower;
        uint96 rewardForPartialPower;
        uint64 timestamp;
        uint96 reward;
        uint160 powerXTimeDelta;
        uint96 stakedIn;
    }

    /// @notice Mapping of node ID's to mappings of distribution ID's to their information
    mapping(uint32 => mapping(uint32 => DistributionInfo)) public distributions;

    /// @notice Structure describing stake information
    struct StakeInfo {
        address owner;
        uint96 amount;
        uint96 withdrawnReward;
        uint32 nodeId;
        uint64 timestamp;
        uint32 firstDistributionId;
    }

    /// @notice Mapping of stake ID's to their information
    mapping(uint256 => StakeInfo) public stakeInfo;

    /// @notice Last stake ID
    uint256 public lastStakeId;

    // EVENTS

    /// @notice Event emitted when new staking node is created
    event NodeCreated(uint32 indexed nodeId, address indexed validator);

    /// @notice Event emitted when new stake is created
    event Staked(
        uint256 indexed stakeId,
        address indexed staker,
        uint32 indexed nodeId,
        uint256 amount
    );

    /// @notice Event emitted when reward is wihdrawn for some stake
    event RewardWithdrawn(uint256 indexed stakeId, uint256 reward);

    /// @notice Event emitted when some stake is withdrawn
    event Unstaked(
        uint256 indexed stakeId,
        address indexed staker,
        uint32 indexed nodeId,
        uint256 amount
    );

    /// @notice Event emitted when reward is distributed for some node
    event RewardDistributed(uint32 indexed nodeId, uint256 reward, uint256 fee);

    /// @notice Event emitted when fee is collected for some node
    event FeeCollected(uint32 indexed nodeId, address collector, uint256 fee);

    /// @notice Event emitted when fee is updated for some node
    event FeeUpdated(uint32 indexed nodeId, uint256 fee);

    /// @notice Event emitted when value of validator minimal stake is updated
    event ValidatorMinimalStakeUpdated(uint96 validatorMinimalStake_);

    /// @notice Event emitted when new validator is set for some node
    event NodeValidatorSet(uint32 indexed nodeId, address indexed validator);

    // INITIALIZER

    /// @notice Contract's initializer
    /// @param token_ Contract of token used in staking
    /// @param validatorMinimalStake_ Minimal size of stake required for validator
    function initialize(IERC20Upgradeable token_, uint96 validatorMinimalStake_)
        external
        initializer
    {
        __Ownable_init();

        token = token_;
        validatorMinimalStake = validatorMinimalStake_;
    }

    // RESTRICTED FUNCTIONS

    /// @notice Owner's function that is used to create new node
    /// @param validator Address of the node's validator
    /// @param fee NUmberator of the fee value
    /// @return nodeId ID of new node
    function createNode(address validator, uint256 fee)
        external
        onlyOwner
        returns (uint32 nodeId)
    {
        require(validator != address(0), Errors.ZERO_VALIDATOR);

        nodeId = ++lastNodeId;
        nodeInfo[nodeId].validator = validator;
        nodeInfo[nodeId].fee = fee;
        distributions[nodeId][0].timestamp = block.timestamp.toUint64();

        emit NodeCreated(nodeId, validator);
    }

    /// @notice Owner's function that is used to distribute rewards to a set of nodes
    /// @param nodeIds List of node ID's
    /// @param rewards List of respective rewards to those nodes
    /// @dev Function transfers distributed reward to contract, approval is required in prior
    function distributeReward(
        uint32[] calldata nodeIds,
        uint256[] calldata rewards
    ) external onlyOwner {
        require(nodeIds.length == rewards.length, Errors.LENGHTS_MISMATCH);

        uint256 totalReward;
        for (uint256 i = 0; i < rewards.length; i++) {
            totalReward += rewards[i];

            uint256 feeAmount = (rewards[i] * getFee(nodeIds[i])) / DENOMINATOR;
            nodeInfo[nodeIds[i]].collectedFee += feeAmount.toUint96();

            _distributeReward(nodeIds[i], rewards[i] - feeAmount);

            emit RewardDistributed(
                nodeIds[i],
                rewards[i] - feeAmount,
                feeAmount
            );
        }

        token.safeTransferFrom(msg.sender, address(this), totalReward);
    }

    /// @notice Updates fee for some node (effective only after next distribution)
    /// @param nodeId ID of the node to update fee for
    /// @param fee New fee value
    function setFee(uint32 nodeId, uint256 fee) external {
        require(
            msg.sender == owner() || msg.sender == nodeInfo[nodeId].validator,
            Errors.NOT_OWNER_OR_VALIDATOR
        );
        require(fee < DENOMINATOR, Errors.FEE_OVERFLOW);

        uint32 lastDistributionId = nodeInfo[nodeId].lastDistributionId;
        uint32 updateDistributionId = nodeInfo[nodeId].feeUpdateDistributionId;
        if (
            updateDistributionId != 0 &&
            updateDistributionId <= lastDistributionId
        ) {
            nodeInfo[nodeId].fee = nodeInfo[nodeId].nextFee;
        }

        nodeInfo[nodeId].nextFee = fee;
        nodeInfo[nodeId].feeUpdateDistributionId = lastDistributionId + 1;

        emit FeeUpdated(nodeId, fee);
    }

    /// @notice Updates value of validator minimal stake
    /// @param validatorMinimalStake_ New value
    function setValidatorMinimalStake(uint96 validatorMinimalStake_)
        external
        onlyOwner
    {
        validatorMinimalStake = validatorMinimalStake_;

        emit ValidatorMinimalStakeUpdated(validatorMinimalStake_);
    }

    /// @notice Updates validar for some node
    /// @param nodeId ID of the node to update validator for
    /// @param validator New validator address (SHOULD NOT HAVE ANY STAKES BEFORE!)
    function setNodeValidator(uint32 nodeId, address validator)
        external
        onlyOwner
    {
        nodeInfo[nodeId].validator = validator;
        nodeInfo[nodeId].stakedByValidator = 0;

        emit NodeValidatorSet(nodeId, validator);
    }

    // PUBLIC FUNCTIONS

    /// @notice Creates new stake
    /// @param nodeId ID of the node to stake for
    /// @param amount Amount to stake
    /// @dev Transfers `amount` of `token` to the contract, approval is required in prior
    /// @return stakeId ID of the created stake
    function stakeFor(uint32 nodeId, uint96 amount)
        external
        returns (uint256 stakeId)
    {
        address validator = nodeInfo[nodeId].validator;
        require(validator != address(0), Errors.INVALID_NODE);

        if (msg.sender != validator) {
            require(
                nodeInfo[nodeId].stakedByValidator >= validatorMinimalStake,
                Errors.NODE_NOT_ACTIVE
            );
        } else {
            nodeInfo[nodeId].stakedByValidator += amount;
        }

        // This stake's first distribution will be next distribution
        uint32 distributionId = nodeInfo[nodeId].lastDistributionId + 1;

        stakeId = ++lastStakeId;
        stakeInfo[stakeId] = StakeInfo({
            owner: msg.sender,
            nodeId: nodeId,
            amount: amount,
            timestamp: block.timestamp.toUint64(),
            firstDistributionId: distributionId,
            withdrawnReward: 0
        });

        nodeInfo[nodeId].totalStaked += amount;

        // Amount staked in current distribution is stored to calculate total reward for partial power in future
        distributions[nodeId][distributionId].stakedIn += amount;

        // Sum of powerXTimeDeltas is increased
        uint256 timeDelta = block.timestamp -
            distributions[nodeId][distributionId - 1].timestamp;
        distributions[nodeId][distributionId].powerXTimeDelta += (timeDelta *
            amount).toUint160();

        token.safeTransferFrom(msg.sender, address(this), amount);

        emit Staked(stakeId, msg.sender, nodeId, amount);
    }

    /// @notice Withdraws accumulated reward for given stake
    /// @param stakeId ID of the stake to collect reward for
    function withdrawReward(uint256 stakeId) public {
        _withdrawReward(stakeId);
    }

    /// @notice Withdraws accumulated reward for list of given stakes
    /// @param stakeIds List of IDs of the stakes to collect reward for
    function batchWithdrawReward(uint256[] calldata stakeIds) public {
        for (uint256 i = 0; i < stakeIds.length; i++) {
            _withdrawReward(stakeIds[i]);
        }
    }

    /// @notice Unstakes given stake (and collects reward in process)
    /// @param stakeId ID of the stake to withdraw
    function unstake(uint256 stakeId) external {
        _unstake(stakeId);
    }

    /// @notice Unstakes list of given stakes (and collects reward in process)
    /// @param stakeIds List of IDs of the stakes to withdraw
    function batchUnstake(uint256[] calldata stakeIds) external {
        for (uint256 i = 0; i < stakeIds.length; i++) {
            _unstake(stakeIds[i]);
        }
    }

    /// @notice Collects fee for a given node (can only be called by validator)
    /// @param nodeId ID of the node to collect fee for
    function withdrawFee(uint32 nodeId) external {
        require(
            msg.sender == nodeInfo[nodeId].validator,
            Errors.NOT_NODE_VALIDATOR
        );

        uint256 fee = nodeInfo[nodeId].collectedFee;
        if (fee > 0) {
            nodeInfo[nodeId].collectedFee = 0;

            token.safeTransfer(msg.sender, fee);

            emit FeeCollected(nodeId, msg.sender, fee);
        }
    }

    // PUBLIC VIEW FUNCTIONS

    /// @notice Returns current reward of given stake
    /// @param stakeId ID of the stake to get reward for
    /// @return Current reward
    function rewardOf(uint256 stakeId) public view returns (uint96) {
        return
            _accumulatedRewardOf(stakeId) - stakeInfo[stakeId].withdrawnReward;
    }

    /// @notice Gets current fee for a node
    /// @param nodeId ID of the node
    /// @return Current fee
    function getFee(uint32 nodeId) public view returns (uint256) {
        uint32 updateDistributionId = nodeInfo[nodeId].feeUpdateDistributionId;
        if (
            updateDistributionId != 0 &&
            updateDistributionId <= nodeInfo[nodeId].lastDistributionId
        ) {
            return nodeInfo[nodeId].nextFee;
        } else {
            return nodeInfo[nodeId].fee;
        }
    }

    /// @notice Returns if node is active (validator has made minimal stake)
    /// @param nodeId ID of the node
    /// @return True if node is active, false otherwise
    function isActive(uint32 nodeId) external view returns (bool) {
        return nodeInfo[nodeId].stakedByValidator >= validatorMinimalStake;
    }

    // PRIVATE FUNCTIONS

    /// @notice Internal function that processes reward distribution for one node
    /// @param nodeId ID of the node
    /// @param reward Distributed reward
    function _distributeReward(uint32 nodeId, uint256 reward) private {
        require(nodeInfo[nodeId].validator != address(0), Errors.INVALID_NODE);
        require(
            nodeInfo[nodeId].stakedByValidator >= validatorMinimalStake,
            Errors.NODE_NOT_ACTIVE
        );

        uint32 distributionId = ++nodeInfo[nodeId].lastDistributionId;
        DistributionInfo storage distribution = distributions[nodeId][
            distributionId
        ];
        uint256 stakedIn = distribution.stakedIn;

        // Total full power is simply sum of all stakes before this distribution
        uint256 fullPower = nodeInfo[nodeId].totalStaked - stakedIn;

        uint256 partialPower;
        if (stakedIn > 0) {
            // Maximal possible (not actual) sum of powerXTimes in this distribution
            uint256 maxTotalPowerXTime = stakedIn *
                (block.timestamp -
                    distributions[nodeId][distributionId - 1].timestamp);

            // Total partial power is share of staked amount equal to share of real totalPowerXTime to maximal
            partialPower =
                (stakedIn *
                    (maxTotalPowerXTime - distribution.powerXTimeDelta)) /
                maxTotalPowerXTime;
        }

        // Reward for full powers is calculated proporionate to total full and partial powers
        uint256 rewardForFullPower = (reward * fullPower) /
            (fullPower + partialPower);

        // If full powers actually exist in this distribution we calculate (magnified) rewardPerPower delta
        uint256 rewardPerPowerDelta;
        if (fullPower > 0) {
            rewardPerPowerDelta = (MAGNITUDE * rewardForFullPower) / fullPower;
        }

        nodeInfo[nodeId].rewardPerPower += rewardPerPowerDelta;
        distribution.timestamp = block.timestamp.toUint64();
        distribution.reward = reward.toUint96();
        distribution.rewardPerPower = nodeInfo[nodeId].rewardPerPower;
        // We store only total reward for partial powers
        distribution.rewardForPartialPower = (reward - rewardForFullPower)
            .toUint96();
    }

    /// @notice Internal function that collects reward for given stake
    /// @param stakeId ID of the stake
    function _withdrawReward(uint256 stakeId) private {
        require(stakeInfo[stakeId].owner == msg.sender, Errors.NOT_STAKE_OWNER);

        uint96 reward = rewardOf(stakeId);
        stakeInfo[stakeId].withdrawnReward += reward;
        token.safeTransfer(msg.sender, reward);

        emit RewardWithdrawn(stakeId, reward);
    }

    /// @notice Internal function that unstakes given stake
    /// @param stakeId ID of the stake
    function _unstake(uint256 stakeId) private {
        _withdrawReward(stakeId);

        uint32 nodeId = stakeInfo[stakeId].nodeId;
        uint32 distributionId = nodeInfo[nodeId].lastDistributionId + 1;
        uint96 amount = stakeInfo[stakeId].amount;

        nodeInfo[nodeId].totalStaked -= amount;
        if (msg.sender == nodeInfo[nodeId].validator) {
            nodeInfo[nodeId].stakedByValidator -= amount;
        }
        if (stakeInfo[stakeId].firstDistributionId == distributionId) {
            distributions[nodeId][distributionId].stakedIn -= amount;

            uint160 timeDelta = stakeInfo[stakeId].timestamp -
                distributions[nodeId][distributionId - 1].timestamp;
            distributions[nodeId][distributionId].powerXTimeDelta -=
                timeDelta *
                amount;
        }

        token.safeTransfer(msg.sender, amount);
        delete stakeInfo[stakeId];

        emit Unstaked(stakeId, msg.sender, nodeId, amount);
    }

    // PRIVATE VIEW FUNCTION

    /// @notice Internal function that calculates total accumulated reward for stake (without withdrawals)
    /// @param stakeId ID of the stake
    /// @return Total reward
    function _accumulatedRewardOf(uint256 stakeId)
        private
        view
        returns (uint96)
    {
        StakeInfo memory stake = stakeInfo[stakeId];
        DistributionInfo memory firstDistribution = distributions[stake.nodeId][
            stake.firstDistributionId
        ];
        if (firstDistribution.timestamp == 0) {
            return 0;
        }

        // Reward for periods when stake was full, calculated straightforward
        uint256 fullReward = (stake.amount *
            (nodeInfo[stake.nodeId].rewardPerPower -
                firstDistribution.rewardPerPower)) / MAGNITUDE;

        // Timestamp of previous distribution
        uint256 previousTimestamp = distributions[stake.nodeId][
            stake.firstDistributionId - 1
        ].timestamp;

        //  Maximal possible (not actual) sum of powerXTimes in first distribution for stake
        uint256 maxTotalPowerXTime = uint256(firstDistribution.stakedIn) *
            (firstDistribution.timestamp - previousTimestamp);

        // Real sum of powerXTimes in first distribution for stake
        uint256 realTotalPowerXTime = maxTotalPowerXTime -
            firstDistribution.powerXTimeDelta;

        // PowerXTime of this stake in first distribution
        uint256 stakePowerXTime = uint256(stake.amount) *
            (firstDistribution.timestamp - stake.timestamp);

        // Reward when stake was partial as propotionate share of total reward for partial stakes in distribution
        uint256 partialReward;
        if (realTotalPowerXTime > 0) {
            partialReward =
                (uint256(firstDistribution.rewardForPartialPower) *
                    stakePowerXTime) /
                realTotalPowerXTime;
        }

        return (fullReward + partialReward).toUint96();
    }
}