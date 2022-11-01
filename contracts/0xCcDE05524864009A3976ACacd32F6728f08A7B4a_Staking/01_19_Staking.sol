// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./interfaces/IGovernance.sol";
import "./interfaces/IGovernanceRegistry.sol";
import "./interfaces/IRewardsLocker.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/IVotingWeightSource.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

/**
 * @title Kapital DAO Staking Pool
 * @author Playground Labs
 * @custom:security-contact [email protected]
 * @notice Staking pool contract for KAP-ETH Uniswap v2 LP tokens. The word
 * "rewards" refers to an amount of KAP given to a user in return for the
 * user's agreement to lock LP tokens in the staking pool.
 */
contract Staking is IStaking, IVotingWeightSource, AccessControlEnumerable {
    using SafeCast for uint256;
    uint256 public constant MIN_LOCK = 4 weeks; // minimum staking lock
    uint256 public constant MAX_LOCK = 52 weeks; // maximum staking lock
    uint256 public constant CUMULATIVE_MULTIPLIER = 1e12; // to reduce integer division error
    bytes32 public constant TEAM_MULTISIG = keccak256("TEAM_MULTISIG");

    using SafeERC20 for IERC20;
    IERC20 public immutable asset; // staked token, KAP or KAP-ETH LP
    IGovernanceRegistry public immutable governanceRegistry; // used to query the latest governance address
    IRewardsLocker public immutable rewardsLocker; // claimed rewards locked here for 52 weeks before withdrawal

    uint256 public cumulative; // cumulative rewards per wight, multiplied by {CUMULATIVE_MULTIPLIER}
    uint256 public totalWeight; // total staking weight in pool
    uint256 public syncdTo; // timestamp at which {cumulative} is valid
    uint256 public totalBoostRewards; // track total claimed boost rewards, for security monitoring
    bool public boostOn = true; // boosting can be turned off by governance or team multisig
    Emission public emission; // controls rewards emission rate
    mapping(address => Deposit[]) public deposits;
    mapping(address => uint256) public totalStaked; // voting weight
    mapping(address => uint256) public lastStaked; // to securely report voting weight

    constructor(
        address _asset,
        address _governanceRegistry,
        address _rewardsLocker,
        address _teamMultisig
    ) {
        require(_asset != address(0), "Staking: Zero address");
        require(_governanceRegistry != address(0), "Staking: Zero address");
        require(_rewardsLocker != address(0), "Staking: Zero address");
        require(_teamMultisig != address(0), "Staking: Zero address");

        asset = IERC20(_asset);
        governanceRegistry = IGovernanceRegistry(_governanceRegistry);
        rewardsLocker = IRewardsLocker(_rewardsLocker);
        _grantRole(TEAM_MULTISIG, _teamMultisig);
    }

    /**
     * @notice Updates {cumulative} and {syncdTo} based on {emission}
     */
    function _sync() internal {
        if (block.timestamp > syncdTo) {
            uint256 expiration = emission.expiration;
            if (syncdTo < expiration && totalWeight > 0) {
                uint256 timeElapsed =
                    block.timestamp < expiration ? block.timestamp - syncdTo : expiration - syncdTo;
                cumulative += (emission.rate * timeElapsed * CUMULATIVE_MULTIPLIER) / totalWeight;
            }
            syncdTo = block.timestamp;
            emit Sync(msg.sender, cumulative);
        }
    }

    modifier syncd() {
        _sync();
        _;
    }

    /**
     * @notice Creates a deposit with the specified amount and lock period
     * @param amount The token amount to stake in units of wei
     * @param lock The time in seconds to lock the tokens for
     * @dev Requires token allowance from staker
     */
    function stake(uint256 amount, uint256 lock) external syncd {
        require(amount > 0, "Staking: Zero amount");
        require(MIN_LOCK <= lock && lock <= MAX_LOCK, "Staking: Lock");
        require(amount <= type(uint112).max, "Staking: Overflow");

        deposits[msg.sender].push(
            Deposit({
                amount: uint112(amount),
                start: block.timestamp.toUint64(),
                end: (block.timestamp + lock).toUint64(),
                collected: false,
                cumulative: cumulative
            })
        );
        totalWeight += amount * lock;
        totalStaked[msg.sender] += amount;
        lastStaked[msg.sender] = block.timestamp;
        emit Stake(msg.sender, deposits[msg.sender].length - 1, amount, lock);

        asset.safeTransferFrom(msg.sender, address(this), amount); // no LP tokens are lost during transfer, expected amount always received
    }

    /**
     * @notice Collects the deposit amount and claims rewards
     * @param depositId The deposit array index to collect from
     */
    function unstake(uint256 depositId) external syncd {
        Deposit storage deposit = deposits[msg.sender][depositId];
        uint256 amount = deposit.amount;
        uint256 end = deposit.end;

        require(!deposit.collected, "Staking: Already collected");
        require(block.timestamp >= end, "Staking: Early unstake");

        totalWeight -= amount * (end - deposit.start);
        totalStaked[msg.sender] -= amount;
        claimRewards(depositId, 0); // must claim before updating `deposit.collected`, see {claimRewards}
        deposit.collected = true;
        emit Unstake(msg.sender, depositId, amount);

        asset.safeTransfer(msg.sender, amount);
    }

    /**
     * @notice Claims rewards and restakes if boosting
     * @param depositId The deposit array index to claim from
     * @param extension The time in seconds to extend the lock period
     */
    function claimRewards(uint256 depositId, uint256 extension) public syncd {
        Deposit storage deposit = deposits[msg.sender][depositId];
        uint256 amount = deposit.amount;
        uint256 end = deposit.end;
        uint256 lock = end - deposit.start;
        uint256 weight = amount * lock;
        uint256 cumulativeDifference = cumulative - deposit.cumulative;
        uint256 rewards = (weight * cumulativeDifference) / CUMULATIVE_MULTIPLIER;
        
        require(!deposit.collected, "Staking: Already collected"); // rewards stop accumulating after principal is collected

        if (boostOn && extension > 0) {
            uint256 boostRewards = _boost(deposit, amount, end, lock, weight, extension, rewards);
            rewards += boostRewards;
            emit Extend(msg.sender, depositId, extension, boostRewards);
        }
        deposit.cumulative = cumulative;
        emit ClaimRewards(msg.sender, depositId, extension, rewards);

        if (rewards > 0) {
            rewardsLocker.createLockAgreement(msg.sender, rewards);
        }
    }

    /**
     * @notice Calculates boost rewards and updates state
     */
    function _boost(
        Deposit storage deposit,
        uint256 amount,
        uint256 end,
        uint256 lock,
        uint256 weight,
        uint256 extension,
        uint256 rewards
    ) internal returns (uint256 boostRewards) {
        require(block.timestamp < end, "Staking: Remaining");
        uint256 remaining = end - block.timestamp;
        uint256 maxExtension = MAX_LOCK - remaining;
        boostRewards = (rewards * remaining * extension) / (lock * maxExtension);
        uint256 newStart = block.timestamp;
        uint256 newEnd = end + extension;
        uint256 newLock = newEnd - newStart;
        uint256 newWeight = amount * newLock;

        require(MIN_LOCK <= newLock && newLock <= MAX_LOCK, "Staking: New lock");

        deposit.start = newStart.toUint64();
        deposit.end = newEnd.toUint64();
        totalWeight -= weight;
        totalWeight += newWeight;
        totalBoostRewards += boostRewards;
    }

    modifier onlyAdmin() {
        require(
            msg.sender == governanceRegistry.governance() || hasRole(TEAM_MULTISIG, msg.sender),
            "Staking: Only admin"
        );
        _;
    }

    /**
     * @notice Sets a new rate and expiration for {emission}
     * @param rate The new kap per second reward
     * @param expiration The new timestamp after which rewards stop
     */
    function updateEmission(uint256 rate, uint256 expiration) external onlyAdmin syncd {
        require(block.timestamp < expiration, "Staking: Invalid expiration");
        emission.rate = rate.toUint128();
        emission.expiration = expiration.toUint128();
        emit UpdateEmission(msg.sender, rate, expiration);
    }

    /**
     * @notice Permanently turns off boosting
     */
    function turnOffBoost() external onlyAdmin {
        require(boostOn, "Staking: Already off");
        boostOn = false;
        emit TurnOffBoost(msg.sender);
    }

    /**
     * @notice Reports voting weight
     * @param voter Staker to report voting weight for
     */
    function votingWeight(address voter) external view returns (uint256) {
        uint256 votingPeriod = IGovernance(governanceRegistry.governance()).votingPeriod();
        uint256 timeElapsed = block.timestamp - lastStaked[voter];
        return timeElapsed > votingPeriod ? totalStaked[voter] : 0;
    }

    /**
     * @notice Front-end getter for staker deposits
     * @param staker Staker to get deposits for
     */
    function getDeposits(address staker) external view returns (Deposit[] memory) {
        return deposits[staker];
    }
}