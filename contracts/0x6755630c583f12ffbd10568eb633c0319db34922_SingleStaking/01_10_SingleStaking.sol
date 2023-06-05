// SPDX-License-Identifier: MIT
// Reference: copied from https://github.com/sushiswap/sushiswap/blob/canary/contracts/MasterChefV2.sol
// Reference: https://github.com/sushiswap/sushiswap/blob/canary/contracts/MiniChefV2.sol

pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "./interfaces/IRewarder.sol";
import "./libraries/SafeMath.sol";
import "./libraries/SignedSafeMath.sol";

// @notice Staking contract to reward Tokens for stakers
contract SingleStaking is Ownable, Multicall {
    using SafeMath for uint256;
    using SafeMath128 for uint128;
    using SafeERC20 for IERC20;
    using SignedSafeMath for int256;

    /// @notice Info of each stakers.
    /// `amount` LP token amount the user has provided.
    /// `rewardDebt` The amount of Token entitled to the user.
    struct UserInfo {
        uint256 amount;
        int256 rewardDebt;
    }

    // The amount of RewardToken entitled to a user but is pending to be distributed is:
    //
    //   pending reward = (user.amount * pool.accRewardPerShare) - user.rewardDebt
    //
    // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
    //   1. The pool's `accRewardPerShare` (and `lastRewardBlock`) gets updated.
    //   2. User receives the pending reward sent to his/her address.
    //   3. User's `amount` gets updated.
    //   4. User's `rewardDebt` gets updated.

    /// @notice Info of each Staking pool.
    /// `allocPoint` The amount of allocation points assigned to the pool.
    /// Also known as the amount of Token to distribute per block.
    struct PoolInfo {
        uint128 accRewardPerShare;
        uint64 lastRewardBlock;
        uint64 allocPoint;
    }

    /// @notice Address of Reward Token contract.
    IERC20 public immutable rewardToken;

    /// @notice Info of each Staking pool.
    PoolInfo[] public poolInfo;
    /// @notice Address of the LP token for each Staking pool.
    IERC20[] public lpToken;
    /// @notice Address of each `IRewarder` contract in Staking.
    IRewarder[] public rewarder;
    
    // @notice reward owner address which owns reward tokens
    address public rewardOwner;

    /// @notice Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    /// @dev Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    uint256 public blockReward;
    uint256 private constant ACC_PRECISION = 1e12;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event LogPoolAddition(uint256 indexed pid, uint256 allocPoint, IERC20 indexed lpToken, IRewarder indexed rewarder);
    event LogSetPool(uint256 indexed pid, uint256 allocPoint, IRewarder indexed rewarder, bool overwrite);
    event LogUpdatePool(uint256 indexed pid, uint64 lastRewardBlock, uint256 lpSupply, uint256 accRewardPerShare);
    event LogInit();
    event LogBlockReward(uint256 blockReward);

    /// @param _rewardToken The reward token contract address.
    /// @param _blockReward Initial Token Reward per block.
    constructor(IERC20 _rewardToken, address _rewardOwner, uint256 _blockReward) public {
        rewardToken = _rewardToken;
        blockReward = _blockReward;
        rewardOwner = _rewardOwner;
    }

    /// @notice Sets the reward owner.
    function setRewardOwner(address _rewardOwner) public onlyOwner {
        rewardOwner = _rewardOwner;
    }

    /// @notice set block reward.
    function setBlockReward(uint256 _blockReward) public onlyOwner {
        massUpdatePools();
        blockReward = _blockReward;
        emit LogBlockReward(_blockReward);
    }

    /// @notice Returns the number of Staking pools.
    function poolLength() public view returns (uint256 pools) {
        pools = poolInfo.length;
    }

    function checkPoolDuplicate(IERC20 _lpToken) public {
        uint256 length = lpToken.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            require(lpToken[pid] != _lpToken, "Staking: existing pool");
        }
    }

    /// @notice Add a new LP to the pool. Can only be called by the owner.
    /// DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    /// @param allocPoint AP of the new pool.
    /// @param _lpToken Address of the LP ERC-20 token.
    /// @param _rewarder Address of the rewarder delegate.
    function add(
        uint256 allocPoint,
        IERC20 _lpToken,
        IRewarder _rewarder
    ) public onlyOwner {
        checkPoolDuplicate(_lpToken);

        uint256 lastRewardBlock = block.number;
        totalAllocPoint = totalAllocPoint.add(allocPoint);
        lpToken.push(_lpToken);
        rewarder.push(_rewarder);

        poolInfo.push(
            PoolInfo({ allocPoint: allocPoint.to64(), lastRewardBlock: lastRewardBlock.to64(), accRewardPerShare: 0 })
        );
        emit LogPoolAddition(lpToken.length.sub(1), allocPoint, _lpToken, _rewarder);
    }

    /// @notice Update the given pool's Reward token allocation point and `IRewarder` contract. Can only be called by the owner.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _allocPoint New AP of the pool.
    /// @param _rewarder Address of the rewarder delegate.
    /// @param overwrite True if _rewarder should be `set`. Otherwise `_rewarder` is ignored.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        IRewarder _rewarder,
        bool overwrite
    ) public onlyOwner {
        massUpdatePools();
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint.to64();
        if (overwrite) {
            rewarder[_pid] = _rewarder;
        }
        emit LogSetPool(_pid, _allocPoint, overwrite ? _rewarder : rewarder[_pid], overwrite);
    }

    /// @notice View function to see pending Rewards on frontend.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _user Address of user.
    /// @return pending Token reward for a given user.
    function pendingRewards(uint256 _pid, address _user) external view returns (uint256 pending) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 lpSupply = lpToken[_pid].balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 blocks = block.number.sub(pool.lastRewardBlock);
            uint256 rewards = blocks.mul(blockReward).mul(pool.allocPoint) / totalAllocPoint;
            accRewardPerShare = accRewardPerShare.add(rewards.mul(ACC_PRECISION) / lpSupply);
        }
        pending = int256(user.amount.mul(accRewardPerShare) / ACC_PRECISION).sub(user.rewardDebt).toUInt256();
    }

    /// @notice Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
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
                uint256 blocks = block.number.sub(pool.lastRewardBlock);
                uint256 rewards = blocks.mul(blockReward).mul(pool.allocPoint) / totalAllocPoint;
                pool.accRewardPerShare = pool.accRewardPerShare.add((rewards.mul(ACC_PRECISION) / lpSupply).to128());
            }
            pool.lastRewardBlock = block.number.to64();
            poolInfo[pid] = pool;
            emit LogUpdatePool(pid, pool.lastRewardBlock, lpSupply, pool.accRewardPerShare);
        }
    }

    /// @notice Deposit LP tokens to Staking contract for Reward token allocation.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to deposit.
    /// @param to The receiver of `amount` deposit benefit.
    function deposit(
        uint256 pid,
        uint256 amount,
        address to
    ) public {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][to];

        // Effects
        user.amount = user.amount.add(amount);
        user.rewardDebt = user.rewardDebt.add(int256(amount.mul(pool.accRewardPerShare) / ACC_PRECISION));

        // Interactions
        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onTokenReward(pid, to, to, 0, user.amount);
        }

        lpToken[pid].safeTransferFrom(msg.sender, address(this), amount);

        emit Deposit(msg.sender, pid, amount, to);
    }

    /// @notice Withdraw LP tokens from Staking contract.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to withdraw.
    /// @param to Receiver of the LP tokens.
    function withdraw(
        uint256 pid,
        uint256 amount,
        address to
    ) public {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][msg.sender];

        // Effects
        user.rewardDebt = user.rewardDebt.sub(int256(amount.mul(pool.accRewardPerShare) / ACC_PRECISION));
        user.amount = user.amount.sub(amount);

        // Interactions
        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onTokenReward(pid, msg.sender, to, 0, user.amount);
        }

        lpToken[pid].safeTransfer(to, amount);

        emit Withdraw(msg.sender, pid, amount, to);
    }

    /// @notice Harvest proceeds for transaction sender to `to`.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param to Receiver of Token rewards.
    function harvest(uint256 pid, address to) public {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][msg.sender];
        int256 accumulatedRewards = int256(user.amount.mul(pool.accRewardPerShare) / ACC_PRECISION);
        uint256 _pendingRewards = accumulatedRewards.sub(user.rewardDebt).toUInt256();

        // Effects
        user.rewardDebt = accumulatedRewards;

        // Interactions
        if (_pendingRewards != 0) {
            rewardToken.safeTransferFrom(rewardOwner, to, _pendingRewards);
        }

        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onTokenReward(pid, msg.sender, to, _pendingRewards, user.amount);
        }

        emit Harvest(msg.sender, pid, _pendingRewards);
    }

    /// @notice Withdraw LP tokens from Staking contract and harvest proceeds for transaction sender to `to`.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to withdraw.
    /// @param to Receiver of the LP tokens and Token rewards.
    function withdrawAndHarvest(
        uint256 pid,
        uint256 amount,
        address to
    ) public {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][msg.sender];
        int256 accumulatedRewards = int256(user.amount.mul(pool.accRewardPerShare) / ACC_PRECISION);
        uint256 _pendingRewards = accumulatedRewards.sub(user.rewardDebt).toUInt256();

        // Effects
        user.rewardDebt = accumulatedRewards.sub(int256(amount.mul(pool.accRewardPerShare) / ACC_PRECISION));
        user.amount = user.amount.sub(amount);

        // Interactions
        rewardToken.safeTransferFrom(rewardOwner, to, _pendingRewards);

        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onTokenReward(pid, msg.sender, to, _pendingRewards, user.amount);
        }

        lpToken[pid].safeTransfer(to, amount);

        emit Withdraw(msg.sender, pid, amount, to);
        emit Harvest(msg.sender, pid, _pendingRewards);
    }

    /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param to Receiver of the LP tokens.
    function emergencyWithdraw(uint256 pid, address to) public {
        UserInfo storage user = userInfo[pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;

        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onTokenReward(pid, msg.sender, to, 0, 0);
        }

        // Note: transfer can fail or succeed if `amount` is zero.
        lpToken[pid].safeTransfer(to, amount);
        emit EmergencyWithdraw(msg.sender, pid, amount, to);
    }
}