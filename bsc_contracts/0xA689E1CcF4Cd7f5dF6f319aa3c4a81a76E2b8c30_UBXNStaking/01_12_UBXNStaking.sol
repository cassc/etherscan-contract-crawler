// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
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
    uint public periodFinish = 0;
    uint public rewardRate = 0;
    uint public rewardsDuration = 90 * 86400;
    uint public lastUpdateTime;
    uint public rewardPerTokenStored;

    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint) public rewards;

    uint private _totalDeposited;
    mapping(address => uint) private _deposits;
    mapping(address => uint) private _periods;
    mapping(address => uint) private _locks;

    uint private constant MULTIPLIER_BASE = 100;
    uint private constant MIN_LOCK = 30 * 86400;
    uint private constant MAX_LOCK = 2 * 360 * 86400;

    // MIN_LOCK = 30 * 86400;
    // MAX_LOCK = 2 * 360 * 86400;

    // CONSTRUCTOR

    constructor(
        address _rewardsToken,
        address _stakingToken
    ) ERC20("STAKED_SHARES-UBXN", "ssUBXN") {
        require(_stakingToken != address(0), "invalid staking token");
        require(_rewardsToken != address(0), "invalid rewards token");
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
    }

    // VIEWS

    function totalDeposited() external view returns (uint) {
        return _totalDeposited;
    }

    function depositOf(address account) external view returns (uint) {
        return _deposits[account];
    }

    function unlockedAt(address account) external view returns (uint) {
        return _locks[account];
    }

    function lockedFor(address account) external view returns (uint) {
        return _periods[account];
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored + (
                (lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18 / totalSupply()
            );
    }

    function earned(address account) public view returns (uint) {
        return
            balanceOf(account) * (rewardPerToken() - userRewardPerTokenPaid[account]) / 1e18 + rewards[account];
    }

    function getRewardForDuration() external view returns (uint) {
        return rewardRate * rewardsDuration;
    }

    function min(uint a, uint b) public pure returns (uint) {
        return a < b ? a : b;
    }

    // PUBLIC FUNCTIONS

    function stake(uint amount, uint lockPeriod)
        external
        nonReentrant
        whenNotPaused
        updateReward(msg.sender)
    {
        require(
            amount > 0, 
            "stake: cannot stake 0"
        );

        require(
            lockPeriod >= MIN_LOCK, 
            "stake: lock period < 30 days"
        );

        if (_deposits[msg.sender] > 0) {
            require(
                lockPeriod >= _periods[msg.sender], 
                "stake: can not set lower lock period while staking"
            );
        }

        if (lockPeriod > MAX_LOCK) {
            lockPeriod = MAX_LOCK;
        }

        uint balBefore = stakingToken.balanceOf(address(this));
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        uint balAfter = stakingToken.balanceOf(address(this));
        uint actualReceived = balAfter - balBefore;

        uint total = _deposits[msg.sender] + actualReceived;
        uint shares = 0;

        // max multiplier (2 year lock) = 24 * 12 = 288 + 100 = 388 / 100 = 3.88x 
        uint lockMultiplier = (lockPeriod - MIN_LOCK) / MIN_LOCK * 12 + MULTIPLIER_BASE;
        shares = total * lockMultiplier / MULTIPLIER_BASE;

        _deposits[msg.sender] = total;
        _totalDeposited = _totalDeposited + actualReceived;

        _mint(msg.sender, shares - balanceOf(msg.sender));
        
        _periods[msg.sender] = lockPeriod;
        _locks[msg.sender] = block.timestamp + lockPeriod;
        emit Staked(msg.sender, actualReceived, lockPeriod);
    }

    function extend(uint lockPeriod)
        external
        nonReentrant
        updateReward(msg.sender)
    {
        require(
            _deposits[msg.sender] > 0, 
            "extend: you need to stake first"
        );

        require(
            lockPeriod > _periods[msg.sender], 
            "extend: can not set lower lock period while staking"
        );

        if (lockPeriod > MAX_LOCK) {
            lockPeriod = MAX_LOCK;
        }

        uint shares = 0;
        uint lockMultiplier = (lockPeriod - MIN_LOCK) / MIN_LOCK * 12 + MULTIPLIER_BASE;
        shares = _deposits[msg.sender] * lockMultiplier / MULTIPLIER_BASE;

        _mint(msg.sender, shares - balanceOf(msg.sender));

        uint _period = _periods[msg.sender];
        _periods[msg.sender] = lockPeriod;
        _locks[msg.sender] = _locks[msg.sender] - _period + lockPeriod;
        emit Extended(msg.sender, _period, lockPeriod);
    }

    function withdraw(uint amount)
        public
        nonReentrant
        updateReward(msg.sender)
    {
        require(
            amount > 0, 
            "withdraw: cannot withdraw 0"
        );

        require(
            _deposits[msg.sender] > 0, 
            "withdraw: you need to stake first"
        );

        require(
            block.timestamp >= _locks[msg.sender], 
            "withdraw: lock period not over"
        );

        uint percentage = amount * 1e18 / _deposits[msg.sender];
        uint shares = balanceOf(msg.sender) * percentage / 1e18;
        if (shares > balanceOf(msg.sender)) shares = balanceOf(msg.sender);

        _deposits[msg.sender] = _deposits[msg.sender] - amount;
        _totalDeposited = _totalDeposited - amount;

        _burn(msg.sender, shares);

        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public nonReentrant updateReward(msg.sender) {
        uint reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
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
        uint amount
    ) internal virtual override(ERC20) {
        require(
            from == address(0) || to == address(0), 
            "Transfers between wallets are disabled"
        );

        super._beforeTokenTransfer(from, to, amount);
    }

    // RESTRICTED FUNCTIONS

    function notifyRewardAmount(uint reward)
        external
        onlyOwner
        updateReward(address(0))
    {
        uint oldBalance = rewardsToken.balanceOf(address(this));
        rewardsToken.safeTransferFrom(msg.sender, address(this), reward);
        uint newBalance = rewardsToken.balanceOf(address(this));
        uint actualReceived = newBalance - oldBalance;
        require(actualReceived == reward, "Whitelist the pool to exclude fees");

        if (block.timestamp >= periodFinish) {
            rewardRate = reward / rewardsDuration;
        } else {
            uint remaining = periodFinish - block.timestamp;
            uint leftover = remaining * rewardRate;
            rewardRate = (reward + leftover) / rewardsDuration;
        }

        uint balance = rewardsToken.balanceOf(address(this));
        require(
            rewardRate <= balance / rewardsDuration,
            "Provided reward too high"
        );

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + rewardsDuration;
        emit RewardAdded(reward);
    }

    function recoverERC20(address tokenAddress, uint tokenAmount)
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

    function setRewardsDuration(uint _rewardsDuration) external onlyOwner {
        require(
            block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    // *** MODIFIERS ***

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }

        _;
    }

    // EVENTS

    event RewardAdded(uint reward);
    event Staked(address indexed user, uint amount, uint lockPeriod);
    event Extended(address indexed user, uint oldPeriod, uint newPeriod);
    event Withdrawn(address indexed user, uint amount);
    event RewardPaid(address indexed user, uint reward);
    event RewardsDurationUpdated(uint newDuration);
    event Recovered(address token, uint amount);
}