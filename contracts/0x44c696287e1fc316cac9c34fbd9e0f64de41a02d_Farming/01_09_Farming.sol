// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title Farming contract
 *
 * @notice Locked Farming contract
 * When users deposit/withdraw, the lock duration will be reset
 * Users should pay fee for withdraw before unlock
 */
contract Farming is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 pendingRewards;
        uint256 lastClaim;
    }

    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardTimestamp;
        uint256 accTokenPerShare;
        uint256 lockupDuration;
        uint256 amount;
    }

    IERC20 public token; // reward token
    uint256 public tokenPerSecond; // reward per second

    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    uint256 public totalAllocPoint;
    uint256 public startTimestamp; // reward start timestamp

    // 5% fee when users withdraw before unlock
    uint256 public earlyWithdrawFee;
    uint256 public constant FEE_MULTIPLIER = 10000;
    address public treasury; // fee will be sent to treasury

    uint256 public constant SHARE_MULTIPLIER = 1e12;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Claim(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardPerSecondChanged(uint256 reward);
    event PoolAdded(
        address indexed token,
        uint256 indexed pid,
        uint256 allocPoint,
        uint256 lockDuration
    );
    event PoolUpdated(uint256 indexed pid, uint256 allocPoint, uint256 lockDuration);
    event TimeChanged(uint256 startTimestamp);
    event TokenSet(address token);
    event Pause();
    event Unpause();

    /**
     * @notice constructor
     *
     * @param _token            {IERC20}    Address of reward token
     * @param _tokenPerSecond   {uint256}   Reward per second
     * @param _startTimestamp   {uint256}   timestamp of reward start
     * @param _treasury         {address}   Address of treasury wallet
     */
    constructor(
        IERC20 _token,
        uint256 _tokenPerSecond,
        uint256 _startTimestamp,
        address _treasury
    ) {
        require(address(_token) != address(0), "Invalid token address!");
        require(address(_treasury) != address(0), "Invalid treasury address!");

        token = _token;
        tokenPerSecond = _tokenPerSecond;
        startTimestamp = _startTimestamp;
        treasury = _treasury;

        earlyWithdrawFee = 500; // 5%

        emit TokenSet(address(token));
        emit RewardPerSecondChanged(_tokenPerSecond);
        emit TimeChanged(startTimestamp);
    }

    modifier validatePoolByPid(uint256 _pid) {
        require(_pid < poolInfo.length, "Pool does not exist");
        _;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function getPools() external view returns (PoolInfo[] memory) {
        return poolInfo;
    }

    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to - _from;
    }

    function pendingToken(
        uint256 _pid,
        address _user
    ) external view validatePoolByPid(_pid) returns (uint256) {
        require(_user != address(0), "Invalid address!");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accTokenPerShare = pool.accTokenPerShare;
        uint256 lpSupply = pool.amount;
        if (block.timestamp > pool.lastRewardTimestamp && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardTimestamp, block.timestamp);
            uint256 tokenReward = (multiplier * tokenPerSecond * pool.allocPoint) / totalAllocPoint;
            accTokenPerShare = accTokenPerShare + ((tokenReward * SHARE_MULTIPLIER) / lpSupply);
        }
        return
            (user.amount * (accTokenPerShare)) /
            SHARE_MULTIPLIER -
            user.rewardDebt +
            user.pendingRewards;
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public validatePoolByPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTimestamp) {
            return;
        }
        uint256 lpSupply = pool.amount;
        if (lpSupply == 0) {
            pool.lastRewardTimestamp = block.timestamp;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardTimestamp, block.timestamp);
        uint256 tokenReward = (multiplier * tokenPerSecond * pool.allocPoint) / totalAllocPoint;
        pool.accTokenPerShare =
            pool.accTokenPerShare +
            ((tokenReward * SHARE_MULTIPLIER) / lpSupply);
        pool.lastRewardTimestamp = block.timestamp;
    }

    /**
     * @notice deposit
     * If amount is zero, it will claim pending rewards
     * If amount is not zero, it will deposit and reset unlock time
     *
     * @param _pid      {uint256}   Pool Id
     * @param _amount   {uint256}   Amount of token to deposit
     */
    function deposit(
        uint256 _pid,
        uint256 _amount
    ) external nonReentrant whenNotPaused validatePoolByPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = (user.amount * pool.accTokenPerShare) /
                SHARE_MULTIPLIER -
                user.rewardDebt;

            if (pending > 0) {
                user.pendingRewards = user.pendingRewards + pending;
                uint256 claimedAmount = safeTokenTransfer(msg.sender, user.pendingRewards);
                emit Claim(msg.sender, _pid, claimedAmount);
                user.pendingRewards -= claimedAmount;
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(msg.sender, address(this), _amount);
            pool.amount += _amount;
            user.amount += _amount;
            user.lastClaim = block.timestamp;
        }
        user.rewardDebt = (user.amount * pool.accTokenPerShare) / SHARE_MULTIPLIER;
        emit Deposit(msg.sender, _pid, _amount);
    }

    /**
     * @notice withdraw
     * If amount is zero, it will claim pending rewards
     * If amount is not zero, it will withdraw and reset unlock time
     *
     * @param _pid      {uint256}   Pool Id
     * @param _amount   {uint256}   Amount of token to withdraw
     */
    function withdraw(
        uint256 _pid,
        uint256 _amount
    ) external nonReentrant whenNotPaused validatePoolByPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.amount >= _amount, "withdraw: not good");

        uint256 feeAmount;
        if (block.timestamp < user.lastClaim + pool.lockupDuration) {
            feeAmount = (_amount * earlyWithdrawFee) / FEE_MULTIPLIER;
        }

        updatePool(_pid);

        uint256 pending = (user.amount * pool.accTokenPerShare) /
            SHARE_MULTIPLIER -
            user.rewardDebt;
        if (pending > 0) {
            user.pendingRewards += pending;
            uint256 claimedAmount = safeTokenTransfer(msg.sender, user.pendingRewards);
            emit Claim(msg.sender, _pid, claimedAmount);
            user.pendingRewards -= claimedAmount;
        }

        if (_amount > 0) {
            user.amount -= _amount;
            user.lastClaim = block.timestamp;

            pool.lpToken.safeTransfer(address(msg.sender), _amount - feeAmount);

            if (feeAmount > 0) {
                pool.lpToken.safeTransfer(treasury, feeAmount);
            }

            pool.amount -= _amount;
        }

        user.rewardDebt = (user.amount * pool.accTokenPerShare) / SHARE_MULTIPLIER;

        emit Withdraw(msg.sender, _pid, _amount);
    }

    function safeTokenTransfer(address _to, uint256 _amount) internal returns (uint256) {
        uint256 tokenBal = token.balanceOf(address(this));
        if (_amount > tokenBal) {
            token.safeTransfer(_to, tokenBal);
            return tokenBal;
        } else {
            token.safeTransfer(_to, _amount);
            return _amount;
        }
    }

    /**
     * @notice add a farming pool
     * @dev
     * @param _allocPoint       {uint256} Reward allocation point
     * @param _lpToken          {uint256} Address of lp token
     * @param _withUpdate       {uint256} Update other pools or not
     * @param _lockupDuration   {uint256} Lockup Duration
     */
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate,
        uint256 _lockupDuration
    ) external onlyOwner {
        require(_lockupDuration > 0, "Invalid lockupDuration");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardTimestamp = block.timestamp > startTimestamp
            ? block.timestamp
            : startTimestamp;
        totalAllocPoint = totalAllocPoint + (_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardTimestamp: lastRewardTimestamp,
                accTokenPerShare: 0,
                lockupDuration: _lockupDuration,
                amount: 0
            })
        );

        emit PoolAdded(address(_lpToken), poolInfo.length - 1, _allocPoint, _lockupDuration);
    }

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        uint256 _lockupDuration,
        bool _withUpdate
    ) external onlyOwner validatePoolByPid(_pid) {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].lockupDuration = _lockupDuration;

        emit PoolUpdated(_pid, _allocPoint, _lockupDuration);
    }

    function setTokenPerSecond(uint256 _tokenPerSecond) external onlyOwner {
        require(_tokenPerSecond > 0, "Invalid");
        tokenPerSecond = _tokenPerSecond;

        emit RewardPerSecondChanged(_tokenPerSecond);
    }

    function setTreasury(address _treasury) external onlyOwner {
        require(address(_treasury) != address(0), "Invalid treasury address!");

        treasury = _treasury;
    }

    function setStartTime(uint256 _startTime) external onlyOwner {
        require(_startTime > block.timestamp, "Invalid");
        require(startTimestamp > block.timestamp, "Can't update");

        startTimestamp = _startTime;

        emit TimeChanged(startTimestamp);
    }

    function setEarlyWithdrawFee(uint256 _earlyWithdrawFee) external onlyOwner {
        require(_earlyWithdrawFee < FEE_MULTIPLIER, "Fee can't be 100%");

        earlyWithdrawFee = _earlyWithdrawFee;
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
        emit Pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
        emit Unpause();
    }
}