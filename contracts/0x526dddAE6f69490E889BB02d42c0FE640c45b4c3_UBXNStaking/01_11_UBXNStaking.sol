// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract UBXNStaking is ERC20, ReentrancyGuard, Pausable, Ownable {
    using SafeERC20 for IERC20;

    // STATE VARIABLES

    IERC20 public rewardsToken;
    IERC20 public stakingToken;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration = 12 * 3600;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalDeposited;
    mapping(address => uint256) private _deposits;
    mapping(address => uint256) private _periods;
    mapping(address => uint256) private _locks;

    uint256 private constant MULTIPLIER_BASE = 100;
    uint256 private constant MIN_LOCK = 30 * 86400;
    uint256 private constant MAX_LOCK = 2 * 360 * 86400;
    uint32 public constant PERCENT_MAX = 100000;

    address public perfPool;
    address public treasuryAddress;
    uint256 public withdrawFee = 300;

    //farming
    address public farmingPool;
    mapping(address => uint256) public userFarmingRewardPerTokenPaid;
    mapping(address => uint256) public farmingRewards;
    uint256 public farmingRewardPerTokenStored;
    uint256 public lastRewardBlock;
    uint256 public rewardPerBlock;

    // CONSTRUCTOR

    constructor(
        address _rewardsToken,
        address _stakingToken,
        address _farmingPool,
        address _perfPool,
        address _treasuryAddress,
        uint256 _rewardPerBlock
    ) ERC20("STAKED_SHARES-UBXN", "ssUBXN") {
        require(_stakingToken != address(0), "invalid staking token");
        require(_rewardsToken != address(0), "invalid rewards token");
        require(_treasuryAddress != address(0), "invalid treasury address");
        require(_farmingPool != address(0), "invalid farming pool");
        require(_perfPool != address(0), "invalid perf pool");
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        treasuryAddress = _treasuryAddress;
        farmingPool = _farmingPool;
        perfPool = _perfPool;

        rewardPerBlock = _rewardPerBlock;
        lastRewardBlock = block.number;
    }

    // VIEWS

    function totalDeposited() external view returns (uint256) {
        return _totalDeposited;
    }

    function depositOf(address account) external view returns (uint256) {
        return _deposits[account];
    }

    function unlockedAt(address account) external view returns (uint256) {
        return _locks[account];
    }

    function lockedFor(address account) external view returns (uint256) {
        return _periods[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return min(block.timestamp, periodFinish);
    }

    function perfRewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            (((lastTimeRewardApplicable() - lastUpdateTime) *
                rewardRate *
                1e18) / totalSupply());
    }

    function earnedFromPerf(address account) public view returns (uint256) {
        return
            (balanceOf(account) *
                (perfRewardPerToken() - userRewardPerTokenPaid[account])) /
            1e18 +
            rewards[account];
    }

    function farmingRewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return farmingRewardPerTokenStored;
        }
        return
            farmingRewardPerTokenStored +
            (((block.number - lastRewardBlock) * rewardPerBlock * 1e18) /
                totalSupply());
    }

    function earnedFromFarming(address account) public view returns (uint256) {
        return
            (balanceOf(account) *
                (farmingRewardPerToken() -
                    userFarmingRewardPerTokenPaid[account])) /
            1e18 +
            farmingRewards[account];
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate * rewardsDuration;
    }

    function min(uint256 a, uint256 b) public pure returns (uint256) {
        return a < b ? a : b;
    }

    // PUBLIC FUNCTIONS

    function stake(uint256 amount, uint256 lockPeriod)
        external
        nonReentrant
        whenNotPaused
        updateReward(msg.sender)
    {
        require(amount > 0, "stake: cannot stake 0");

        require(lockPeriod >= MIN_LOCK, "stake: lock period < 30 days");

        if (_deposits[msg.sender] > 0) {
            require(
                lockPeriod >= _periods[msg.sender],
                "stake: can not set lower lock period while staking"
            );
        }

        if (lockPeriod > MAX_LOCK) {
            lockPeriod = MAX_LOCK;
        }

        uint256 balBefore = stakingToken.balanceOf(address(this));
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        uint256 balAfter = stakingToken.balanceOf(address(this));
        uint256 actualReceived = balAfter - balBefore;

        uint256 total = _deposits[msg.sender] + actualReceived;
        uint256 shares = 0;

        // max multiplier (2 year lock) = 24 * 12 = 288 + 100 = 388 / 100 = 3.88x
        uint256 lockMultiplier = ((lockPeriod - MIN_LOCK) / MIN_LOCK) *
            12 +
            MULTIPLIER_BASE;
        shares = (total * lockMultiplier) / MULTIPLIER_BASE;

        _deposits[msg.sender] = total;
        _totalDeposited = _totalDeposited + actualReceived;

        _mint(msg.sender, shares - balanceOf(msg.sender));

        _periods[msg.sender] = lockPeriod;
        _locks[msg.sender] = block.timestamp + lockPeriod;
        emit Staked(msg.sender, actualReceived, lockPeriod);
    }

    function extend(uint256 lockPeriod)
        external
        nonReentrant
        updateReward(msg.sender)
    {
        require(_deposits[msg.sender] > 0, "extend: you need to stake first");

        require(
            lockPeriod > _periods[msg.sender],
            "extend: can not set lower lock period while staking"
        );

        if (lockPeriod > MAX_LOCK) {
            lockPeriod = MAX_LOCK;
        }

        uint256 shares = 0;
        uint256 lockMultiplier = ((lockPeriod - MIN_LOCK) / MIN_LOCK) *
            12 +
            MULTIPLIER_BASE;
        shares = (_deposits[msg.sender] * lockMultiplier) / MULTIPLIER_BASE;

        _mint(msg.sender, shares - balanceOf(msg.sender));

        uint256 _period = _periods[msg.sender];
        _periods[msg.sender] = lockPeriod;
        _locks[msg.sender] = _locks[msg.sender] - _period + lockPeriod;
        emit Extended(msg.sender, _period, lockPeriod);
    }

    function withdraw(uint256 amount)
        public
        nonReentrant
        updateReward(msg.sender)
    {
        require(amount > 0, "withdraw: cannot withdraw 0");

        require(_deposits[msg.sender] > 0, "withdraw: you need to stake first");

        require(
            block.timestamp >= _locks[msg.sender],
            "withdraw: lock period not over"
        );

        uint256 percentage = (amount * 1e18) / _deposits[msg.sender];
        uint256 shares = (balanceOf(msg.sender) * percentage) / 1e18;
        if (shares > balanceOf(msg.sender)) shares = balanceOf(msg.sender);

        _deposits[msg.sender] = _deposits[msg.sender] - amount;
        _totalDeposited = _totalDeposited - amount;

        _burn(msg.sender, shares);

        uint256 feeAmount = (amount * withdrawFee) / PERCENT_MAX;
        stakingToken.safeTransfer(address(treasuryAddress), feeAmount);
        stakingToken.safeTransfer(msg.sender, amount - feeAmount);
        emit Withdrawn(msg.sender, amount - feeAmount);
    }

    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
        }
        uint256 farmingReward = farmingRewards[msg.sender];
        if (farmingReward > 0) {
            farmingRewards[msg.sender] = 0;
            rewardsToken.safeTransferFrom(
                farmingPool,
                msg.sender,
                farmingReward
            );
        }
        if (reward + farmingReward > 0) {
            emit RewardPaid(msg.sender, reward + farmingReward);
        }
    }

    function exit() external {
        withdraw(_deposits[msg.sender]);
        getReward();
    }

    // INTERNAL FUNCTIONS

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20) {
        require(
            from == address(0) || to == address(0),
            "Transfers between wallets are disabled"
        );

        super._beforeTokenTransfer(from, to, amount);
    }

    // RESTRICTED FUNCTIONS

    function updateRewardPerBlock(uint256 _rewardPerBlock)
        external
        onlyOwner
        updateReward(address(0))
    {
        rewardPerBlock = _rewardPerBlock;
    }

    function updateTreasury(address _treasuryAddress) public onlyOwner {
        require(_treasuryAddress != address(0), "invalid address");
        treasuryAddress = _treasuryAddress;
    }

    function updateWithdrawFee(uint32 _withdrawFee) external onlyOwner {
        require(_withdrawFee <= PERCENT_MAX / 10, "invalid withdrawal fee");
        withdrawFee = _withdrawFee;
    }

    function updatePerfPool(address _perfPool) external onlyOwner {
        require(_perfPool != address(0), "invalid address");
        perfPool = _perfPool;
    }

    function updateFarmingPool(address _farmingPool) external onlyOwner {
        require(_farmingPool != address(0), "invalid address");
        farmingPool = _farmingPool;
    }

    function distributePerfPoolRewards()
        external
        onlyOwner
        updateReward(address(0))
    {
        require(perfPool != address(0), "perfPool is not set");
        uint256 reward = rewardsToken.balanceOf(perfPool);
        uint256 oldBalance = rewardsToken.balanceOf(address(this));
        rewardsToken.safeTransferFrom(perfPool, address(this), reward);
        uint256 newBalance = rewardsToken.balanceOf(address(this));
        uint256 actualReceived = newBalance - oldBalance;
        require(actualReceived == reward, "Whitelist the pool to exclude fees");

        if (block.timestamp >= periodFinish) {
            rewardRate = reward / rewardsDuration;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (reward + leftover) / rewardsDuration;
        }

        uint256 balance = rewardsToken.balanceOf(address(this));
        require(
            rewardRate <= balance / rewardsDuration,
            "Provided reward too high"
        );

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + rewardsDuration;
        emit RewardAdded(reward);
    }

    function notifyRewardAmount(uint256 reward)
        external
        onlyOwner
        updateReward(address(0))
    {
        uint256 oldBalance = rewardsToken.balanceOf(address(this));
        rewardsToken.safeTransferFrom(msg.sender, address(this), reward);
        uint256 newBalance = rewardsToken.balanceOf(address(this));
        uint256 actualReceived = newBalance - oldBalance;
        require(actualReceived == reward, "Whitelist the pool to exclude fees");

        if (block.timestamp >= periodFinish) {
            rewardRate = reward / rewardsDuration;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (reward + leftover) / rewardsDuration;
        }

        uint256 balance = rewardsToken.balanceOf(address(this));
        require(
            rewardRate <= balance / rewardsDuration,
            "Provided reward too high"
        );

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + rewardsDuration;
        emit RewardAdded(reward);
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        external
        onlyOwner
    {
        require(
            tokenAddress != address(stakingToken) &&
                tokenAddress != address(rewardsToken),
            "Cannot withdraw the staking or rewards tokens"
        );
        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(
            block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    // *** MODIFIERS ***

    modifier updateReward(address account) {
        rewardPerTokenStored = perfRewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earnedFromPerf(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }

        farmingRewardPerTokenStored = farmingRewardPerToken();
        lastRewardBlock = block.number;
        if (account != address(0)) {
            farmingRewards[account] = earnedFromFarming(account);
            userFarmingRewardPerTokenPaid[
                account
            ] = farmingRewardPerTokenStored;
        }

        _;
    }

    // EVENTS

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount, uint256 lockPeriod);
    event Extended(address indexed user, uint256 oldPeriod, uint256 newPeriod);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);
}