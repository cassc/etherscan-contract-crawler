// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;
pragma abicoder v2;

import '../libraries/SafeMath.sol';
import '../libraries/TransferHelper.sol';
import '../interfaces/ITwapLPTokenRewarder.sol';
import '../interfaces/IERC20.sol';
import '../interfaces/IIntegralToken.sol';

abstract contract TwapLPTokenRewarder is ITwapLPTokenRewarder {
    using SafeMath for uint256;
    using SafeMath for int256;
    using TransferHelper for address;

    uint256 private locked;

    uint256 internal constant ACCUMULATED_ITGR_PRECISION = 1e12;

    address public immutable itgr;
    address public owner;
    uint256 public totalAllocationPoints;
    uint256 public itgrPerSecond;
    bool public stakeDisabled;
    PoolInfo[] public pools;
    address[] public lpTokens;

    mapping(uint256 => mapping(address => UserInfo)) public users;
    mapping(address => bool) public addedLpTokens;

    constructor(address _itgr) {
        itgr = _itgr;
        owner = msg.sender;

        emit OwnerSet(msg.sender);
    }

    modifier lock() {
        require(locked == 0, 'LR06');
        locked = 1;
        _;
        locked = 0;
    }

    /**
     * @notice Set the owner of the contract.
     * @param _owner New owner of the contract.
     */
    function setOwner(address _owner) external override {
        require(msg.sender == owner, 'LR00');
        require(_owner != address(0), 'LR02');
        require(_owner != owner, 'LR01');
        owner = _owner;
        emit OwnerSet(_owner);
    }

    /**
     * @notice Set the amount of ITGR per second.
     * @param _itgrPerSecond Amount of ITGR per second.
     */
    function setItgrPerSecond(uint256 _itgrPerSecond, bool withPoolsUpdate) external override {
        require(msg.sender == owner, 'LR00');
        require(_itgrPerSecond != itgrPerSecond, 'LR01');

        if (withPoolsUpdate) {
            updateAllPools();
        }

        itgrPerSecond = _itgrPerSecond;
        emit ItgrPerSecondSet(_itgrPerSecond);
    }

    /**
     * @notice Set a flag for disabling new staking.
     * @param _stakeDisabled Flag if new staking will not be accepted.
     */
    function setStakeDisabled(bool _stakeDisabled) external override {
        require(msg.sender == owner, 'LR00');
        require(_stakeDisabled != stakeDisabled, 'LR01');
        stakeDisabled = _stakeDisabled;
        emit StakeDisabledSet(stakeDisabled);
    }

    /**
     * @notice View function to see the number of pools.
     */
    function poolCount() external view override returns (uint256 length) {
        length = pools.length;
    }

    /**
     * @notice Add a new LP pool.
     * @param token Staked LP token.
     * @param allocationPoints Allocation points of the new pool.
     * @dev Call `updatePools` or `updateAllPools` function before adding a new pool to update all active pools.
     */
    function addPool(
        address token,
        uint256 allocationPoints,
        bool withPoolsUpdate
    ) external override {
        require(msg.sender == owner, 'LR00');
        require(addedLpTokens[token] == false, 'LR69');

        if (withPoolsUpdate) {
            updateAllPools();
        }

        totalAllocationPoints = totalAllocationPoints.add(allocationPoints);
        lpTokens.push(token);
        pools.push(
            PoolInfo({
                accumulatedItgrPerShare: 0,
                allocationPoints: allocationPoints.toUint64(),
                lastRewardTimestamp: block.timestamp.toUint64()
            })
        );

        addedLpTokens[token] = true;

        emit PoolAdded(pools.length.sub(1), token, allocationPoints);
    }

    /**
     * @notice Update allocationPoints of the given LP pool.
     * @param pid ID of the LP pool.
     * @param allocationPoints New allocation points of the pool.
     * @dev Call `updatePools` or `updateAllPools` function before setting allocation points to update all active pools.
     */
    function setPoolAllocationPoints(
        uint256 pid,
        uint256 allocationPoints,
        bool withPoolsUpdate
    ) external override {
        require(msg.sender == owner, 'LR00');

        if (withPoolsUpdate) {
            updateAllPools();
        }

        totalAllocationPoints = totalAllocationPoints.sub(pools[pid].allocationPoints).add(allocationPoints);
        pools[pid].allocationPoints = allocationPoints.toUint64();

        emit PoolSet(pid, allocationPoints);
    }

    /**
     * @notice Stake LP tokens for ITGR rewards.
     * @param pid ID of the LP pool.
     * @param amount Amount of LP token to stake.
     * @param to Receiver of staked LP token `amount` profit.
     */
    function stake(
        uint256 pid,
        uint256 amount,
        address to
    ) external override lock {
        require(!stakeDisabled, 'LR70');
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = users[pid][to];

        lpTokens[pid].safeTransferFrom(msg.sender, address(this), amount);

        user.lpAmount = user.lpAmount.add(amount);
        user.rewardDebt = user.rewardDebt.add(
            (amount.mul(pool.accumulatedItgrPerShare) / ACCUMULATED_ITGR_PRECISION).toInt256()
        );

        emit Staked(msg.sender, pid, amount, to);
    }

    /**
     * @notice Remove staked LP tokens WITHOUT CLAIMING REWARDS. Using this function will NOT cause losing accrued rewards for the amount of unstaked LP token.
     * @param pid ID of the LP pool.
     * @param amount Amount of staked LP toked to unstake.
     * @param to LP tokens receiver.
     */
    function unstake(
        uint256 pid,
        uint256 amount,
        address to
    ) external override lock {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = users[pid][msg.sender];

        user.lpAmount = user.lpAmount.sub(amount);
        user.rewardDebt = user.rewardDebt.sub(
            (amount.mul(pool.accumulatedItgrPerShare) / ACCUMULATED_ITGR_PRECISION).toInt256()
        );

        lpTokens[pid].safeTransfer(to, amount);

        emit Unstaked(msg.sender, pid, amount, to);
    }

    /**
     * @notice Remove ALL staked LP tokens WITHOUT CLAIMING REWARDS. Using this function will cause losing accrued rewards.
     * @param pid ID of the LP pool.
     * @param to LP tokens receiver.
     */
    function emergencyUnstake(uint256 pid, address to) external override lock {
        UserInfo storage user = users[pid][msg.sender];
        uint256 amount = user.lpAmount;

        user.lpAmount = 0;
        user.rewardDebt = 0;

        lpTokens[pid].safeTransfer(to, amount);

        emit EmergencyUnstaked(msg.sender, pid, amount, to);
    }

    /**
     * @notice Remove staked LP token and claim ITGR rewards for a given LP token.
     * @param pid ID of the LP pool.
     * @param amount Amount of staked LP token to unstake.
     * @param to Reward and LP tokens receiver.
     */
    function unstakeAndClaim(
        uint256 pid,
        uint256 amount,
        address to
    ) external override lock {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = users[pid][msg.sender];

        int256 accumulatedItgr = (user.lpAmount.mul(pool.accumulatedItgrPerShare) / ACCUMULATED_ITGR_PRECISION)
            .toInt256();
        uint256 _claimable = uint256(accumulatedItgr.sub(user.rewardDebt));

        user.lpAmount = user.lpAmount.sub(amount);
        user.rewardDebt = accumulatedItgr.sub(
            (amount.mul(pool.accumulatedItgrPerShare) / ACCUMULATED_ITGR_PRECISION).toInt256()
        );

        if (_claimable > 0) {
            sendReward(_claimable, to);
        }
        lpTokens[pid].safeTransfer(to, amount);

        emit Unstaked(msg.sender, pid, amount, to);
        emit Claimed(msg.sender, pid, _claimable, to);
    }

    /**
     * @notice Claim ITGR reward for given LP token.
     * @param pid ID of the LP pool.
     * @param to Reward tokens receiver.
     */
    function claim(uint256 pid, address to) external override lock {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = users[pid][msg.sender];

        int256 accumulatedItgr = (user.lpAmount.mul(pool.accumulatedItgrPerShare) / ACCUMULATED_ITGR_PRECISION)
            .toInt256();
        uint256 _claimable = uint256(accumulatedItgr.sub(user.rewardDebt));

        user.rewardDebt = accumulatedItgr;

        if (_claimable > 0) {
            sendReward(_claimable, to);
        }

        emit Claimed(msg.sender, pid, _claimable, to);
    }

    /**
     * @notice View function to see claimable ITGR rewards for a user that is staking LP tokens.
     * @param pid ID of the LP pool.
     * @param userAddress User address that is staking LP tokens.
     */
    function claimable(uint256 pid, address userAddress) external view override returns (uint256 _claimable) {
        PoolInfo memory pool = pools[pid];
        UserInfo storage user = users[pid][userAddress];

        uint256 accumulatedItgrPerShare = pool.accumulatedItgrPerShare;
        uint256 lpSupply = IERC20(lpTokens[pid]).balanceOf(address(this));

        if (block.timestamp > pool.lastRewardTimestamp && lpSupply != 0) {
            uint256 time = block.timestamp.sub(pool.lastRewardTimestamp);
            uint256 itgrReward = time.mul(itgrPerSecond).mul(pool.allocationPoints).div(totalAllocationPoints);
            accumulatedItgrPerShare = accumulatedItgrPerShare.add(
                itgrReward.mul(ACCUMULATED_ITGR_PRECISION) / lpSupply
            );
        }

        _claimable = uint256(
            (user.lpAmount.mul(accumulatedItgrPerShare) / ACCUMULATED_ITGR_PRECISION).toInt256().sub(user.rewardDebt)
        );
    }

    /**
     * @notice Withdraw all ITGR tokens from the contract.
     * @param to Receiver of the ITGR tokens.
     */
    function withdraw(address to) external lock {
        require(msg.sender == owner, 'LR00');

        uint256 balance = IERC20(itgr).balanceOf(address(this));
        if (balance > 0) {
            itgr.safeTransfer(to, balance);
        }
    }

    /**
     * @notice Update reward variables of the given LP pools.
     * @param pids IDs of the LP pools to be updated.
     */
    function updatePools(uint256[] calldata pids) external override {
        uint256 pidsLength = pids.length;
        for (uint256 i; i < pidsLength; ++i) {
            updatePool(pids[i]);
        }
    }

    /**
     * @notice Update reward variables of all LP pools.
     */
    function updateAllPools() public override {
        uint256 poolLength = pools.length;
        for (uint256 i; i < poolLength; ++i) {
            updatePool(i);
        }
    }

    /**
     * @notice Update reward variables of the given LP pool.
     * @param pid ID of the LP pool.
     * @dev This function does not require a lock. Consider adding a lock in case of future modifications.
     */
    function updatePool(uint256 pid) public override returns (PoolInfo memory pool) {
        pool = pools[pid];
        if (block.timestamp > pool.lastRewardTimestamp) {
            uint256 lpSupply = IERC20(lpTokens[pid]).balanceOf(address(this));
            if (lpSupply > 0) {
                uint256 time = block.timestamp.sub(pool.lastRewardTimestamp);
                uint256 itgrReward = time.mul(itgrPerSecond).mul(pool.allocationPoints).div(totalAllocationPoints);
                pool.accumulatedItgrPerShare = pool.accumulatedItgrPerShare.add(
                    (itgrReward.mul(ACCUMULATED_ITGR_PRECISION) / lpSupply)
                );
            }
            pool.lastRewardTimestamp = block.timestamp.toUint64();
            pools[pid] = pool;

            emit PoolUpdated(pid, pool.lastRewardTimestamp, lpSupply, pool.accumulatedItgrPerShare);
        }
    }

    function sendReward(uint256 amount, address to) internal virtual;
}