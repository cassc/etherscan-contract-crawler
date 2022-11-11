// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./BoringMath.sol";
import "./IRewarder.sol";
import "./ZeroxZeroToken.sol";

/// @notice Returns a constant number of ZeroxZero tokens per block to LP providers.
/// It is the only address with minting rights for ZeroxZero.
contract ZeroxZeroStaking is Ownable {
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using SignedSafeMath for int256;
    using SafeERC20 for ZeroxZeroToken;
    using SafeERC20 for IERC20;

    /// @notice Info of each liquidity provider.
    /// `amount` LP token amount the user has provided.
    /// `rewardDebt` The amount of ZeroxZero entitled to the user.
    struct UserInfo {
        uint256 amount;
        int256 rewardDebt;
    }

    /// @notice Info of each liquidity pool.
    /// `allocPoint` The amount of allocation points assigned to the pool.
    /// Also known as the amount of ZeroxZero to distribute per block.
    struct PoolInfo {
        uint128 accZeroxZeroPerShare;
        uint64 lastRewardBlock;
        uint64 allocPoint;
    }

    /// @notice Address of ZeroxZero contract.
    ZeroxZeroToken public ZeroxZero;

    /// @notice We track balances directly rather than relying on the token contract `balanceOf`
    mapping (uint256 => uint256) public poolBalances;

    /// @notice Info of each liquidity pool.
    PoolInfo[] public poolInfo;
    /// @notice Address of the LP token for each pool.
    IERC20[] public lpToken;
    /// @notice Address of each `IRewarder` contract.
    IRewarder[] public rewarder;

    /// @notice Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    /// @dev Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    uint256 public stakingZeroxZeroPerBlock = 1e19;
    uint256 private constant ACC_ZeroxZero_PRECISION = 1e12;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event LogPoolAddition(uint256 indexed pid, uint256 allocPoint, IERC20 indexed lpToken, IRewarder indexed rewarder);
    event LogSetPool(uint256 indexed pid, uint256 allocPoint, IRewarder indexed rewarder, bool overwrite);
    event LogUpdatePool(uint256 indexed pid, uint64 lastRewardBlock, uint256 lpSupply, uint256 accZeroxZeroPerShare);

    constructor(address devWallet, address reward) {
        ZeroxZero = new ZeroxZeroToken(devWallet, address(this), msg.sender);
        if (reward != address(0)) {
          uint256 currentBalance = ZeroxZero.balanceOf(address(this));
          ZeroxZero.safeTransfer(reward, currentBalance.mul(50)/100);
        }
    }

    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /// @notice Returns the number of liquidity pools.
    function poolLength() public view returns (uint256 pools) {
        pools = poolInfo.length;
    }

    /// @notice Add a new LP to the pool. Can only be called by the owner.
    /// DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    /// @param allocPoint AP of the new pool.
    /// @param _lpToken Address of the LP ERC-20 token.
    /// @param _rewarder Address of the rewarder delegate.
    function add(uint256 allocPoint, IERC20 _lpToken, IRewarder _rewarder) public onlyOwner {
        uint256 lastRewardBlock = block.number;
        totalAllocPoint = totalAllocPoint.add(allocPoint);
        lpToken.push(_lpToken);
        rewarder.push(_rewarder);

        poolInfo.push(PoolInfo({
            allocPoint: allocPoint.to64(),
            lastRewardBlock: lastRewardBlock.to64(),
            accZeroxZeroPerShare: 0
        }));
        emit LogPoolAddition(lpToken.length.sub(1), allocPoint, _lpToken, _rewarder);
    }

    /// @notice Update the given pool's ZeroxZero allocation point and `IRewarder` contract. Can only be called by the owner.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _allocPoint New AP of the pool.
    /// @param _rewarder Address of the rewarder delegate.
    /// @param overwrite True if _rewarder should be `set`. Otherwise `_rewarder` is ignored.
    function set(uint256 _pid, uint256 _allocPoint, IRewarder _rewarder, bool overwrite) public onlyOwner {
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint.to64();
        if (overwrite) { rewarder[_pid] = _rewarder; }
        emit LogSetPool(_pid, _allocPoint, overwrite ? _rewarder : rewarder[_pid], overwrite);
    }

    /// @notice View function to see pending ZeroxZero on frontend.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _user Address of user.
    /// @return pending ZeroxZero reward for a given user.
    function pendingZeroxZero(uint256 _pid, address _user) external view returns (uint256 pending) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accZeroxZeroPerShare = pool.accZeroxZeroPerShare;
        uint256 lpSupply = poolBalances[_pid];
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 blocks = block.number.sub(pool.lastRewardBlock);
            uint256 zeroxzeroReward = blocks.mul(zeroxzeroPerBlock()).mul(pool.allocPoint) / totalAllocPoint;
            accZeroxZeroPerShare = accZeroxZeroPerShare.add(zeroxzeroReward.mul(ACC_ZeroxZero_PRECISION) / lpSupply);
        }
        pending = toUint256(int256(user.amount.mul(accZeroxZeroPerShare) / ACC_ZeroxZero_PRECISION).sub(user.rewardDebt));
    }

    /// @notice Update reward variables for all pools. Be careful of gas spending!
    /// @param pids Pool IDs of all to be updated. Make sure to update all active pools.
    function massUpdatePools(uint256[] calldata pids) external {
        uint256 len = pids.length;
        for (uint256 i = 0; i < len; ++i) {
            updatePool(pids[i]);
        }
    }

    /// @notice Calculates and returns the `amount` of ZeroxZero per block.
    function zeroxzeroPerBlock() public view returns (uint256 amount) {
        return stakingZeroxZeroPerBlock;
    }

    /// @notice Sets the `amount` of ZeroxZero per block.
    function setZeroxZeroPerBlock(uint256 amount) public onlyOwner {
        stakingZeroxZeroPerBlock = amount;
    }

    /// @notice Update reward variables of the given pool.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @return pool Returns the pool that was updated.
    function updatePool(uint256 pid) public returns (PoolInfo memory pool) {
        pool = poolInfo[pid];
        if (block.number > pool.lastRewardBlock) {
            uint256 lpSupply = poolBalances[pid];
            if (lpSupply > 0) {
                uint256 blocks = block.number.sub(pool.lastRewardBlock);
                uint256 zeroxzeroReward = blocks.mul(zeroxzeroPerBlock()).mul(pool.allocPoint) / totalAllocPoint;
                pool.accZeroxZeroPerShare = pool.accZeroxZeroPerShare.add((zeroxzeroReward.mul(ACC_ZeroxZero_PRECISION) / lpSupply).to128());
            }
            pool.lastRewardBlock = block.number.to64();
            poolInfo[pid] = pool;
            emit LogUpdatePool(pid, pool.lastRewardBlock, lpSupply, pool.accZeroxZeroPerShare);
        }
    }

    /// @notice Deposit LP tokens to liquidity pool for ZeroxZero allocation.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to deposit.
    /// @param to The receiver of `amount` deposit benefit.
    function deposit(uint256 pid, uint256 amount, address to) public {
        require(to != address(this), "Cannot deposit to staking contract");
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][to];

        // Effects
        user.amount = user.amount.add(amount);
        user.rewardDebt = user.rewardDebt.add(int256(amount.mul(pool.accZeroxZeroPerShare) / ACC_ZeroxZero_PRECISION));

        // Interactions
        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onZeroxZeroReward(pid, to, to, 0, user.amount);
        }

        lpToken[pid].safeTransferFrom(msg.sender, address(this), amount);
        poolBalances[pid] = poolBalances[pid].add(amount);

        emit Deposit(msg.sender, pid, amount, to);
    }

    /// @notice Withdraw LP tokens from liquidity pool.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to withdraw.
    /// @param to Receiver of the LP tokens.
    function withdraw(uint256 pid, uint256 amount, address to) public {
        require(to != address(this), "Cannot withdraw from staking contract");

        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][msg.sender];

        // Effects
        user.rewardDebt = user.rewardDebt.sub(int256(amount.mul(pool.accZeroxZeroPerShare) / ACC_ZeroxZero_PRECISION));
        user.amount = user.amount.sub(amount);
        poolBalances[pid] = poolBalances[pid].sub(amount);

        // Interactions
        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onZeroxZeroReward(pid, msg.sender, to, 0, user.amount);
        }

        lpToken[pid].safeTransfer(to, amount);

        emit Withdraw(msg.sender, pid, amount, to);
    }

    /// @notice Harvest proceeds for transaction sender to `to`.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param to Receiver of ZeroxZero rewards.
    function harvest(uint256 pid, address to) public {
        require(to != address(this), "Cannot harvest to staking contract");

        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][msg.sender];
        int256 accumulatedZeroxZero = int256(user.amount.mul(pool.accZeroxZeroPerShare) / ACC_ZeroxZero_PRECISION);
        uint256 rewardZeroxZero = toUint256(accumulatedZeroxZero.sub(user.rewardDebt));

        // Effects
        user.rewardDebt = accumulatedZeroxZero;

        // Interactions
        if (rewardZeroxZero != 0) {
            ZeroxZero.safeTransfer(to, rewardZeroxZero);
        }

        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onZeroxZeroReward( pid, msg.sender, to, rewardZeroxZero, user.amount);
        }

        emit Harvest(msg.sender, pid, rewardZeroxZero);
    }

    /// @notice Withdraw LP tokens from liquidity pool and harvest proceeds for transaction sender to `to`.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to withdraw.
    /// @param to Receiver of the LP tokens and ZeroxZero rewards.
    function withdrawAndHarvest(uint256 pid, uint256 amount, address to) public {
        require(to != address(this), "Cannot withdraw and harvest from staking contract");

        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][msg.sender];
        int256 accumulatedZeroxZero = int256(user.amount.mul(pool.accZeroxZeroPerShare) / ACC_ZeroxZero_PRECISION);
        uint256 rewardZeroxZero = toUint256(accumulatedZeroxZero.sub(user.rewardDebt));

        // Effects
        user.rewardDebt = accumulatedZeroxZero.sub(int256(amount.mul(pool.accZeroxZeroPerShare) / ACC_ZeroxZero_PRECISION));
        user.amount = user.amount.sub(amount);
        poolBalances[pid] = poolBalances[pid].sub(amount);

        // Interactions
        ZeroxZero.safeTransfer(to, rewardZeroxZero);

        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onZeroxZeroReward(pid, msg.sender, to, rewardZeroxZero, user.amount);
        }
        lpToken[pid].safeTransfer(to, amount);

        emit Withdraw(msg.sender, pid, amount, to);
        emit Harvest(msg.sender, pid, rewardZeroxZero);
    }

    /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param to Receiver of the LP tokens.
    function emergencyWithdraw(uint256 pid, address to) public {
        require(to != address(this), "Cannot emergency withdraw from staking contract");

        UserInfo storage user = userInfo[pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        poolBalances[pid] = poolBalances[pid].sub(amount);

        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onZeroxZeroReward(pid, msg.sender, to, 0, 0);
        }

        // Note: transfer can fail or succeed if `amount` is zero.
        lpToken[pid].safeTransfer(to, amount);
        emit EmergencyWithdraw(msg.sender, pid, amount, to);
    }
}