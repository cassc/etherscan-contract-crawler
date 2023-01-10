// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

pragma experimental ABIEncoderV2;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "openzeppelin/security/ReentrancyGuard.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";
import {IPool} from "../interfaces/IPool.sol";
import {ILPToken} from "../interfaces/ILPToken.sol";
import {IWETH} from "../interfaces/IWETH.sol";
import {ILevelStake} from "../interfaces/ILevelStake.sol";
import "../interfaces/IRewarder.sol";

/// @title LevelMaster V2
contract LevelMasterV2 is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeERC20 for IWETH;

    uint256 private constant MAX_REWARD_PER_SECOND = 100 ether;
    uint256 private constant MAX_ALLOCT_POINT = 1e6;

    /// @notice Info of each MCV2 user.
    /// `amount` LP token amount the user has provided.
    /// `rewardDebt` The amount of REWARD entitled to the user.
    struct UserInfo {
        uint256 amount;
        int256 rewardDebt;
    }

    /// @notice Info of each MCV2 pool.
    /// `allocPoint` The amount of allocation points assigned to the pool.
    /// Also known as the amount of REWARD to distribute per block.
    struct PoolInfo {
        uint128 accRewardPerShare;
        uint64 lastRewardTime;
        uint64 allocPoint;
        bool staking;
    }

    /// @notice Info of each MCV2 pool.
    PoolInfo[] public poolInfo;

    /// @notice Address of the LP token for each MCV2 pool.
    IERC20[] public lpToken;

    /// @notice Address of each `IRewarder` contract in MCV2.
    IRewarder[] public rewarder;

    IPool public immutable levelPool;
    ILevelStake public immutable levelStake;
    IWETH public immutable weth;
    IERC20 public rewardToken;

    /// @notice Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    /// @dev Tokens added
    mapping(address => bool) public addedTokens;

    /// @dev Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    uint256 public rewardPerSecond;
    uint256 private constant ACC_REWARD_PRECISION = 1e12;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event LogPoolAddition(uint256 indexed pid, uint256 allocPoint, IERC20 indexed lpToken, IRewarder indexed rewarder);
    event LogSetPool(uint256 indexed pid, uint256 allocPoint, IRewarder indexed rewarder, bool overwrite);
    event LogUpdatePool(uint256 indexed pid, uint64 lastRewardTime, uint256 lpSupply, uint256 accRewardPerShare);
    event LogRewardPerSecond(uint256 rewardPerSecond);

    constructor(address _levelPool, address _levelStake, address _weth, address _rewardToken) {
        levelPool = IPool(_levelPool);
        levelStake = ILevelStake(_levelStake);
        weth = IWETH(_weth);
        rewardToken = IERC20(_rewardToken);
    }

    /// @notice Returns the number of MCV2 pools.
    function poolLength() public view returns (uint256 pools) {
        pools = poolInfo.length;
    }

    /// @notice Add a new LP to the pool. Can only be called by the owner.
    /// DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    /// @param allocPoint AP of the new pool.
    /// @param _lpToken Address of the LP ERC-20 token.
    /// @param _staking Reward will be staked
    /// @param _rewarder Address of the rewarder delegate.
    function add(uint256 allocPoint, IERC20 _lpToken, bool _staking, IRewarder _rewarder) public onlyOwner {
        require(addedTokens[address(_lpToken)] == false, "Token already added");
        require(allocPoint <= MAX_ALLOCT_POINT, "Alloc point too high");
        totalAllocPoint = totalAllocPoint + allocPoint;
        lpToken.push(_lpToken);
        rewarder.push(_rewarder);

        poolInfo.push(
            PoolInfo({allocPoint: uint64(allocPoint), lastRewardTime: uint64(block.timestamp), accRewardPerShare: 0, staking: _staking})
        );
        addedTokens[address(_lpToken)] = true;
        emit LogPoolAddition(lpToken.length - 1, allocPoint, _lpToken, _rewarder);
    }

    /// @notice Update the given pool's REWARD allocation point and `IRewarder` contract. Can only be called by the owner.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _allocPoint New AP of the pool.
    /// @param _staking Reward will be staked
    /// @param _rewarder Address of the rewarder delegate.
    /// @param overwrite True if _rewarder should be `set`. Otherwise `_rewarder` is ignored.
    function set(uint256 _pid, uint256 _allocPoint, bool _staking, IRewarder _rewarder, bool overwrite) public onlyOwner {
        require(_allocPoint <= MAX_ALLOCT_POINT, "Alloc point too high");
        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = uint64(_allocPoint);
        poolInfo[_pid].staking = _staking;
        if (overwrite) {
            rewarder[_pid] = _rewarder;
        }
        emit LogSetPool(_pid, _allocPoint, overwrite ? _rewarder : rewarder[_pid], overwrite);
    }

    /// @notice Sets the reward per second to be distributed. Can only be called by the owner.
    /// @param _rewardPerSecond The amount of LEvEL to be distributed per second.
    function setRewardPerSecond(uint256 _rewardPerSecond) public onlyOwner {
        require(_rewardPerSecond <= MAX_REWARD_PER_SECOND, "> MAX_REWARD_PER_SECOND");
        rewardPerSecond = _rewardPerSecond;
        emit LogRewardPerSecond(_rewardPerSecond);
    }

    /// @notice View function to see pending REWARD on frontend.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _user Address of user.
    /// @return pending LEVEL reward for a given user.
    function pendingReward(uint256 _pid, address _user) external view returns (uint256 pending) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 lpSupply = lpToken[_pid].balanceOf(address(this));
        if (block.timestamp > pool.lastRewardTime && lpSupply != 0) {
            uint256 time = block.timestamp - pool.lastRewardTime;
            accRewardPerShare = accRewardPerShare
                + (time * rewardPerSecond * pool.allocPoint * ACC_REWARD_PRECISION / totalAllocPoint / lpSupply);
        }
        pending = uint256(int256(user.amount * accRewardPerShare / ACC_REWARD_PRECISION) - user.rewardDebt);
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
        if (block.timestamp > pool.lastRewardTime) {
            uint256 lpSupply = lpToken[pid].balanceOf(address(this));
            if (lpSupply != 0) {
                uint256 time = block.timestamp - pool.lastRewardTime;
                pool.accRewardPerShare = pool.accRewardPerShare
                    + uint128(time * rewardPerSecond * pool.allocPoint * ACC_REWARD_PRECISION / totalAllocPoint / lpSupply);
            }
            pool.lastRewardTime = uint64(block.timestamp);
            poolInfo[pid] = pool;
            emit LogUpdatePool(pid, pool.lastRewardTime, lpSupply, pool.accRewardPerShare);
        }
    }

    /// @notice Deposit LP tokens to MCV2 for REWARD allocation.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to deposit.
    /// @param to The receiver of `amount` deposit benefit.
    function deposit(uint256 pid, uint256 amount, address to) public {
        _deposit(pid, amount, to);
        lpToken[pid].safeTransferFrom(msg.sender, address(this), amount);
    }

    /// @notice Withdraw LP tokens from MCV2.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to withdraw.
    /// @param to Receiver of the LP tokens.
    function withdraw(uint256 pid, uint256 amount, address to) public {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][msg.sender];

        // Effects
        user.rewardDebt = user.rewardDebt - int256(amount * pool.accRewardPerShare / ACC_REWARD_PRECISION);
        user.amount = user.amount - amount;

        // Interactions
        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onReward(pid, msg.sender, to, 0, user.amount);
        }

        lpToken[pid].safeTransfer(to, amount);

        emit Withdraw(msg.sender, pid, amount, to);
    }

    /// @notice Harvest proceeds for transaction sender to `to`.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param to Receiver of REWARD rewards.
    function harvest(uint256 pid, address to) public {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][msg.sender];
        int256 accumulatedReward = int256(user.amount * pool.accRewardPerShare / ACC_REWARD_PRECISION);
        uint256 _pendingReward = uint256(accumulatedReward - user.rewardDebt);

        // Effects
        user.rewardDebt = accumulatedReward;

        // Interactions
        if (_pendingReward != 0) {
            _transferReward(to, _pendingReward, pool.staking);
        }

        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onReward(pid, msg.sender, to, _pendingReward, user.amount);
        }

        emit Harvest(msg.sender, pid, _pendingReward);
    }

    function harvestAll(address to) external {
        for (uint256 i = 0; i < poolInfo.length; i++) {
            harvest(i, to);
        }
    }

    /// @notice Withdraw LP tokens from MCV2 and harvest proceeds for transaction sender to `to`.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to withdraw.
    /// @param to Receiver of the LP tokens and REWARD rewards.
    function withdrawAndHarvest(uint256 pid, uint256 amount, address to) public {
        _withdrawAndHarvest(pid, amount, to);
        lpToken[pid].safeTransfer(to, amount);
    }

    function addLiquidity(uint256 pid, address assetToken, uint256 assetAmount, uint256 minLpAmount, address to)
        external
        nonReentrant
    {
        require(assetAmount != 0, "Invalid input");

        address tranche = address(lpToken[pid]);
        uint256 balanceLpTokenBefore = ILPToken(tranche).balanceOf(address(this));
        IERC20(assetToken).safeTransferFrom(msg.sender, address(this), assetAmount);
        IERC20(assetToken).safeIncreaseAllowance(address(levelPool), assetAmount);
        levelPool.addLiquidity(tranche, assetToken, assetAmount, minLpAmount, address(this));
        uint256 lpAmount = ILPToken(tranche).balanceOf(address(this)) - balanceLpTokenBefore;

        _deposit(pid, lpAmount, to);
    }

    function addLiquidityETH(uint256 pid, uint256 minLpAmount, address to) external payable nonReentrant {
        uint256 _amountIn = msg.value;
        require(_amountIn != 0, "Invalid input");

        address tranche = address(lpToken[pid]);
        uint256 balanceLpTokenBefore = ILPToken(tranche).balanceOf(address(this));
        weth.deposit{value: _amountIn}();
        weth.safeIncreaseAllowance(address(levelPool), _amountIn);
        levelPool.addLiquidity(tranche, address(weth), _amountIn, minLpAmount, address(this));
        uint256 lpAmount = ILPToken(tranche).balanceOf(address(this)) - balanceLpTokenBefore;

        _deposit(pid, lpAmount, to);
    }

    function removeLiquidity(uint256 pid, uint256 lpAmount, address toToken, uint256 minOut, address to)
        external
        nonReentrant
    {
        _withdrawAndHarvest(pid, lpAmount, to);
        IERC20 tranche = lpToken[pid];
        tranche.safeIncreaseAllowance(address(levelPool), lpAmount);
        levelPool.removeLiquidity(address(tranche), toToken, lpAmount, minOut, to);
    }

    function removeLiquidityETH(uint256 pid, uint256 lpAmount, uint256 minOut, address to) external nonReentrant {
        _withdrawAndHarvest(pid, lpAmount, to);

        IERC20 tranche = lpToken[pid];
        tranche.safeIncreaseAllowance(address(levelPool), lpAmount);
        uint256 balanceBefore = weth.balanceOf(address(this));
        levelPool.removeLiquidity(address(tranche), address(weth), lpAmount, minOut, address(this));
        uint256 received = weth.balanceOf(address(this)) - balanceBefore;
        weth.withdraw(received);
        _safeTransferETH(to, received);
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

    // internal
    function _deposit(uint256 pid, uint256 amount, address to) internal {
        require(amount != 0, "Invalid deposit amount");
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][to];

        // Effects
        user.amount = user.amount + amount;
        user.rewardDebt = user.rewardDebt + int256(amount * pool.accRewardPerShare / ACC_REWARD_PRECISION);

        // Interactions
        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onReward(pid, msg.sender, to, 0, user.amount);
        }
        emit Deposit(msg.sender, pid, amount, to);
    }

    function _withdrawAndHarvest(uint256 pid, uint256 amount, address to) internal {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][msg.sender];
        int256 accumulatedReward = int256(user.amount * pool.accRewardPerShare / ACC_REWARD_PRECISION);
        uint256 _pendingReward = uint256(accumulatedReward - user.rewardDebt);

        // Effects
        user.rewardDebt = accumulatedReward - int256(amount * pool.accRewardPerShare / ACC_REWARD_PRECISION);
        user.amount = user.amount - amount;

        // Interactions
        if (_pendingReward != 0) {
            _transferReward(to, _pendingReward, pool.staking);
            emit Harvest(msg.sender, pid, _pendingReward);
        }

        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onReward(pid, msg.sender, to, _pendingReward, user.amount);
        }
        emit Withdraw(msg.sender, pid, amount, to);
    }

    function _safeTransferETH(address to, uint256 amount) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success,) = to.call{value: amount}(new bytes(0));
        require(success, "ETH_TRANSFER_FAILED");
    }

    function _transferReward(address _to, uint256 _amount, bool _staking) internal {
        if (_staking) {
            levelStake.stake(_to, _amount);
        } else {
            rewardToken.safeTransfer(_to, _amount);
        }
    }

    receive() external payable {}
}