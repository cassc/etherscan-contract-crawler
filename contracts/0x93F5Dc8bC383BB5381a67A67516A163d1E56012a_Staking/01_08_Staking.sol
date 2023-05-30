// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "./interfaces/IERC677Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

contract Staking is Ownable, Multicall, IERC677Receiver {
    using SafeERC20 for IERC20;

    /// @notice Info of each Staking user.
    /// `amount` LP token amount the user has provided.
    /// `rewardDebt` The amount of token entitled to the user.
    struct UserInfo {
        uint256 amount;
        int256 rewardDebt;
    }

    /// @notice Info of each Staking pool.
    /// `allocPoint` The amount of allocation points assigned to the pool.
    /// Also known as the amount of token to distribute per block.
    struct PoolInfo {
        uint128 accRewardPerShare;
        uint64 lastRewardBlock;
        uint64 allocPoint;
    }

    /// @notice Address of token contract.
    IERC20 public rewardToken;
    address public rewardOwner;

    /// @notice Info of each Staking pool.
    PoolInfo[] public poolInfo;
    /// @notice Address of the LP token for each Staking pool.
    IERC20[] public lpToken;

    /// @notice Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    /// @dev Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    uint256 public rewardPerBlock = 0;
    uint256 private constant ACC_PRECISION = 1e12;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event LogPoolAddition(uint256 indexed pid, uint256 allocPoint, IERC20 indexed lpToken);
    event LogSetPool(uint256 indexed pid, uint256 allocPoint);
    event LogUpdatePool(uint256 indexed pid, uint64 lastRewardBlock, uint256 lpSupply, uint256 accRewardPerShare);

    /// @param _rewardToken The reward token contract address.
    constructor(IERC20 _rewardToken, address _rewardOwner, uint256 _rewardPerBlock) public Ownable() {
        rewardToken = _rewardToken;
        rewardOwner = _rewardOwner;
        rewardPerBlock = _rewardPerBlock;
    }

    /// @notice Sets the reward token.
    function setRewardToken(IERC20 _rewardToken) public onlyOwner {
        rewardToken = _rewardToken;
    }

    /// @notice Sets the reward owner.
    function setRewardOwner(address _rewardOwner) public onlyOwner {
        rewardOwner = _rewardOwner;
    }

    /// @notice Adjusts the reward per block.
    function setRewardsPerBlock(uint256 _rewardPerBlock) public onlyOwner {
        rewardPerBlock = _rewardPerBlock;
    }

    /// @notice Returns the number of Staking pools.
    function poolLength() public view returns (uint256 pools) {
        pools = poolInfo.length;
    }

    /// @notice Add a new LP to the pool. Can only be called by the owner.
    /// DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    /// @param allocPoint AP of the new pool.
    /// @param _lpToken Address of the LP ERC-20 token.
    function add(uint256 allocPoint, IERC20 _lpToken) public onlyOwner {
        uint256 lastRewardBlock = block.number;
        totalAllocPoint = totalAllocPoint + allocPoint;
        lpToken.push(_lpToken);

        poolInfo.push(PoolInfo({
            allocPoint: uint64(allocPoint),
            lastRewardBlock: uint64(lastRewardBlock),
            accRewardPerShare: 0
        }));
        emit LogPoolAddition(lpToken.length - 1, allocPoint, _lpToken);
    }

    /// @notice Update the given pool's token allocation point. Can only be called by the owner.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _allocPoint New AP of the pool.
    function set(uint256 _pid, uint256 _allocPoint) public onlyOwner {
        totalAllocPoint = (totalAllocPoint - poolInfo[_pid].allocPoint) + _allocPoint;
        poolInfo[_pid].allocPoint = uint64(_allocPoint);
        emit LogSetPool(_pid, _allocPoint);
    }

    /// @notice View function to see pending token reward on frontend.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _user Address of user.
    /// @return pending token reward for a given user.
    function pendingRewards(uint256 _pid, address _user) external view returns (uint256 pending) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 lpSupply = lpToken[_pid].balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 blocks = block.number - pool.lastRewardBlock;
            uint256 reward = (blocks * rewardPerBlock * pool.allocPoint) / totalAllocPoint;
            accRewardPerShare = accRewardPerShare + ((reward * ACC_PRECISION) / lpSupply);
        }
        pending = uint256(int256((user.amount * accRewardPerShare) / ACC_PRECISION) - user.rewardDebt);
    }

    /// @notice Update reward variables for all pools. Be careful of gas spending!
    /// @param pids Pool IDs of all to be updated. Make sure to update all active pools.
    function massUpdatePools(uint256[] calldata pids) external {
        uint256 len = pids.length;
        for (uint256 i = 0; i < len; ++i) {
            updatePool(pids[i]);
        }
    }

    /// @notice Update reward variables of the given pool.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @return pool Returns the pool that was updated.
    function updatePool(uint256 pid) public returns (PoolInfo memory pool) {
        pool = poolInfo[pid];
        if (block.number > pool.lastRewardBlock) {
            uint256 lpSupply = lpToken[pid].balanceOf(address(this));
            if (lpSupply > 0) {
                uint256 blocks = block.number - pool.lastRewardBlock;
                uint256 reward = (blocks * rewardPerBlock * pool.allocPoint) / totalAllocPoint;
                pool.accRewardPerShare = pool.accRewardPerShare + uint128((reward * ACC_PRECISION) / lpSupply);
            }
            pool.lastRewardBlock = uint64(block.number);
            poolInfo[pid] = pool;
            emit LogUpdatePool(pid, pool.lastRewardBlock, lpSupply, pool.accRewardPerShare);
        }
    }

    /// @notice Deposit LP tokens to Staking for reward token allocation.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to deposit.
    /// @param to The receiver of `amount` deposit benefit.
    function deposit(uint256 pid, uint256 amount, address to) public {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][to];

        // Effects
        user.amount = user.amount + amount;
        user.rewardDebt = user.rewardDebt + int256((amount * pool.accRewardPerShare) / ACC_PRECISION);

        // Interactions
        lpToken[pid].safeTransferFrom(msg.sender, address(this), amount);

        emit Deposit(msg.sender, pid, amount, to);
    }

    /// @notice Withdraw LP tokens from Staking.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to withdraw.
    /// @param to Receiver of the LP tokens.
    function withdraw(uint256 pid, uint256 amount, address to) public {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][msg.sender];

        // Effects
        user.rewardDebt = user.rewardDebt - int256((amount * pool.accRewardPerShare) / ACC_PRECISION);
        user.amount = user.amount - amount;

        // Interactions
        lpToken[pid].safeTransfer(to, amount);

        emit Withdraw(msg.sender, pid, amount, to);
    }

    /// @notice Harvest proceeds for transaction sender to `to`.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param to Receiver of token rewards.
    function harvest(uint256 pid, address to) public {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][msg.sender];
        int256 accumulatedReward = int256((user.amount * pool.accRewardPerShare) / ACC_PRECISION);
        uint256 _pendingReward = uint256(accumulatedReward - user.rewardDebt);

        // Effects
        user.rewardDebt = accumulatedReward;

        // Interactions
        if (_pendingReward != 0) {
            rewardToken.safeTransferFrom(rewardOwner, to, _pendingReward);
        }
        
        emit Harvest(msg.sender, pid, _pendingReward);
    }
    
    /// @notice Withdraw LP tokens from Staking and harvest proceeds for transaction sender to `to`.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to withdraw.
    /// @param to Receiver of the LP tokens and token rewards.
    function withdrawAndHarvest(uint256 pid, uint256 amount, address to) public {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][msg.sender];
        int256 accumulatedReward = int256((user.amount * pool.accRewardPerShare) / ACC_PRECISION);
        uint256 _pendingReward = uint256(accumulatedReward - user.rewardDebt);

        // Effects
        user.rewardDebt = accumulatedReward - int256((amount * pool.accRewardPerShare) / ACC_PRECISION);
        user.amount = user.amount - amount;
        
        // Interactions
        rewardToken.safeTransferFrom(rewardOwner, to, _pendingReward);
        lpToken[pid].safeTransfer(to, amount);

        emit Withdraw(msg.sender, pid, amount, to);
        emit Harvest(msg.sender, pid, _pendingReward);
    }

    /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param to Receiver of the LP tokens.
    function emergencyWithdraw(uint256 pid, address to) public {
        UserInfo storage user = userInfo[pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;

        // Note: transfer can fail or succeed if `amount` is zero.
        lpToken[pid].safeTransfer(to, amount);
        emit EmergencyWithdraw(msg.sender, pid, amount, to);
    }

    function onTokenTransfer(address to, uint amount, bytes calldata _data) external override {
        uint pid = 0;
        require(msg.sender == address(rewardToken), "onTokenTransfer: can only be called by rewardToken");
        require(msg.sender == address(lpToken[pid]), "onTokenTransfer: pool 0 needs to be a rewardToken pool");
        if (amount > 0) {
            // Deposit skipping token transfer (as it already was)
            PoolInfo memory pool = updatePool(pid);
            UserInfo storage user = userInfo[pid][to];

            // Effects
            user.amount = user.amount + amount;
            user.rewardDebt = user.rewardDebt + int256((amount * pool.accRewardPerShare) / ACC_PRECISION);

            emit Deposit(msg.sender, pid, amount, to);
        }
    }
}