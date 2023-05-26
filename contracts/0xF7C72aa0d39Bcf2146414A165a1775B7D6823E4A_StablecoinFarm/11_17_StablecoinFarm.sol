// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { Pausable } from '../Pausable.sol';
import { BalanceManagement } from '../BalanceManagement.sol';
import { IRevenueShare } from '../interfaces/IRevenueShare.sol';

contract StablecoinFarm is Pausable, BalanceManagement {
    using SafeERC20 for IERC20;

    struct VestedBalance {
        uint256 amount;
        uint256 unlockTime;
    }

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See the explanation below.
        uint256 remainingRewardTokenAmount; // Tokens that weren't distributed for a user per pool.

        // Any point in time, the amount of reward tokens entitled to a user but pending to be distributed is:
        // pending reward = (user.amount * pool.accumulatedRewardTokenPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws Staked tokens to a pool. Here's what happens:
        //   1. The pool's `accumulatedRewardTokenPerShare` (and `lastRewardTime`) gets updated.
        //   2. A user receives the pending reward sent to his/her address.
        //   3. The user's `amount` gets updated.
        //   4. The user's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        address stakingToken; // Contract address of staked token
        uint256 stakingTokenTotalAmount; //Total amount of deposited tokens
        uint256 accumulatedRewardTokenPerShare; // Accumulated reward token per share, times 1e12. See below.
        uint32 lastRewardTime; // Last timestamp number that reward token distribution occurs.
        uint16 allocationPoint; // How many allocation points are assigned to this pool.
    }

    address public immutable rewardToken; // The reward token.

    address public ITPRevenueShare; // The penalty address of the fee ITPRevenueShare contract.
    address public LPRevenueShare; // The penalty address of the fee LPRevenueShare contract.

    uint256 public rewardTokenPerSecond; // Reward tokens vested per second.
    PoolInfo[] public poolInfo; // Info of each pool.

    mapping(address => bool) public isStakingTokenSet;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo; // Info of each user that stakes tokens.
    mapping(uint256 => mapping(address => VestedBalance[])) public userVested; // vested tokens

    uint256 public totalAllocationPoint = 0; // the sum of all allocation points in all pools.
    uint32 public immutable startTime; // the timestamp when reward token farming starts.
    uint32 public endTime; // time on which the reward calculation should end.
    uint256 public immutable vestingDuration;
    uint256 public exitEarlyUserShare = 500; // 50%
    uint256 public exitEarlyITPShare = 200; // 20%
    uint256 public exitEarlyLPShare = 300; // 30%

    // Factor to perform multiplication and division operations.
    uint256 private constant SHARE_PRECISION = 1e18;

    event Staked(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event WithdrawVesting(address indexed user, uint256 amount);
    event Vested(address indexed user, uint256 indexed pid, uint256 amount);
    event Locked(address indexed user, uint256 indexed pid, uint256 amount);
    event ExitEarly(address indexed user, uint256 amount);

    constructor(
        address _rewardToken,
        uint256 _rewardTokenPerSecond,
        uint32 _startTime,
        uint256 _vestingDuration
    ) {
        rewardToken = _rewardToken;
        rewardTokenPerSecond = _rewardTokenPerSecond;
        startTime = _startTime;
        endTime = startTime + 90 days;
        vestingDuration = _vestingDuration;
    }

    /**
     * @dev Sets a new ITP revenue share
     * @param _newRevenueShare is a new ITP revenue share address
     */
    function setITPRevenueShare(address _newRevenueShare) external onlyOwner {
        require(_newRevenueShare != address(0), 'Zero address error');
        ITPRevenueShare = _newRevenueShare;
    }

    /**
     * @dev Sets a new LP revenue share
     * @param _newRevenueShare is a new LP revenue share address
     */
    function setLPRevenueShare(address _newRevenueShare) external onlyOwner {
        require(_newRevenueShare != address(0), 'Zero address error');
        LPRevenueShare = _newRevenueShare;
    }

    /**
     * @dev Sets portions for exit early. If it needs to set 33.3%, just provide a 333 value.
     * Pay attention, the sum of all values must be 1000, which means 100%
     * @param _userPercent is a user percent
     * @param _itpPercent is an ITP share percent
     * @param _lpPercent is an LP share percent
     */
    function setPercentsShare(
        uint256 _userPercent,
        uint256 _itpPercent,
        uint256 _lpPercent
    ) external onlyOwner {
        require(
            _userPercent + _itpPercent + _lpPercent == 1000,
            'Total percentage should be 100% in total'
        );
        exitEarlyUserShare = _userPercent;
        exitEarlyITPShare = _itpPercent;
        exitEarlyLPShare = _lpPercent;
    }

    /**
     * @dev Deposit staking tokens for reward token allocation.
     * @param _pid is a pool id
     * @param _amount is a number of deposit tokens
     */
    function stake(uint256 _pid, uint256 _amount) external whenNotPaused {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        _updatePool(_pid);
        IERC20(pool.stakingToken).safeTransferFrom(msg.sender, address(this), _amount);
        user.remainingRewardTokenAmount = pendingRewardToken(_pid, msg.sender);
        user.amount += _amount;
        pool.stakingTokenTotalAmount += _amount;
        user.rewardDebt = (user.amount * pool.accumulatedRewardTokenPerShare) / SHARE_PRECISION;
        emit Staked(msg.sender, _pid, _amount);
    }

    /**
     * @dev Withdraw only staked iUSDC/iUSDT tokens
     * @param _pid is a pool id
     * @param _amount is an amount of withdrawn tokens
     */
    function withdraw(uint256 _pid, uint256 _amount) external whenNotPaused {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.amount < _amount) {
            revert('Can not withdraw this amount');
        }

        _updatePool(_pid);

        user.remainingRewardTokenAmount = pendingRewardToken(_pid, msg.sender);
        user.amount -= _amount;
        pool.stakingTokenTotalAmount -= _amount;
        user.rewardDebt = (user.amount * pool.accumulatedRewardTokenPerShare) / SHARE_PRECISION;

        IERC20(pool.stakingToken).safeTransfer(msg.sender, _amount);

        emit Withdraw(msg.sender, _pid, _amount);
    }

    /**
     * @dev Withdraw without caring about rewards. EMERGENCY ONLY.
     * @param _pid is a pool id
     */
    function emergencyWithdraw(uint256 _pid) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 userAmount = user.amount;

        pool.stakingTokenTotalAmount -= userAmount;
        user.amount = 0;
        user.rewardDebt = 0;
        user.remainingRewardTokenAmount = 0;
        IERC20(pool.stakingToken).safeTransfer(msg.sender, userAmount);
        emit EmergencyWithdraw(msg.sender, _pid, userAmount);
    }

    /**
     * @dev Add seconds to endTime parameter
     * @param _addSeconds is an additional seconds value
     */
    function changeEndTime(uint32 _addSeconds) external onlyManager {
        endTime += _addSeconds;
    }

    /**
     * @dev Changes reward token amount per second. Use this function to moderate the `lockup amount`.
     * Essentially this function changes the amount of the reward which is entitled to the user
     * for his token staking by the time the `endTime` is passed.
     * Good practice to update pools without messing up the contract.
     * @param _rewardTokenPerSecond is a new value for reward token per second
     * @param _withUpdate if set in true all pools will be updated,
     * otherwise only new rewardTokenPerSecond will be set
     */
    function setRewardTokenPerSecond(
        uint256 _rewardTokenPerSecond,
        bool _withUpdate
    ) external onlyManager {
        if (_withUpdate) {
            _massUpdatePools();
        }

        rewardTokenPerSecond = _rewardTokenPerSecond;
    }

    /**
     * @dev Add a new staking token to the pool. Can only be called by managers.
     * @param _allocPoint is an allocation point
     * @param _stakingToken is a staked token address that will be used for the new pool
     * @param _withUpdate if set in true all pools will be updated,
     * otherwise only the new pool will be added
     */
    function add(uint16 _allocPoint, address _stakingToken, bool _withUpdate) external onlyManager {
        require(!isStakingTokenSet[_stakingToken], 'Staking token was already set');
        require(poolInfo.length < 5, 'No more then 5 pools can be added');

        if (_withUpdate) {
            _massUpdatePools();
        }

        uint256 lastRewardTime = block.timestamp > startTime ? block.timestamp : startTime;
        totalAllocationPoint += _allocPoint;
        poolInfo.push(
            PoolInfo({
                stakingToken: _stakingToken,
                stakingTokenTotalAmount: 0,
                allocationPoint: _allocPoint,
                lastRewardTime: uint32(lastRewardTime),
                accumulatedRewardTokenPerShare: 0
            })
        );
        isStakingTokenSet[_stakingToken] = true;
    }

    /**
     * @dev Update the given pool's reward token allocation point. Can only be called by managers.
     * @param _pid is a pool id that exists in the list
     * @param _allocPoint is an allocation point
     * @param _withUpdate if set in true all pools will be updated,
     * otherwise only allocation data will be updated
     */
    function set(uint256 _pid, uint16 _allocPoint, bool _withUpdate) external onlyManager {
        if (_withUpdate) {
            _massUpdatePools();
        }
        totalAllocationPoint = totalAllocationPoint - poolInfo[_pid].allocationPoint + _allocPoint;
        poolInfo[_pid].allocationPoint = _allocPoint;
    }

    /**
     * @dev Update reward variables for all pools.
     */
    function massUpdatePools() external whenNotPaused {
        _massUpdatePools();
    }

    /**
     * @dev Update reward variables of the given pool to be up-to-date.
     */
    function updatePool(uint256 _pid) external whenNotPaused {
        _updatePool(_pid);
    }

    /**
     * @dev How many pools are in the contract
     */
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /**
     * @dev Vest all pending rewards. Vest tokens means that they will be locked for the
     * vestingDuration time
     * @param _pid is a pool id
     */
    function vest(uint256 _pid) external whenNotPaused {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        _updatePool(_pid);
        uint256 pending = pendingRewardToken(_pid, msg.sender);
        require(pending > 0, 'Amount of tokens can not be zero value');
        uint256 unlockTime = block.timestamp + vestingDuration;
        VestedBalance[] storage vestings = userVested[_pid][msg.sender];
        require(vestings.length <= 100, 'User can not execute vest function more than 100 times');
        vestings.push(VestedBalance({ amount: pending, unlockTime: unlockTime }));

        user.remainingRewardTokenAmount = 0;
        user.rewardDebt = (user.amount * pool.accumulatedRewardTokenPerShare) / SHARE_PRECISION;
        emit Vested(msg.sender, _pid, pending);
    }

    /**
     * @dev user can get his rewards for staked iUSDC/iUSDT if locked time has already occurred
     * @param _pid is a pool id
     */
    function withdrawVestedRewards(uint256 _pid) external {
        // withdraw only `vestedTotal` amount
        _updatePool(_pid);
        (uint256 vested, , ) = checkVestingBalances(_pid, msg.sender);

        uint256 amount;
        if (vested > 0) {
            uint256 length = userVested[_pid][msg.sender].length;
            for (uint256 i = 0; i < length; i++) {
                uint256 vestAmount = userVested[_pid][msg.sender][i].amount;
                if (userVested[_pid][msg.sender][i].unlockTime > block.timestamp) {
                    break;
                }
                amount = amount + vestAmount;
                delete userVested[_pid][msg.sender][i];
            }
        }

        if (amount > 0) {
            safeRewardTransfer(msg.sender, amount);
        } else {
            revert('Tokens are not available for now');
        }

        emit WithdrawVesting(msg.sender, amount);
    }

    /**
     * @dev The user receives only `exitEarlyUserShare` - 50% tokens by default
     * `exitEarlyITPShare` - 20% tokens by default transfers to the ITP revenue share contract
     * `exitEarlyLPShare` - 30% tokens by default transfers to the LP revenue share contract
     * @param _pid is a pool id
     */
    function exitEarly(uint256 _pid) external {
        _updatePool(_pid);
        // can withdraw 50% immediately

        (, uint256 vesting, ) = checkVestingBalances(_pid, msg.sender);
        require(vesting > 0, 'Total vesting tokens can not be zero');

        uint256 amountUser = (vesting * exitEarlyUserShare) / 1000;
        uint256 amountITP = (vesting * exitEarlyITPShare) / 1000;
        uint256 amountLP = (vesting * exitEarlyLPShare) / 1000;

        safeRewardTransfer(msg.sender, amountUser);

        // transfer penalties
        IERC20(rewardToken).safeTransfer(ITPRevenueShare, amountITP);
        IERC20(rewardToken).safeTransfer(LPRevenueShare, amountLP);

        _cleanVestingBalances(_pid, msg.sender);
        emit ExitEarly(msg.sender, amountUser);
    }

    /**
     * @dev Lock only vesting tokens to revenue share contract
     * @param _pid is a pool id
     */
    function lockVesting(uint256 _pid) external {
        _updatePool(_pid);
        (, uint256 _vesting, ) = checkVestingBalances(_pid, msg.sender);
        require(_vesting > 0, 'Total vesting tokens can not be zero');
        uint256 currentBalance = IERC20(rewardToken).balanceOf(address(this));
        if (_vesting > currentBalance) {
            revert('Not enough tokens to lock');
        }
        IERC20(rewardToken).safeIncreaseAllowance(ITPRevenueShare, _vesting);
        IRevenueShare(ITPRevenueShare).lock(_vesting, msg.sender);

        _cleanVestingBalances(_pid, msg.sender);
        emit Locked(msg.sender, _pid, _vesting);
    }

    /**
     * @dev lock pending amount of tokens to the ITPRevenueShare
     * @param _pid is a pool id
     */
    function lockPending(uint256 _pid) external {
        _updatePool(_pid);
        uint256 pending = pendingRewardToken(_pid, msg.sender);
        // check that user has any pendings
        require(pending > 0, 'Amount of tokens can not be zero value');
        uint256 currentBalance = IERC20(rewardToken).balanceOf(address(this));

        if (pending > currentBalance) {
            revert('Not enough tokens to lock');
        }

        IERC20(rewardToken).safeIncreaseAllowance(ITPRevenueShare, pending);
        IRevenueShare(ITPRevenueShare).lock(pending, msg.sender);
        UserInfo storage user = userInfo[_pid][msg.sender];
        PoolInfo storage pool = poolInfo[_pid];
        user.remainingRewardTokenAmount = 0;
        user.rewardDebt = (user.amount * pool.accumulatedRewardTokenPerShare) / SHARE_PRECISION;

        emit Locked(msg.sender, _pid, pending);
    }

    /**
     * @dev Return reward multiplier over the given _from to _to time.
     * @param _from is a from datetime in seconds
     * @param _to is a to datetime in seconds
     * @return multiplier
     */
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        _from = _from > startTime ? _from : startTime;

        if (_from > endTime || _to < startTime) {
            return 0;
        } else if (_to > endTime) {
            return endTime - _from;
        } else return _to - _from;
    }

    /**
     * @dev Check if provided token is staked token in the pool
     * @param _tokenAddress is a checked token
     * @return result true if provided token is staked token in the pool, otherwise false
     */
    function isReservedToken(address _tokenAddress) public view override returns (bool) {
        uint256 length = poolInfo.length;

        for (uint256 pid; pid < length; ++pid) {
            if (_tokenAddress == poolInfo[pid].stakingToken) {
                return true;
            }
        }

        return false;
    }

    /**
     * @dev View function to see pending reward tokens on the frontend.
     * @param _pid is a pool id
     * @param _user is a user address to check rewards
     * @return pending reward token amount
     */
    function pendingRewardToken(uint256 _pid, address _user) public view returns (uint256 pending) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        uint256 acc = pool.accumulatedRewardTokenPerShare;

        if (block.timestamp > pool.lastRewardTime && pool.stakingTokenTotalAmount != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);

            uint256 tokenReward = (multiplier * rewardTokenPerSecond * pool.allocationPoint) /
                totalAllocationPoint;
            acc += (tokenReward * SHARE_PRECISION) / pool.stakingTokenTotalAmount;
        }

        pending =
            (user.amount * acc) /
            SHARE_PRECISION -
            user.rewardDebt +
            user.remainingRewardTokenAmount;
    }

    /**
     * @dev Information on a user's total/vestedTotal/vestingTotal balances
     * @param _pid is a pool id
     * @param _user is a user address to check rewards
     * @return vestedTotal is the number of vested tokens (that are available to withdraw)
     * @return vestingTotal is the number of vesting tokens (that are not available to withdraw yet)
     * @return vestData is the list with the number of tokens and their unlock time
     */
    function checkVestingBalances(
        uint256 _pid,
        address _user
    )
        public
        view
        returns (
            uint256 vestedTotal, // available to withdraw
            uint256 vestingTotal,
            VestedBalance[] memory vestData
        )
    {
        VestedBalance[] storage vests = userVested[_pid][_user];
        uint256 index;

        for (uint256 i = 0; i < vests.length; i++) {
            if (vests[i].unlockTime > block.timestamp) {
                if (index == 0) {
                    vestData = new VestedBalance[](vests.length - i);
                }

                vestData[index] = vests[i];
                index++;
                vestingTotal += vests[i].amount;
            } else {
                vestedTotal = vestedTotal + vests[i].amount;
            }
        }
    }

    function _cleanVestingBalances(uint256 _pid, address _user) internal {
        VestedBalance[] storage vests = userVested[_pid][_user];
        for (uint256 i = 0; i < vests.length; i++) {
            if (vests[i].unlockTime > block.timestamp) {
                delete vests[i];
            }
        }
    }

    /**
     * @dev Safe reward token transfer function.
     * Revert error if not enough tokens on the smart contract
     * Just in case the pool does not have enough reward tokens.
     * @param _to is an address to transfer rewards
     * @param _amount is a number of reward tokens that will be transferred to the user
     */
    function safeRewardTransfer(address _to, uint256 _amount) private {
        uint256 rewardTokenBalance = IERC20(rewardToken).balanceOf(address(this));

        if (_amount > rewardTokenBalance) {
            revert('Not enough tokens on the smart contract');
        } else {
            IERC20(rewardToken).safeTransfer(_to, _amount);
        }
    }

    /**
     * @dev Update reward variables for all pools
     */
    function _massUpdatePools() private {
        uint256 length = poolInfo.length;

        for (uint256 pid; pid < length; ++pid) {
            _updatePool(pid);
        }
    }

    /**
     * @dev Update reward variables of the given pool to be up-to-date.
     * @param _pid is a pool id
     */
    function _updatePool(uint256 _pid) private {
        PoolInfo storage pool = poolInfo[_pid];

        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }

        if (pool.stakingTokenTotalAmount == 0) {
            pool.lastRewardTime = uint32(block.timestamp);
            return;
        }

        uint256 multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);
        uint256 rewardTokenAmount = (multiplier * rewardTokenPerSecond * pool.allocationPoint) /
            totalAllocationPoint;

        pool.accumulatedRewardTokenPerShare +=
            (rewardTokenAmount * SHARE_PRECISION) /
            pool.stakingTokenTotalAmount;
        pool.lastRewardTime = uint32(block.timestamp);
    }
}