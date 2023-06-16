// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IReservoir.sol";

/**
 * @title MasterChef
 */
contract MasterChef is Ownable {
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of rewardTokens
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accRewardPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accRewardPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;             // Address of LP token contract.
        uint256 allocPoint;         // How many allocation points assigned to this pool. rewardTokens to distribute per block.
        uint256 lastRewardBlock;    // Last block number that rewardTokens distribution occurs.
        uint256 accRewardPerShare;  // Accumulated rewardTokens per share, times 1e18. See below.
    }

    // The REWARD TOKEN!
    IERC20 public rewardToken;
    // rewardTokens created per block.
    uint256 public rewardPerBlock;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when rewardToken mining starts.
    uint256 public startBlock;

    // Token reservoir.
    IReservoir public rewardReservoir;

    // Checking already added LP tokens.
    mapping(address => bool) private lpTokens;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    event SetRewardReservoir(address reservoir); // Set reward reservoir event.
    event SetRewardPerBlock(uint256 rewardPerBlock); // Set rewardPerBlock event.

    constructor(
        IERC20 _rewardToken,
        IReservoir _rewardReservoir,
        uint256 _rewardPerBlock,
        uint256 _startBlock
    ) {
        require(address(_rewardToken) != address(0), "MasterChef: rewardToken cannot be zero address");

        rewardToken = _rewardToken;
        rewardReservoir = _rewardReservoir;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
    }


    // ** EXTERNAL VIEW functions **

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // View function to see pending rewardTokens on frontend.
    function pendingReward(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = _getMultiplier(pool.lastRewardBlock, block.number);
            uint256 tokenReward = multiplier * rewardPerBlock * pool.allocPoint / totalAllocPoint;
            tokenReward = _availableReward(tokenReward); // amount available on rewardReservoir
            accRewardPerShare = accRewardPerShare + (tokenReward * 1e18 / lpSupply);
        }
        return (user.amount * accRewardPerShare / 1e18) - user.rewardDebt;
    }


    // ** POOL PUBLIC functions **

    // Update reward variables for all pools. Be careful of gas spending!
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
        uint256 multiplier = _getMultiplier(pool.lastRewardBlock, block.number);
        uint256 tokenReward = multiplier * rewardPerBlock * pool.allocPoint / totalAllocPoint;
        tokenReward = rewardReservoir.drip(tokenReward); // transfer tokens from rewardReservoir
        pool.accRewardPerShare = pool.accRewardPerShare + (tokenReward * 1e18 / lpSupply);
        pool.lastRewardBlock = block.number;
    }


    // ** USER EXTERNAL functions **

    // Deposit LP tokens to MasterChef for rewardToken allocation.
    function deposit(uint256 _pid, uint256 _amount) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = (user.amount * pool.accRewardPerShare / 1e18) - user.rewardDebt;
            if (pending > 0) {
                _safeRewardTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount += _amount;
        }
        user.rewardDebt = user.amount * pool.accRewardPerShare / 1e18;
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "MasterChef: amount exceeds balance");
        updatePool(_pid);
        uint256 pending = (user.amount * pool.accRewardPerShare / 1e18) - user.rewardDebt;
        if (pending > 0) {
            _safeRewardTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount -= _amount;
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount * pool.accRewardPerShare / 1e18;
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }


    // ** ONLY OWNER functions **

    // Add a new lp to the pool. Can only be called by the owner.
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) external onlyOwner {
        // Trying to add the same LP token more than once.
        require(!lpTokens[address(_lpToken)], "MasterChef: LP token has already been added");
        lpTokens[address(_lpToken)] = true;

        // Trying to add rewardToken as LP token.
        require(address(_lpToken) != address(rewardToken), "MasterChef: reward token cannot be LP token");

        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = (block.number > startBlock) ? block.number : startBlock;
        totalAllocPoint += _allocPoint;
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accRewardPerShare: 0
        }));
    }

    // Update the given pool's rewardToken allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) external onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        require(totalAllocPoint > 0, "MasterChef: totalAllocPoint cannot be zero");

        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Set reward per block. Can only be called by the owner.
    function setRewardPerBlock(uint256 _rewardPerBlock, bool _withUpdate) external onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        rewardPerBlock = _rewardPerBlock;
        emit SetRewardPerBlock(_rewardPerBlock);
    }

    // Set rewardReservoir. Can only be called by the owner.
    function setRewardReservoir(IReservoir _rewardReservoir) external onlyOwner {
        rewardReservoir = _rewardReservoir;
        emit SetRewardReservoir(address(_rewardReservoir));
    }


    // ** INTERNAL functions **

    // Return reward multiplier over the given _from to _to block.
    function _getMultiplier(uint256 _from, uint256 _to) internal pure returns (uint256) {
        return (_to - _from);
    }

    // Return available reward on rewardReservoir.
    function _availableReward(uint256 _requestedTokens) internal view returns (uint256) {
        uint256 reservoirBalance = rewardToken.balanceOf(address(rewardReservoir));
        return (_requestedTokens > reservoirBalance) ? reservoirBalance : _requestedTokens;
    }

    // Safe rewardToken transfer function, just in case if rounding error causes pool to not have enough rewardTokens.
    function _safeRewardTransfer(address _to, uint256 _amount) internal {
        uint256 rewardBal = rewardToken.balanceOf(address(this));
        if (_amount > rewardBal) {
            rewardToken.safeTransfer(_to, rewardBal);
        } else {
            rewardToken.safeTransfer(_to, _amount);
        }
    }
}