// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./interfaces/IRewardsLocker.sol";
import "./interfaces/IVotingWeightSource.sol";
import "./interfaces/IGovernanceRegistry.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Kapital DAO Rewards Locker
 * @author Playground Labs
 * @custom:security-contact [email protected]
 * @notice KAP rewards claimed from a staking pool are locked here for 52 weeks
 * before being made available for withdrawal
 */
contract RewardsLocker is IRewardsLocker, IVotingWeightSource, AccessControlEnumerable {
    bytes32 public constant KAP_SAVER = keccak256("KAP_SAVER"); // role to call {transferKAP}
    bytes32 public constant LOCK_CREATOR = keccak256("LOCK_CREATOR"); // role to call {createLockAgreement}

    IGovernanceRegistry public immutable governanceRegistry; // used to query the latest governance address
    IERC20 public immutable kapToken; // the rewards token

    mapping(address => LockAgreement[]) public lockAgreements;
    mapping(address => uint256) public votingWeight; // the DAO may vote to include {RewardsLocker} as a voting weight source
    uint256 public totalVotingWeight; // sum over {votingWeight}, for security monitoring

    constructor(
        address _stakingPool,
        address _governanceRegistry,
        address _kapToken,
        address _teamMultisig
    ) {
        require(_stakingPool != address(0), "RewardsLocker: Zero address");
        require(_governanceRegistry != address(0), "RewardsLocker: Zero address");
        require(_kapToken != address(0), "RewardsLocker: Zero address");
        require(_teamMultisig != address(0), "RewardsLocker: Zero address");

        governanceRegistry = IGovernanceRegistry(_governanceRegistry);
        kapToken = IERC20(_kapToken);
        _grantRole(LOCK_CREATOR, _stakingPool);
        _grantRole(KAP_SAVER, _teamMultisig);
    }

    /**
     * @notice Called by role {LOCK_CREATOR} when KAP rewards are claimed
     * @param beneficiary Address which is permitted to collect the KAP
     * @param amount Number of KAP tokens promised in the lock agreement
     */
    function createLockAgreement(address beneficiary, uint256 amount) external onlyRole(LOCK_CREATOR) {
        votingWeight[beneficiary] += amount;
        totalVotingWeight += amount;
        lockAgreements[beneficiary].push(
            LockAgreement({
                availableTimestamp: SafeCast.toUint64(
                    block.timestamp + (52 weeks)
                ),
                amount: SafeCast.toUint96(amount),
                collected: false
            })
        );
        emit CreateLockAgreement(beneficiary, amount);
    }

    /**
     * @notice Called by the beneficiary of a lock agreement
     * @param lockAgreementId Index in `lockAgreements[beneficiary]`
     */
    function collectRewards(uint256 lockAgreementId) external {
        require(lockAgreementId < lockAgreements[msg.sender].length, "RewardsLocker: Invalid Id");
        LockAgreement storage lockAgreement = lockAgreements[msg.sender][lockAgreementId];
        uint256 amount = lockAgreement.amount;

        require(
            block.timestamp >= lockAgreement.availableTimestamp,
            "RewardsLocker: Too early"
        ); // make sure beneficiary waits 52 weeks before collecting rewards
        require(!lockAgreement.collected, "RewardsLocker: Already collected"); // prohibit double-collection
        
        lockAgreement.collected = true;
        votingWeight[msg.sender] -= amount;
        totalVotingWeight -= amount;
        emit CollectRewards(msg.sender, lockAgreementId);
        SafeERC20.safeTransfer(kapToken, msg.sender, amount);
    }

    /**
     * @dev Used in emergency to save KAP rewards from vulnerability
     * @param to Address of recipient of saved KAP rewards
     * @param amount Amount of KAP rewards to save
     */
    function transferKap(address to, uint256 amount) external {
        bool senderIsGovernance = (msg.sender == governanceRegistry.governance());
        bool authorized = senderIsGovernance || hasRole(KAP_SAVER, msg.sender);

        require(authorized, "RewardsLocker: Access denied");
        require(amount > 0, "RewardsLocker: Invalid amount");

        emit TransferKap(to, amount);
        SafeERC20.safeTransfer(kapToken, to, amount);
    }

    /**
     * @notice Used on the front-end
     * @param user Owner of {LockAgreement}s
     * @return {LockAgreement}s associated with `user`
     */
    function getLockAgreements(
        address user
    ) external view returns (LockAgreement[] memory) {
        return lockAgreements[user];
    }
}