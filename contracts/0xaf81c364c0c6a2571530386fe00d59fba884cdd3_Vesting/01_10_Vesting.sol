//SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

/**
 * @title Vesting
 * @author gotbit
 */

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './utils/Merkle.sol';

error InvalidLength();
error InvalidValue();
error NotStarted();
error WrongProof();
error ZeroClaim();

contract Vesting is Ownable, Initializable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Merkle for bytes32[];

    /// @dev Describes a single period of a vesting round
    /// (Vesting includes multiple parallel rounds, each of them consists of several periods)
    /// @param startTimestamp Timestamp of a period beginning
    /// @param duration Duration of a period
    /// @param linearUnits Number of unlocks in the current period
    /// Example: period duration is 1000 sec, linearUnits is 5, tokenAmount is 100 => 20 tokens will be unlocked every 200 sec
    /// @param percentageD Percentage ratio multiplied by DENOMINATOR = 10 ** 18 (token amount of period / token amount of round)
    struct VestingPeriod {
        uint64 startTimestamp;
        uint32 duration;
        uint32 linearUnits;
        uint128 percentageD;
    }

    struct VestingRound {
        string name;
        VestingPeriod[] periods;
    }

    uint256 constant DENOMINATOR = 10**18; // 18 decimals accuracy

    mapping(uint256 => VestingRound) public rounds;
    uint256 public roundLength;

    IERC20 public immutable token;
    bytes32 public ROOT;
    string private leaves;
    uint256 public startTimestamp;

    mapping(address => mapping(uint256 => uint256)) _claimed;

    modifier isStarted() {
        if (block.timestamp < startTimestamp) revert NotStarted();
        _;
    }

    event InitializedVesting(uint256 indexed timestamp, address indexed user);
    event Claim(
        uint256 indexed timestamp,
        address indexed user,
        string roundName,
        uint256 amount
    );

    constructor(IERC20 token_, address owner_) {
        token = token_;
        _transferOwnership(owner_);
    }

    /// @dev function to initialize vesting (only owner)
    /// @param startTimestamp_ timestamp of start
    /// @param leaves_ link to merkle leaves
    /// @param root_ root of merkle tree
    /// @param rounds_ array of unlock schedule for each round
    function init(
        uint256 startTimestamp_,
        string memory leaves_,
        bytes32 root_,
        VestingRound[] memory rounds_
    ) external onlyOwner initializer {
        // validate startTimestamp
        if (startTimestamp_ == 0 || startTimestamp_ < block.timestamp)
            revert InvalidValue();

        roundLength = rounds_.length;
        // validate rounds
        if (roundLength == 0) revert InvalidLength();

        startTimestamp = startTimestamp_;
        leaves = leaves_;
        ROOT = root_;

        for (uint256 roundId; roundId < roundLength; ++roundId) {
            // check if round is not empty
            uint256 periodsLength = rounds_[roundId].periods.length;
            if (periodsLength == 0) revert InvalidLength();

            rounds[roundId].name = rounds_[roundId].name;
            uint256 percentageSumD;
            for (uint256 periodId; periodId < periodsLength; ++periodId) {
                // check if next period starts only after the previous period is finished
                if (periodId > 0) {
                    if (
                        uint256(
                            rounds_[roundId].periods[periodId].startTimestamp
                        ) <
                        uint256(
                            rounds_[roundId]
                                .periods[periodId - 1]
                                .startTimestamp
                        ) +
                            uint256(
                                rounds_[roundId].periods[periodId - 1].duration
                            )
                    ) revert InvalidValue();
                }

                uint32 duration = rounds_[roundId].periods[periodId].duration;
                uint32 unlocks = rounds_[roundId].periods[periodId].linearUnits;

                // if a period has positive duration (end > start)
                //  => number of unlocks can not be greater than duration (in seconds)
                if (duration > 0 && duration < unlocks) {
                    revert InvalidValue();
                }

                // add the current period to vesting round
                rounds[roundId].periods.push(
                    rounds_[roundId].periods[periodId]
                );
                percentageSumD += rounds_[roundId]
                    .periods[periodId]
                    .percentageD;
            }
            if (percentageSumD != DENOMINATOR * 100) revert InvalidValue();
        }

        emit InitializedVesting(block.timestamp, msg.sender);
    }

    /// @dev claims user's tokens
    /// @param roundId id of target
    /// @param allocations corresponding allocations for rounds
    /// @param targetAmount amount of token to claim
    function _claim(
        uint256 roundId,
        uint256[] calldata allocations,
        uint256 targetAmount
    ) internal nonReentrant returns (uint256 actualAmount) {
        uint256 totalAmount = unlocked(roundId, allocations[roundId]) -
            claimed(msg.sender, roundId);

        uint256 amount = targetAmount > totalAmount
            ? totalAmount
            : targetAmount;
        _updateClaimed(msg.sender, roundId, amount);

        if (amount == 0) revert ZeroClaim();
        token.safeTransfer(msg.sender, amount);
        actualAmount = amount;

        emit Claim(block.timestamp, msg.sender, rounds[roundId].name, amount);
    }

    /// @dev Claims user's tokens from a single round
    /// @param roundId Id of round to claim
    /// @param allocations corresponding allocations for rounds
    /// @param proof Merkle tree proof
    /// @param targetAmount Amount of token to claim
    function claimSingle(
        uint256 roundId,
        uint256[] calldata allocations,
        bytes32[] calldata proof,
        uint256 targetAmount
    ) external isStarted {
        // verify user address
        bytes32 leaf = keccak256(abi.encode(allocations, msg.sender));
        if (!proof.verify(ROOT, leaf)) revert WrongProof();

        // make a claim
        _claim(roundId, allocations, targetAmount);
    }

    /// @dev Claims user's tokens from a single round
    /// @param allocations corresponding allocations for rounds
    /// @param proof Merkle tree proof
    /// @param targetAmount Amount of token to claim
    function claimAll(
        uint256[] calldata allocations,
        bytes32[] calldata proof,
        uint256 targetAmount
    ) external isStarted {
        // check if msg.sender is allowed to claim tokens
        bytes32 leaf = keccak256(abi.encode(allocations, msg.sender));
        if (!proof.verify(ROOT, leaf)) revert WrongProof();

        uint256 amountToClaim = targetAmount;

        for (uint256 roundId; roundId < roundLength; ++roundId) {
            uint256 totalAmount = unlocked(roundId, allocations[roundId]) -
                claimed(msg.sender, roundId);
            // check if a user participates in the vesting round
            if (totalAmount == 0) {
                continue;
            }
            // try to make a claim
            uint256 claimedFromRound = _claim(
                roundId,
                allocations,
                amountToClaim
            );
            amountToClaim -= claimedFromRound;

            // continue only if there is amount to claim
            if (amountToClaim == 0) {
                break;
            }
        }
    }

    /// @dev Returns claimed amount for user
    /// @param user Address of user
    /// @param id Id of round
    /// @return Claimed claimed amount for user in round
    function claimed(address user, uint256 id)
        public
        view
        virtual
        returns (uint256)
    {
        return _claimed[user][id];
    }

    /// @dev Updates claimed amount for user in round
    /// @param user Address of user
    /// @param id Id of round
    /// @param amount Amount on update
    function _updateClaimed(
        address user,
        uint256 id,
        uint256 amount
    ) internal {
        _claimed[user][id] += amount;
    }

    /// @dev Calculates unclaimed total amount of tokens
    /// @param id Id of rounds
    /// @param allocation Allocation for user
    /// @return amount Amount of tokens that are free to be claimed
    function unlocked(uint256 id, uint256 allocation)
        public
        view
        virtual
        returns (uint256)
    {
        uint256 length = rounds[id].periods.length;
        uint256 passedUnlocks;
        uint256 totalUnlocks = 1;
        uint128 sumWeightD;
        uint128 lastWeightD;
        for (uint256 periodId; periodId < length; ++periodId) {
            uint64 start = rounds[id].periods[periodId].startTimestamp;
            uint32 duration = rounds[id].periods[periodId].duration;
            uint32 unlocks = rounds[id].periods[periodId].linearUnits;
            uint64 end = start + duration;
            // passed stage

            if (end <= block.timestamp) {
                sumWeightD += rounds[id].periods[periodId].percentageD;
                continue;
            }

            // 1 second period
            if (start == end) {
                totalUnlocks = 1;
                passedUnlocks = block.timestamp < start ? 0 : 1;
            } else {
                uint256 passedTime;
                if (block.timestamp > start) {
                    passedTime = block.timestamp - start;
                }

                // [unlocks * (passedTime / timeTotal)].Floor()
                passedUnlocks = (passedTime * unlocks) / (end - start);
                totalUnlocks = unlocks;
            }
            lastWeightD = rounds[id].periods[periodId].percentageD;

            break;
        }
        uint256 result = (allocation *
            (sumWeightD * totalUnlocks + lastWeightD * passedUnlocks)) /
            (DENOMINATOR * 100 * totalUnlocks);
        return result;
    }

    /// @dev returns rounds for vesting
    ///
    /// @return array of rounds
    function getRounds() external view returns (VestingRound[] memory) {
        VestingRound[] memory rounds_ = new VestingRound[](roundLength);
        for (uint256 i; i < roundLength; ++i) rounds_[i] = rounds[i];

        return rounds_;
    }

    /// @dev returns rounds for vesting
    ///
    /// @return array of rounds
    function getRound(uint256 id) external view returns (VestingRound memory) {
        VestingRound memory round_ = rounds[id];

        return round_;
    }

    /// @dev function to claim all left tokens (only owner)
    /// @param recipient is address withdraw tokens to
    /// @param amount is tokens amount to withdraw
    function withdraw(address recipient, uint256 amount)
        external
        onlyOwner
        nonReentrant
    {
        token.safeTransfer(recipient, amount);
    }

    /// @dev function to reset ROOT if allocations changed
    /// @param root_ is new merkle tree root hash
    /// @param leaves_ is new link to allocations information
    function resetROOT(bytes32 root_, string memory leaves_)
        external
        onlyOwner
    {
        ROOT = root_;
        leaves = leaves_;
    }

    /// @dev function to get allocations link
    function getAllocations() external view returns (string memory) {
        return leaves;
    }
}