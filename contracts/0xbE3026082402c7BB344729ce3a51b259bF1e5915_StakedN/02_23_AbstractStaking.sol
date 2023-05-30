//SPDX-License-Identifier: MIT
/**
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(     (@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           @@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(   @@@@@@@@@@@@@@@@@@@@(            @@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@@@@@             @@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           @@@@@@@@@@@(            @@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@             @@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@(            @@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@     @@@@@@@     @@@@@@@             @@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@(         @@(         @@(            @@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@          @@          @@           @@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@     @@@@@@@     @@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@ @@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(     @@@@@@@     @@@@@@@     @@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           @           @           @@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@(            @@@         @@@         @@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@             @@@@@@@     @@@@@@@     @@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@(            @@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@             @@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@(            @@@@@@@@@@@@           @@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@(            @@@@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@(     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 */
pragma solidity 0.8.6;

import "./interfaces/INil.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title AbstractStaking
 * @author Nil DAO
 */
abstract contract AbstractStaking is AccessControl, ReentrancyGuard {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN");

    event Staked(address account, uint256 amount, uint256 balance, uint256 rewards, uint256 votes);
    event Unstaked(address account, uint256 amount, uint256 balance, uint256 rewards, uint256 votes);
    event Rewarded(address account, uint256 rewards);
    event VotesSpent(address account, uint256 votesSpent, uint256 totalVotesStored);
    event VotesSpenderSet(address spender);
    event MinStakingPeriodSet(uint256 minStakingPeriod);

    mapping(address => uint256) public balancePerAccount;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public userVotesPerTokenPaid;
    mapping(address => uint256) public rewardsByAccount;
    mapping(address => uint256) public votesByAccount;
    mapping(address => uint256) public stakingTimeByAccount;

    address public voteSpender;
    bool public emergencyShutdown;
    uint256 public lastRewardsRateUpdate;
    uint256 public lastVotesUpdate;
    uint256 public rewardRatePerSecond;
    uint256 public votesRatePerSecond;
    uint256 public rewardPerTokenStored;
    uint256 public votesPerTokenStored;
    uint256 public totalVotesStored;
    uint256 public minStakingPeriod;
    uint256 public totalBalance;

    INil public immutable nil;

    constructor(
        INil nil_,
        address dao,
        uint256 rewardRatePerSecond_,
        uint256 votesRatePerSecond_
    ) {
        require(address(nil_) != address(0), "AbstractStaking:ILLEGAL_ADDRESS");
        nil = nil_;
        rewardRatePerSecond = rewardRatePerSecond_;
        votesRatePerSecond = votesRatePerSecond_;
        lastRewardsRateUpdate = block.timestamp;
        lastVotesUpdate = block.timestamp;
        minStakingPeriod = 0;
        _setupRole(GUARDIAN_ROLE, dao);
        _setupRole(ADMIN_ROLE, dao);
        _setupRole(GUARDIAN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender); // This will be surrendered after deployment
        _setRoleAdmin(GUARDIAN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
    }

    modifier onlyGuardian() {
        require(hasRole(GUARDIAN_ROLE, msg.sender), "AbstractStaking:ACCESS_DENIED");
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "AbstractStaking:ACCESS_DENIED");
        _;
    }

    function updateRewards(uint256 newRate) external onlyAdmin {
        require(newRate != rewardRatePerSecond, "AbstractStaking:RATE_NOT_CHANGED");
        rewardPerTokenStored = rewardPerToken();
        lastRewardsRateUpdate = block.timestamp;
        rewardRatePerSecond = newRate;
    }

    function updateVotes(uint256 newRate) external onlyAdmin {
        require(newRate != votesRatePerSecond, "AbstractStaking:RATE_NOT_CHANGED");
        totalVotesStored = totalVotes();
        votesPerTokenStored = votesPerToken();
        lastVotesUpdate = block.timestamp;
        votesRatePerSecond = newRate;
    }

    function rewardPerToken() public view returns (uint256) {
        uint256 delta = block.timestamp - lastRewardsRateUpdate;
        uint256 accruedRewards = delta * rewardRatePerSecond;
        return (rewardPerTokenStored + accruedRewards);
    }

    function votesPerToken() public view returns (uint256) {
        uint256 delta = block.timestamp - lastVotesUpdate;
        uint256 accruedVotes = delta * votesRatePerSecond;
        return (votesPerTokenStored + accruedVotes);
    }

    function calculateCurrentRewards(address account) public view returns (uint256, uint256) {
        uint256 currentRewardPerToken = rewardPerToken();
        uint256 newlyAccruedRewardsPerToken = (currentRewardPerToken - userRewardPerTokenPaid[account]);
        uint256 currentRewards = rewardsByAccount[account] +
            ((balancePerAccount[account] * newlyAccruedRewardsPerToken) / 1e18);
        return (currentRewards, currentRewardPerToken);
    }

    function calculateCurrentVotes(address account) public view returns (uint256, uint256) {
        uint256 currentVotesPerToken = votesPerToken();
        uint256 newlyAccruedVotesPerToken = (currentVotesPerToken - userVotesPerTokenPaid[account]);
        uint256 currentVotes = votesByAccount[account] +
            ((balancePerAccount[account] * newlyAccruedVotesPerToken) / 1e18);
        return (currentVotes, currentVotesPerToken);
    }

    function _accrueRewards(address account) internal returns (uint256) {
        (uint256 currentRewards, uint256 currentRewardPerToken) = calculateCurrentRewards(account);
        rewardsByAccount[account] = currentRewards;
        userRewardPerTokenPaid[account] = currentRewardPerToken;
        return currentRewards;
    }

    function _accrueVotes(address account) internal returns (uint256) {
        (uint256 currentVotes, uint256 currentVotesPerToken) = calculateCurrentVotes(account);
        votesByAccount[account] = currentVotes;
        userVotesPerTokenPaid[account] = currentVotesPerToken;
        // The following differs from rewards as we want to keep track of total votes
        uint256 newlyAccruedVotesPerToken = (currentVotesPerToken - votesPerTokenStored);
        totalVotesStored = totalVotesStored + ((totalBalance * newlyAccruedVotesPerToken) / 1e18);
        lastVotesUpdate = block.timestamp;
        votesPerTokenStored = currentVotesPerToken;
        return currentVotes;
    }

    function _stake(address account, uint256 amount) internal {
        require(!emergencyShutdown, "AbstractStaking:SHUTDOWN");
        uint256 rewards = _accrueRewards(account);
        uint256 votes = _accrueVotes(account);
        uint256 balance = balancePerAccount[account];
        balancePerAccount[account] = balance + amount;
        totalBalance += amount;
        stakingTimeByAccount[account] = block.timestamp;
        emit Staked(account, amount, balance, rewards, votes);
    }

    function _unstake(address account, uint256 amount) internal {
        if (emergencyShutdown) return;
        require(
            block.timestamp - stakingTimeByAccount[account] > minStakingPeriod,
            "AbstractStaking:MIN_STAKING_REQUIRED"
        );
        uint256 rewards = _accrueRewards(account);
        uint256 votes = _accrueVotes(account);
        uint256 balance = balancePerAccount[account];
        balancePerAccount[account] = balance - amount;
        totalBalance -= amount;
        emit Unstaked(account, amount, balance, rewards, votes);
    }

    function claim(address account) external nonReentrant {
        require(!emergencyShutdown, "AbstractStaking:SHUTDOWN");
        (uint256 currentRewards, uint256 currentRewardPerToken) = calculateCurrentRewards(account);
        require(currentRewards > 0, "AbstractStaking:ZERO_REWARDS");
        rewardsByAccount[account] = 0;
        userRewardPerTokenPaid[account] = currentRewardPerToken;
        nil.mint(account, currentRewards);
        emit Rewarded(account, currentRewards);
    }

    function claimableOf(address account) external view returns (uint256) {
        (uint256 currentRewards, ) = calculateCurrentRewards(account);
        return currentRewards;
    }

    function spendVotes(address account, uint256 amount) external nonReentrant {
        require(!emergencyShutdown, "AbstractStaking:SHUTDOWN");
        require(voteSpender == msg.sender, "AbstractStaking:ACCESS_DENIED");
        (uint256 currentVotes, uint256 currentVotesPerToken) = calculateCurrentVotes(account);
        votesByAccount[account] = currentVotes - amount;
        userVotesPerTokenPaid[account] = currentVotesPerToken;
        uint256 newlyAccruedVotesPerToken = (currentVotesPerToken - votesPerTokenStored);
        totalVotesStored = (totalVotesStored + ((totalBalance * newlyAccruedVotesPerToken) / 1e18)) - amount;
        lastVotesUpdate = block.timestamp;
        votesPerTokenStored = currentVotesPerToken;
        emit VotesSpent(account, amount, totalVotesStored);
    }

    function totalVotes() public view returns (uint256) {
        return (totalVotesStored + ((totalBalance * (votesPerToken() - votesPerTokenStored)) / 1e18));
    }

    function setVoteSpender(address voteSpender_) external onlyAdmin {
        voteSpender = voteSpender_;
        emit VotesSpenderSet(voteSpender_);
    }

    function setMinStakingPeriod(uint256 minStakingPeriod_) external onlyAdmin {
        require(minStakingPeriod_ < 14 days, "AbstractStaking:ILLEGAL_MIN_STAKING_PERIOD");
        minStakingPeriod = minStakingPeriod_;
        emit MinStakingPeriodSet(minStakingPeriod_);
    }

    function setEmergencyShutdown(bool emergencyShutdown_) external onlyGuardian {
        emergencyShutdown = emergencyShutdown_;
    }
}