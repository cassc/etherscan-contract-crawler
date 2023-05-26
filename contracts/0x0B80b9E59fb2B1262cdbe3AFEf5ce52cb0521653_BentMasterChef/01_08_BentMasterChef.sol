// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../libraries/Errors.sol";

contract BentMasterChef is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;

    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        //   pending reward = (user.amount * pool.accRewardPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accRewardPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. Rewards to distribute per block.
        uint256 lastRewardBlock; // Last block number that Rewards distribution occurs.
        uint256 accRewardPerShare; // Accumulated Rewards per share, times 1e36. See below.
    }

    // BENT
    IERC20 public bent;
    // BENT tokens reward per block.
    uint256 public rewardPerBlock;
    // max BENT tokens reward per block. 20M / 4 years
    uint256 public maxRewardPerBlock;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // user's withdrawable rewards
    mapping(uint256 => mapping(address => uint256)) private userRewards;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when BENT mining starts.
    uint256 public startBlock;

    // Events
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardPaid(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(
        IERC20 _bent,
        uint256 _rewardPerBlock,
        uint256 _startBlock
    ) Ownable() ReentrancyGuard() {
        bent = _bent;
        // rewardPerBlock at deployment will be max reward per block
        maxRewardPerBlock = _rewardPerBlock;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function updateRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        require(
            _rewardPerBlock <= maxRewardPerBlock,
            Errors.INVALID_REWARD_PER_BLOCK
        );

        massUpdatePools();
        rewardPerBlock = _rewardPerBlock;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) external onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accRewardPerShare: 0
            })
        );
    }

    // Update the given pool's BENT allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint =
            totalAllocPoint -
            poolInfo[_pid].allocPoint +
            _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // View function to see pending BENT on frontend.
    function pendingReward(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 bentReward = ((block.number - pool.lastRewardBlock) *
                rewardPerBlock *
                pool.allocPoint) / totalAllocPoint;
            accRewardPerShare += (bentReward * 1e36) / lpSupply;
        }
        return
            userRewards[_pid][_user] +
            (user.amount * accRewardPerShare) /
            1e36 -
            user.rewardDebt;
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 bentReward = ((block.number - pool.lastRewardBlock) *
            rewardPerBlock *
            pool.allocPoint) / totalAllocPoint;
        pool.accRewardPerShare += (bentReward * 1e36) / lpSupply;
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for BENT allocation.
    function deposit(uint256 _pid, uint256 _amount) external nonReentrant {
        require(_amount > 0, Errors.INVALID_AMOUNT);

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        queueRewards(_pid, msg.sender);

        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        user.amount += _amount;
        user.rewardDebt = (user.amount * pool.accRewardPerShare) / 1e36;

        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        require(_amount > 0, Errors.INVALID_AMOUNT);

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, Errors.INVALID_AMOUNT);

        updatePool(_pid);
        queueRewards(_pid, msg.sender);

        user.amount -= _amount;
        user.rewardDebt = (user.amount * pool.accRewardPerShare) / 1e36;
        pool.lpToken.safeTransfer(address(msg.sender), _amount);

        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Claim Bent from MasterChef
    function claim(uint256 _pid, address _account) external nonReentrant {
        updatePool(_pid);
        queueRewards(_pid, _account);

        uint256 pending = userRewards[_pid][_account];
        require(pending > 0, Errors.NO_PENDING_REWARD);

        userRewards[_pid][_account] = 0;
        userInfo[_pid][_account].rewardDebt =
            (userInfo[_pid][_account].amount *
                poolInfo[_pid].accRewardPerShare) /
            (1e36);

        bent.safeTransfer(_account, pending);

        emit RewardPaid(_account, _pid, pending);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
        userRewards[_pid][msg.sender] = 0;

        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
    }

    // Queue rewards - increase pending rewards
    function queueRewards(uint256 _pid, address _account) internal {
        UserInfo memory user = userInfo[_pid][_account];
        uint256 pending = (user.amount * poolInfo[_pid].accRewardPerShare) /
            (1e36) -
            user.rewardDebt;
        if (pending > 0) {
            userRewards[_pid][_account] += pending;
        }
    }

    // owner can force withdraw bent tokens
    function forceWithdrawBent(uint256 _amount)
        external
        onlyOwner
        nonReentrant
    {
        bent.safeTransfer(msg.sender, _amount);
    }
}