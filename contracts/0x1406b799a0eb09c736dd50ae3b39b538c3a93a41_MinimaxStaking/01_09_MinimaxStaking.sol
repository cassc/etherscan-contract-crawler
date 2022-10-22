// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IMinimaxToken.sol";

contract MinimaxStaking is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    uint public constant SHARE_MULTIPLIER = 1e12;

    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct UserPoolInfo {
        uint amount; // How many LP tokens the user has provided.
        uint rewardDebt; // Reward debt. See explanation below.
        uint timeDeposited; // timestamp when minimax was deposited
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20Upgradeable token; // Address of LP token contract.
        uint totalSupply;
        uint allocPoint; // How many allocation points assigned to this pool. MINIMAXs to distribute per block.
        uint timeLocked; // How long stake must be locked for
        uint lastRewardBlock; // Last block number that MINIMAXs distribution occurs.
        uint accMinimaxPerShare; // Accumulated MINIMAXs per share, times SHARE_MULTIPLIER. See below.
    }

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint => mapping(address => UserPoolInfo)) public userPoolInfo;

    address public minimaxToken;
    uint public minimaxPerBlock;
    uint public startBlock;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint public totalAllocPoint;

    event Deposit(address indexed user, uint indexed pid, uint amount);
    event Withdraw(address indexed user, uint indexed pid, uint amount);
    event EmergencyWithdraw(address indexed user, uint indexed pid, uint256 amount);
    event PoolAdded(uint allocPoint, uint timeLocked);
    event SetMinimaxPerBlock(uint minimaxPerBlock);
    event SetPool(uint pid, uint allocPoint);

    function initialize(
        address _minimaxToken,
        uint _minimaxPerBlock,
        uint _startBlock
    ) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        minimaxToken = _minimaxToken;
        minimaxPerBlock = _minimaxPerBlock;
        startBlock = _startBlock;

        // staking pool
        poolInfo.push(
            PoolInfo({
                token: IERC20Upgradeable(minimaxToken),
                totalSupply: 0,
                allocPoint: 800,
                timeLocked: 0 days,
                lastRewardBlock: startBlock,
                accMinimaxPerShare: 0
            })
        );
        poolInfo.push(
            PoolInfo({
                token: IERC20Upgradeable(minimaxToken),
                totalSupply: 0,
                allocPoint: 1400,
                timeLocked: 7 days,
                lastRewardBlock: startBlock,
                accMinimaxPerShare: 0
            })
        );
        poolInfo.push(
            PoolInfo({
                token: IERC20Upgradeable(minimaxToken),
                totalSupply: 0,
                allocPoint: 2000,
                timeLocked: 30 days,
                lastRewardBlock: startBlock,
                accMinimaxPerShare: 0
            })
        );
        poolInfo.push(
            PoolInfo({
                token: IERC20Upgradeable(minimaxToken),
                totalSupply: 0,
                allocPoint: 3000,
                timeLocked: 90 days,
                lastRewardBlock: startBlock,
                accMinimaxPerShare: 0
            })
        );
        totalAllocPoint = 7200;
    }

    /* ========== External Functions ========== */

    function getUserAmount(uint _pid, address _user) external view returns (uint) {
        UserPoolInfo storage user = userPoolInfo[_pid][_user];
        return user.amount;
    }

    // View function to see pending MINIMAXs from Pools on frontend.
    function pendingMinimax(uint _pid, address _user) external view returns (uint) {
        PoolInfo memory pool = poolInfo[_pid];
        UserPoolInfo memory user = userPoolInfo[_pid][_user];

        // Minting reward
        uint accMinimaxPerShare = pool.accMinimaxPerShare;
        if (block.number > pool.lastRewardBlock && pool.totalSupply != 0) {
            uint multiplier = block.number - pool.lastRewardBlock;
            uint minimaxReward = (multiplier * minimaxPerBlock * pool.allocPoint) / totalAllocPoint;
            accMinimaxPerShare = accMinimaxPerShare + (minimaxReward * SHARE_MULTIPLIER) / pool.totalSupply;
        }
        uint pendingUserMinimax = (user.amount * accMinimaxPerShare) / SHARE_MULTIPLIER - user.rewardDebt;
        return pendingUserMinimax;
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        if (pool.totalSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        // Minting reward
        uint multiplier = block.number - pool.lastRewardBlock;
        uint minimaxReward = (multiplier * minimaxPerBlock * pool.allocPoint) / totalAllocPoint;
        pool.accMinimaxPerShare = pool.accMinimaxPerShare + (minimaxReward * SHARE_MULTIPLIER) / pool.totalSupply;
        pool.lastRewardBlock = block.number;
    }

    // Deposit lp tokens for MINIMAX allocation.
    function deposit(uint _pid, uint _amount) external nonReentrant {
        require(_amount > 0, "deposit: amount is 0");
        PoolInfo storage pool = poolInfo[_pid];
        UserPoolInfo storage user = userPoolInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            _claimPendingMintReward(_pid, msg.sender);
        }
        if (_amount > 0) {
            uint before = pool.token.balanceOf(address(this));
            pool.token.safeTransferFrom(address(msg.sender), address(this), _amount);
            uint post = pool.token.balanceOf(address(this));
            uint finalAmount = post - before;
            user.amount = user.amount + finalAmount;
            user.timeDeposited = block.timestamp;
            pool.totalSupply = pool.totalSupply + finalAmount;
            emit Deposit(msg.sender, _pid, finalAmount);
        }
        user.rewardDebt = (user.amount * pool.accMinimaxPerShare) / SHARE_MULTIPLIER;
    }

    // Withdraw LP tokens
    function withdraw(uint _pid, uint _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserPoolInfo storage user = userPoolInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: requested amount is high");
        require(block.timestamp >= user.timeDeposited + pool.timeLocked, "can't withdraw before end of lock-up");

        updatePool(_pid);
        _claimPendingMintReward(_pid, msg.sender);

        if (_amount > 0) {
            user.amount = user.amount - _amount;
            pool.totalSupply = pool.totalSupply - _amount;
            pool.token.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = (user.amount * pool.accMinimaxPerShare) / SHARE_MULTIPLIER;
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint _pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserPoolInfo storage user = userPoolInfo[_pid][msg.sender];
        require(block.timestamp >= user.timeDeposited + pool.timeLocked, "time locked");

        uint amount = user.amount;

        pool.totalSupply = pool.totalSupply - user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.token.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint length = poolInfo.length;
        for (uint pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint _allocPoint,
        address _poolToken,
        uint _timeLocked
    ) external onlyOwner {
        massUpdatePools();
        uint lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolInfo.push(
            PoolInfo({
                token: IERC20Upgradeable(_poolToken),
                totalSupply: 0,
                allocPoint: _allocPoint,
                timeLocked: _timeLocked,
                lastRewardBlock: lastRewardBlock,
                accMinimaxPerShare: 0
            })
        );
        emit PoolAdded(_allocPoint, _timeLocked);
    }

    // Update the given pool's MINIMAX allocation point. Can only be called by the owner.
    function set(uint _pid, uint _allocPoint) external onlyOwner {
        massUpdatePools();
        uint prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint - prevAllocPoint + _allocPoint;
        }
        emit SetPool(_pid, _allocPoint);
    }

    function setMinimaxPerBlock(uint _minimaxPerBlock) external onlyOwner {
        minimaxPerBlock = _minimaxPerBlock;
        emit SetMinimaxPerBlock(_minimaxPerBlock);
    }

    function _claimPendingMintReward(uint _pid, address _user) private {
        PoolInfo storage pool = poolInfo[_pid];
        UserPoolInfo storage user = userPoolInfo[_pid][_user];

        uint pendingMintReward = (user.amount * pool.accMinimaxPerShare) / SHARE_MULTIPLIER - user.rewardDebt;
        if (pendingMintReward > 0) {
            IMinimaxToken(minimaxToken).mint(_user, pendingMintReward);
        }
    }
}