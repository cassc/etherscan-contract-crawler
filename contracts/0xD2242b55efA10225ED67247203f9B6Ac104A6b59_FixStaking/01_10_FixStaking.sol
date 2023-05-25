// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./lib/UintSet.sol";

contract FixStaking is AccessControl, Pausable {
    using UintSet for Set;

    event RemovePool(uint256 poolIndex);
    event SetMinMax(uint256 minStake, uint256 maxStake);
    event SetPenDay(uint256 penaltyDuration);
    event PoolFunded(uint256 poolIndex, uint256 fundAmount);
    event ReserveWithdrawed(uint256 poolIndex);
    event Claimed(
        address user,
        uint256 depositAmountIncludePen,
        uint256 reward,
        uint256 stakerIndex,
        uint256 poolIndex
    );
    event Deposit(
        address indexed staker,
        uint256 amount,
        uint256 startTime,
        uint256 closedTime,
        uint256 indexed poolIndex,
        uint256 indexed stakerIndex
    );

    event Restake(
        address indexed staker,
        uint256 amount,
        uint256 indexed poolIndex,
        uint256 indexed stakerIndex
    );

    event Withdraw(
        address indexed staker,
        uint256 withdrawAmount,
        uint256 reward,
        uint256 mainPenaltyAmount,
        uint256 subPenaltyAmount,
        uint256 indexed poolIndex,
        uint256 indexed stakerIndex
    );

    event EmergencyWithdraw(
        address indexed staker,
        uint256 withdrawAmount,
        uint256 reward,
        uint256 mainPenaltyAmount,
        uint256 subPenaltyAmount,
        uint256 indexed poolIndex,
        uint256 indexed stakerIndex
    );
    event NewPool(
        uint256 indexed poolIndex,
        uint256 startTime,
        uint256 duration,
        uint256 apy,
        uint256 mainPenaltyRate,
        uint256 subPenaltyRate,
        uint256 lockedLimit,
        uint256 promisedReward,
        bool nftReward
    );

    struct PoolInfo {
        uint256 startTime;
        uint256 duration;
        uint256 apy;
        uint256 mainPenaltyRate;
        uint256 subPenaltyRate;
        uint256 lockedLimit;
        uint256 stakedAmount;
        uint256 reserve;
        uint256 promisedReward;
        bool nftReward;
    }

    struct StakerInfo {
        uint256 poolIndex;
        uint256 startTime;
        uint256 amount;
        uint256 lastIndex;
        uint256 pendingStart;
        uint256 reward;
        bool isFinished;
        bool pendingRequest;
    }

    mapping(address => mapping(uint256 => StakerInfo)) public stakers;
    mapping(address => uint256) public currentStakerIndex;

    // user address => pool index => total deposit amount
    mapping(address => mapping(uint256 => uint256)) public amountByPool;

    // Minumum amount the user can deposit in 1 pool.We will not look at the total amount deposited by the user into the pool.
    uint256 public minStake;

    // Maximum amount the user can deposit in 1 pool. We will look at the total amount the user deposited into the pool.
    uint256 public maxStake;

    // Time for penalized users have to wait.
    uint256 public penaltyDuration;
    // Pool Index => Pool Info
    PoolInfo[] public pools;

    IERC20 public token;
    uint256 private unlocked = 1;

    /**
     * @notice Checks if the pool exists
     */
    modifier isPoolExist(uint256 _poolIndex) {
        require(
            pools[_poolIndex].startTime > 0,
            "isPoolExist: This pool not exist"
        );
        _;
    }

    /**
     * @notice Checks if the already finish.
     */
    modifier isFinished(address _user, uint256 _stakerIndex) {
        StakerInfo memory staker = stakers[_user][_stakerIndex];
        require(
            staker.isFinished == false,
            "isFinished: This index already finished."
        );
        _;
    }

    /**
     * @notice Check if these values are valid
     */
    modifier isValid(
        uint256 _startTime,
        uint256 _duration,
        uint256 _apy
    ) {
        require(
            _startTime >= block.timestamp,
            "isValid: Start time must be greater than current time"
        );
        require(_duration != 0, "isValid: duration can not be ZERO.");
        require(_apy != 0, "isValid: Apy can not be ZERO.");

        _;
    }

    modifier lock() {
        require(unlocked == 1, "FixStaking: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor(address _token) {
        require(_token != address(0), "FixStaking: token can not be ZERO.");
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        token = IERC20(_token);
    }

    /**
     * Pauses the contract
     */
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * removes the pause
     */
    function unPause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * Sets minumum and maximum deposit amount for user
     */
    function setMinMaxStake(uint256 _minStake, uint256 _maxStake)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            _minStake >= 0,
            "setMinMaxStake: minumum amount cannot be ZERO"
        );
        require(
            _maxStake > _minStake,
            "setMinMaxStake: maximum amount cannot be lower than minimum amount"
        );

        minStake = _minStake;
        maxStake = _maxStake;
        emit SetMinMax(_minStake, _maxStake);
    }

    /**
     * Admin can set penalty time with this function
     * @param _duration penalty time in seconds
     */
    function setPenaltyDuration(uint256 _duration)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            _duration <= 5 days,
            "setPenaltyDuration: duration must be less than 5 days"
        );
        penaltyDuration = _duration;

        emit SetPenDay(_duration);
    }

    /**
     * Admin has to fund the pool for rewards. Using this function, he can finance any pool he wants.
     * @param _poolIndex the index of the pool it wants to fund.
     * @param _fundingAmount amount of funds to be added to the pool.
     */
    function fundPool(uint256 _poolIndex, uint256 _fundingAmount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        isPoolExist(_poolIndex)
    {
        require(
            token.transferFrom(msg.sender, address(this), _fundingAmount),
            "fundPool: token transfer failed."
        );

        pools[_poolIndex].reserve += _fundingAmount;

        emit PoolFunded(_poolIndex, _fundingAmount);
    }

    /**
     * Used when tokens are accidentally sent to the contract.
     * @param _token address will be recover.
     */
    function withdrawERC20(address _token, uint256 _amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            _token != address(token),
            "withdrawERC20: token can not be Reward Token."
        );
        require(
            IERC20(_token).transfer(msg.sender, _amount),
            "withdrawERC20: Transfer failed"
        );
    }

    function withdrawFunds(uint256 _poolIndex, uint256 _amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        PoolInfo memory pool = pools[_poolIndex];
        require(
            pool.reserve - pool.promisedReward >= _amount,
            "withdrawFunds: Amount should be lower that promised rewards."
        );

        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "withdrawFunds: token transfer failed."
        );
    }

    /**
     * With this function, the administrator can create an interest period.
     * Periods of 30 - 90 - 365 days can be created.
     *
     * Example:
     * -------------------------------------
     * | Apy ve altındakiler 1e16 %1 olacak şekilde ayarlanır.
     * | duration = 2592000                   => 30  Days
     * | apy = 100000000000000000             => %10 Monthly
     * | mainPenaltyRate = 100000000000000000 => %10 Main penalty rate
     * | subPenaltyRate = 50000000000000000   => %5  Sub penalty rate
     * |
     *  -------------------------------------
     *
     * @param _startTime in seconds.
     * @param _duration in seconds.
     * @param _apy 1 month rate should be 18 decimal.
     * @param _mainPenaltyRate Percentage of penalty to be deducted from the user's deposit amount.
     * @param _subPenaltyRate Percentage of penalty to be deducted from the reward won by the user.
     */
    function createPool(
        uint256 _startTime,
        uint256 _duration,
        uint256 _apy,
        uint256 _mainPenaltyRate,
        uint256 _subPenaltyRate,
        uint256 _lockedLimit,
        bool _nftReward
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        isValid(_startTime, _duration, _apy)
    {
        PoolInfo memory pool = PoolInfo(
            _startTime,
            _duration,
            _apy,
            _mainPenaltyRate,
            _subPenaltyRate,
            _lockedLimit,
            0,
            0,
            0,
            _nftReward
        );

        pools.push(pool);

        uint256 poolIndex = pools.length - 1;

        emit NewPool(
            poolIndex,
            _startTime,
            _duration,
            _apy,
            _mainPenaltyRate,
            _subPenaltyRate,
            _lockedLimit,
            pool.promisedReward,
            _nftReward
        );
    }

    /**
     * The created period can be edited by the admin.
     * @param _poolIndex the index of the pool to be edited.
     * @param _startTime pool start time in seconds.
     * @param _duration pool duration time in seconds.
     * @param _apy the new apy ratio.
     * @param _mainPenaltyRate the new main penalty rate.
     * @param _subPenaltyRate the new sub penalty rate.
     * @param _lockedLimit maximum amount of tokens that can be locked for this pool
     * @dev Reverts if the pool is not empty.
     * @dev Reverts if the pool is not created before.
     */
    function editPool(
        uint256 _poolIndex,
        uint256 _startTime,
        uint256 _duration,
        uint256 _apy,
        uint256 _mainPenaltyRate,
        uint256 _subPenaltyRate,
        uint256 _lockedLimit,
        bool _nftReward
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        isPoolExist(_poolIndex)
        isValid(_startTime, _duration, _apy)
    {
        require(
            _mainPenaltyRate == 0,
            "editPool: main penalty rate must be equal to 0"
        );
        PoolInfo storage pool = pools[_poolIndex];

        pool.startTime = _startTime;
        pool.duration = _duration;
        pool.apy = _apy;
        pool.mainPenaltyRate = _mainPenaltyRate;
        pool.subPenaltyRate = _subPenaltyRate;
        pool.lockedLimit = _lockedLimit;
        pool.nftReward = _nftReward;

        emit NewPool(
            _poolIndex,
            _startTime,
            _duration,
            _apy,
            _mainPenaltyRate,
            _subPenaltyRate,
            _lockedLimit,
            pool.promisedReward,
            _nftReward
        );
    }

    /**
     * The created period can be remove by the admin.
     * @param _poolIndex the index of the to be removed pool.
     * @dev Reverts if the pool is not empty.
     * @dev Reverts if the pool is not created before.
     */
    function removePool(uint256 _poolIndex)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        isPoolExist(_poolIndex)
    {
        if (pools[_poolIndex].reserve > 0) {
            require(
                token.transfer(msg.sender, pools[_poolIndex].reserve),
                "removePool: transfer failed."
            );
        }

        delete pools[_poolIndex];

        emit RemovePool(_poolIndex);
    }

    /**
     * Users can deposit money into any pool they want.
     * @notice Each time the user makes a deposit, the structer is kept at a different stakerIndex so it can be in more than one or the same pool at the same time.
     * @notice Users can join the same pool more than once at the same time.
     * @notice Users can join different pools at the same time.
     * @param _amount amount of money to be deposited.
     * @param _poolIndex index of the period to be entered.
     * @dev reverts if the user tries to deposit it less than the minimum amount.
     * @dev reverts if the user tries to deposit more than the maximum amount into the one pool.
     * @dev reverts if the pool does not have enough funds.
     */
    function deposit(uint256 _amount, uint256 _poolIndex)
        external
        whenNotPaused
        lock
        isPoolExist(_poolIndex)
    {
        uint256 index = currentStakerIndex[msg.sender];
        StakerInfo storage staker = stakers[msg.sender][index];
        PoolInfo storage pool = pools[_poolIndex];
        uint256 reward = calculateRew(_amount, pool.apy, pool.duration);
        uint256 totStakedAmount = pool.stakedAmount + _amount;
        pool.promisedReward += reward;
        require(
            _amount >= minStake,
            "deposit: You cannot deposit below the minimum amount."
        );

        require(
            (amountByPool[msg.sender][_poolIndex] + _amount) <= maxStake,
            "deposit: You cannot deposit, have reached the maximum deposit amount."
        );
        require(
            pool.reserve >= reward,
            "deposit: This pool has no enough reward reserve"
        );
        require(
            pool.lockedLimit >= totStakedAmount,
            "deposit: The pool has reached its maximum capacity."
        );

        require(
            block.timestamp >= pool.startTime,
            "deposit: This pool hasn't started yet."
        );

        uint256 duration = pool.duration;
        uint256 timestamp = block.timestamp;

        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "deposit: Token transfer failed."
        );

        staker.startTime = timestamp;
        staker.amount = _amount;
        staker.poolIndex = _poolIndex;
        pool.stakedAmount += _amount;

        currentStakerIndex[msg.sender] += 1;
        amountByPool[msg.sender][_poolIndex] += _amount;

        emit Deposit(
            msg.sender,
            _amount,
            timestamp,
            (timestamp + duration),
            _poolIndex,
            index
        );
    }

    /**
     * Users can exit the period they are in at any time.
     * @notice Users who are not penalized can withdraw their money directly with this function. Users who are penalized should execut the claimPending function after this process.
     * @notice If the period has not finished, they will be penalized at the rate of mainPeanltyRate from their deposit.
     * @notice If the period has not finished, they will be penalized at the rate of subPenaltyRate from their rewards.
     * @notice Penalized users will be able to collect their rewards later with the claim function.
     * @param _stakerIndex of the period want to exit.
     * @dev reverts if the user's deposit amount is ZERO
     * @dev reverts if the pool does not have enough funds to cover the reward
     */
    function withdraw(uint256 _stakerIndex)
        external
        whenNotPaused
        lock
        isFinished(msg.sender, _stakerIndex)
    {
        StakerInfo storage staker = stakers[msg.sender][_stakerIndex];
        PoolInfo storage pool = pools[staker.poolIndex];

        require(
            staker.pendingRequest == false,
            "withdraw: you have already requested claim."
        );
        require(staker.amount > 0, "withdraw: Insufficient amount.");

        uint256 closedTime = getClosedTime(msg.sender, _stakerIndex);
        uint256 duration = _getStakerDuration(closedTime, staker.startTime);
        uint256 reward = calculateRew(staker.amount, pool.apy, duration);
        // If the user tries exits before the pool end time they should be penalized
        (uint256 mainPen, uint256 subPen) = getPenalty(
            msg.sender,
            _stakerIndex
        );
        uint256 totalReward = (reward - subPen);
        uint256 totalWithdraw = (staker.amount + totalReward);

        staker.reward = totalReward;
        pool.reserve -= staker.reward;
        pool.promisedReward = pool.promisedReward <= totalReward
            ? 0
            : pool.promisedReward - totalReward;

        pool.stakedAmount -= staker.amount;
        amountByPool[msg.sender][staker.poolIndex] -= staker.amount;
        // ELSE user tries withdraw before the period end time he needs to be wait cooldown

        if (closedTime <= block.timestamp) {
            _transferAndRemove(msg.sender, totalWithdraw, _stakerIndex);
        } else {
            staker.pendingStart = block.timestamp;
            staker.pendingRequest = true;
        }

        emit Withdraw(
            msg.sender,
            totalReward,
            totalWithdraw,
            mainPen,
            subPen,
            staker.poolIndex,
            _stakerIndex
        );
    }

    /**
     * After the user has completed enough duration in the pool, he can stake to the same pool again with this function.
     * @notice The same stakerIndex is used to save gas.
     * @notice The reward he won from the pool will be added to the amount he deposited.
     */
    function restake(uint256 _stakerIndex)
        external
        whenNotPaused
        lock
        isFinished(msg.sender, _stakerIndex)
    {
        StakerInfo storage staker = stakers[msg.sender][_stakerIndex];
        PoolInfo storage pool = pools[staker.poolIndex];

        uint256 poolIndex = staker.poolIndex;
        uint256 closedTime = getClosedTime(msg.sender, _stakerIndex);

        require(staker.amount > 0, "restake: Insufficient amount.");
        require(
            staker.pendingRequest == false,
            "restake: You have already requested claim."
        );
        require(
            block.timestamp >= closedTime,
            "restake: Time has not expired."
        );

        uint256 duration = _getStakerDuration(closedTime, staker.startTime);
        uint256 reward = calculateRew(staker.amount, pool.apy, duration);
        uint256 totalDeposit = staker.amount + reward;
        uint256 promisedReward = calculateRew(
            totalDeposit,
            pool.apy,
            pool.duration
        );
        pool.promisedReward += promisedReward;
        // we are checking only reward because staker amount currently staked.
        require(
            pool.reserve >=
                calculateRew(
                    pool.stakedAmount + reward,
                    pool.apy,
                    pool.duration
                ),
            "restake: This pool has no enough reward reserve"
        );

        require(
            (amountByPool[msg.sender][poolIndex] + reward) <= maxStake,
            "restake: You cannot deposit, have reached the maximum deposit amount."
        );

        pool.stakedAmount += reward;
        staker.startTime = block.timestamp;
        staker.amount = totalDeposit;
        amountByPool[msg.sender][poolIndex] += reward;

        emit Restake(msg.sender, totalDeposit, poolIndex, _stakerIndex);
    }

    /**
     * @notice Emergency function
     * Available only when the contract is paused. Users can withdraw their inside amount without receiving the rewards.
     */
    function emergencyWithdraw(uint256 _stakerIndex)
        external
        whenPaused
        isFinished(msg.sender, _stakerIndex)
    {
        StakerInfo memory staker = stakers[msg.sender][_stakerIndex];
        PoolInfo storage pool = pools[staker.poolIndex];

        require(staker.amount > 0, "withdraw: Insufficient amount.");

        uint256 withdrawAmount = staker.amount;
        pool.stakedAmount -= withdrawAmount;
        pool.promisedReward -= calculateRew(
            withdrawAmount,
            pool.apy,
            pool.duration
        );
        amountByPool[msg.sender][staker.poolIndex] -= withdrawAmount;
        _transferAndRemove(msg.sender, withdrawAmount, _stakerIndex);
        emit EmergencyWithdraw(
            msg.sender,
            withdrawAmount,
            staker.reward,
            pool.mainPenaltyRate,
            pool.subPenaltyRate,
            staker.poolIndex,
            _stakerIndex
        );
    }

    /**
     * Users who have been penalized can withdraw their tokens with this function when the 4-day penalty period expires.
     * @param _stakerIndex of the period want to claim.
     */
    function claimPending(uint256 _stakerIndex)
        external
        whenNotPaused
        lock
        isFinished(msg.sender, _stakerIndex)
    {
        StakerInfo storage staker = stakers[msg.sender][_stakerIndex];
        PoolInfo memory pool = pools[staker.poolIndex];

        require(staker.amount > 0, "claim: You do not have a pending amount.");

        require(
            block.timestamp >= staker.pendingStart + penaltyDuration,
            "claim: Please wait your time has not been up."
        );

        uint256 mainAmount = staker.amount;
        // If a penalty rate is defined that will be deducted from the amount deposited by the user
        // Deduct this penalty from the amount deposited by the user and transfer the penalty amount to the reward reserve.
        if (pool.mainPenaltyRate > 0) {
            (uint256 mainPen, ) = getPenalty(msg.sender, _stakerIndex);
            mainAmount = mainAmount - mainPen;
            pool.reserve += mainPen;
        }

        staker.pendingRequest = false;

        // There is no need to deduct the amount from the reward earned as much as the penalty rate.
        // We already did in the withdraw function.
        uint256 totalPending = mainAmount + staker.reward;
        pool.promisedReward -= staker.reward;

        _transferAndRemove(msg.sender, totalPending, _stakerIndex);

        emit Claimed(
            msg.sender,
            mainAmount,
            staker.reward,
            _stakerIndex,
            staker.poolIndex
        );
    }

    /**
     * Returns the penalty, if any, of the user whose address and index are given.
     * @param _staker address of the person whose penalty will be calculated.
     * @param _stakerIndex user index to be calculated.
     * @return mainPenalty penalty amount, to be deducted from the deposited amount by the user.
     * @return subPenalty penalty amount, to be deducted from the reward amount.
     */
    function getPenalty(address _staker, uint256 _stakerIndex)
        public
        view
        returns (uint256 mainPenalty, uint256 subPenalty)
    {
        StakerInfo memory staker = stakers[_staker][_stakerIndex];
        PoolInfo memory pool = pools[staker.poolIndex];

        uint256 closedTime = getClosedTime(_staker, _stakerIndex);
        if (closedTime > block.timestamp) {
            uint256 duration = block.timestamp - staker.startTime;
            uint256 reward = calculateRew(staker.amount, pool.apy, duration);
            uint256 amountPen = (staker.amount * pool.mainPenaltyRate) / 1e18;
            uint256 rewardPen = (reward * pool.subPenaltyRate) / 1e18;

            return (amountPen, rewardPen);
        }
        return (0, 0);
    }

    /**
     * Calculates the current reward of the user whose address and index are given.
     * @param _amount amount of deposit.
     * @param _apy monthly rate.
     * @param _duration amount of time spent inside.
     * @return reward amount of earned by the user.
     */
    function calculateRew(
        uint256 _amount,
        uint256 _apy,
        uint256 _duration
    ) public pure returns (uint256) {
        uint256 rateToSec = (_apy * 1e36) / 30 days;
        uint256 percent = (rateToSec * _duration) / 1e18;
        return (_amount * percent) / 1e36;
    }

    /**
     * Calculates the current reward of the user whose address and index are given.
     * @param _staker address of the person whose reward will be calculated.
     * @param _stakerIndex user index to be calculated.
     * @return reward amount of earned by the user.
     * @return mainPenalty penalty amount, to be deducted from the deposited amount by the user.
     * @return subPenalty penalty amount, to be deducted from the reward amount.
     * @return closedTime user end time.
     * @return futureReward reward for completing the pool
     * @return stakerInf Information owned by the user for this index.
     */
    function stakerInfo(address _staker, uint256 _stakerIndex)
        external
        view
        returns (
            uint256 reward,
            uint256 mainPenalty,
            uint256 subPenalty,
            uint256 closedTime,
            uint256 futureReward,
            StakerInfo memory stakerInf
        )
    {
        StakerInfo memory staker = stakers[_staker][_stakerIndex];
        PoolInfo memory pool = pools[staker.poolIndex];

        closedTime = getClosedTime(_staker, _stakerIndex);
        uint256 duration = _getStakerDuration(closedTime, staker.startTime);
        reward = calculateRew(staker.amount, pool.apy, duration);
        (mainPenalty, subPenalty) = getPenalty(_staker, _stakerIndex);
        futureReward = calculateRew(staker.amount, pool.apy, pool.duration);

        return (
            reward,
            mainPenalty,
            subPenalty,
            closedTime,
            futureReward,
            staker
        );
    }

    function getClosedTime(address _staker, uint256 _stakerIndex)
        public
        view
        returns (uint256)
    {
        StakerInfo memory staker = stakers[_staker][_stakerIndex];
        PoolInfo memory pool = pools[staker.poolIndex];

        uint256 closedTime = staker.startTime + pool.duration;

        return closedTime;
    }

    /**
     * Returns the available allocation for the given pool index.
     */
    function getAvaliableAllocation(uint256 _poolIndex)
        external
        view
        returns (uint256)
    {
        PoolInfo memory pool = pools[_poolIndex];

        return pool.lockedLimit - pool.stakedAmount;
    }

    /**
     * Returns a list of all pools.
     */
    function getPoolList() external view returns (PoolInfo[] memory) {
        return pools;
    }

    /**
     * Returns the total staked amount and remaining allocation all pools.
     * @notice We are aware of the gas problem that will occur with the for loop here. This won't be a problem as we won't have more than 10-20 pools.
     */
    function getTotStakedAndAlloc()
        external
        view
        returns (uint256 totStakedAmount, uint256 totAlloc)
    {
        for (uint256 i = 0; i < pools.length; i++) {
            PoolInfo memory pool = pools[i];

            totStakedAmount += pool.stakedAmount;
            totAlloc += pool.lockedLimit - pool.stakedAmount;
        }

        return (totStakedAmount, totAlloc);
    }

    function _getStakerDuration(uint256 _closedTime, uint256 _startTime)
        private
        view
        returns (uint256)
    {
        uint256 endTime = block.timestamp > _closedTime
            ? _closedTime
            : block.timestamp;
        uint256 duration = endTime - _startTime;

        return duration;
    }

    function _transferAndRemove(
        address _user,
        uint256 _transferAmount,
        uint256 _stakerIndex
    ) private {
        StakerInfo storage staker = stakers[_user][_stakerIndex];
        require(
            token.transfer(_user, _transferAmount),
            "_transferAndRemove: transfer failed."
        );

        staker.isFinished = true;
    }
}