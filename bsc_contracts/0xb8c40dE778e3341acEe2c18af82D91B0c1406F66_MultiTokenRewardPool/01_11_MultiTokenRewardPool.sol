// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20.sol";
import "SafeERC20.sol";
import "SafeMath.sol";
import "AccessControl.sol";
import "Counters.sol";
import "IEF_LiquidityContract.sol";

contract MultiTokenRewardPool is AccessControl {
    using SafeMath for uint256;
    using SafeMath for uint112;
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    Counters.Counter requestedClaimIdIncrementer;
    Counters.Counter depositSeqId;
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many  tokens the user has provided.
        // uint256 accruedCoin; // Interest accrued till date.
        uint256 claimedCoin; // Interest claimed till date
        uint256 lastAccrued; // Last date when the interest was claimed
        uint256[] depositSeqIds;
    }
    // Info for rates at different dates

    struct DepositInfo {
        address wallet;
        uint256 depositDateTime;
        uint256 stakedAmount;
        bool inactive;
        uint256 lockUpTime;
        uint256 lockUpFactor;
    }
    struct rateInfoStruct {
        uint256 timestamp;
        uint256 rate;
    }

    // Info of each pool.
    struct PoolInfo {
        address token1; // Address of investment token contract.
        address token2; // Address of investment token contract.
        bool isStarted; // if lastRewardTime has passed
        address rewardToken;
        uint256 totalStaked;
        uint256 maximumStakingAllowed;
        uint256 poolStartTime;
        uint256 poolEndTime;
        uint256 rewardsBalance;
        address lp_address;
        address treasury;
    }

    struct DepositInfoAndSeq {
        uint256 seqId;
        DepositInfo deposits;
        bool isUnlocked;
        uint256 depositInterest;
    }

    struct TotalStakeDetail {
        uint256 amount;
        uint256 interest;
        uint256 total;
        uint256 count;
    }
    //PoolId -> Start of the Day timestamp -> details
    mapping(uint256 => mapping(uint256 => TotalStakeDetail))
        public totalStakeDetails;

    // Map (date(Not a date time) => details(Amount, Interest, total, count))

    //pool-> seq -> DepositInfo
    mapping(uint256 => mapping(uint256 => DepositInfo)) public depositInfo;

    rateInfoStruct[][] public rateInfo;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // poolID=> time
    struct LockUpStruct {
        uint256 lockUpTime;
        uint256 lockUpFactor;
    }

    mapping(uint256 => LockUpStruct[]) public lockUpInfo; //struct withdrawalTime withdrawalfactor

    mapping(address => uint256[]) individual_user_array;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 indexed seqId,
        uint256 amount
    );
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event DepositReInvested(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event RewardPaid(address indexed user, uint256 amount);

    bytes32 public constant Operator = keccak256("OPERATOR_ROLE"); //op
    bytes32 public constant Transfer_Out_Operator = keccak256("TRANSFER_OUT_OPERATOR_ROLE"); //transferoutop
    bool public isInitialized;

    function initialize(address operator) public {
        require(!isInitialized, "Already Initialized");
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(Operator, operator);
        _setupRole(Transfer_Out_Operator, operator);
        isInitialized = true;
    }

    function checkRole(address account, bytes32 role) public view {
        require(hasRole(role, account), "Role Does Not Exist");
    } //req

    function giveRole(address wallet, uint256 _roleId) public {
        require(_roleId >= 0 && _roleId < 2, "Invalid roleId");
        checkRole(msg.sender, Operator);
        bytes32 _role;
        if (_roleId == 0) {
            _role = Operator;
        } else if (_roleId == 1) {
            _role = Transfer_Out_Operator;
        } //req
        grantRole(_role, wallet);
    }

    function revokeRole(address wallet, uint256 _roleId) public {
        require(_roleId >= 0 && _roleId < 2, "Invalid roleId");
        checkRole(msg.sender, Operator);
        bytes32 _role;
        if (_roleId == 0) {
            _role = Operator;
        } else if (_roleId == 1) {
            _role = Transfer_Out_Operator;
        }
        revokeRole(_role, wallet); //req
    }

    function renounceOwnership() public {
        checkRole(msg.sender, DEFAULT_ADMIN_ROLE);
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new farm to the pool. Can only be called by the owner.
    function add(
        address _token1,
        address _token2,
        address _rewardToken,
        uint256 _rate,
        uint256 _maximumStakingAllowed,
        uint256 _poolStartTime,
        uint256 _poolEndTime,
        address _lp_address,
        address _treasury
    ) public {
        checkRole(msg.sender, Operator);
        poolInfo.push(
            PoolInfo({
                token1: _token1,
                token2: _token2,
                rewardToken: _rewardToken,
                isStarted: false,
                totalStaked: 0,
                maximumStakingAllowed: _maximumStakingAllowed,
                poolStartTime: _poolStartTime,
                poolEndTime: _poolEndTime,
                rewardsBalance: 0,
                lp_address: _lp_address,
                treasury: _treasury
            })
        );
        rateInfo.push().push(
            rateInfoStruct({rate: _rate, timestamp: block.timestamp})
        );
    }

    // Update maxStaking. Can only be called by the owner.
    function setMaximumStakingAllowed(
        uint256 _pid,
        uint256 _maximumStakingAllowed
    ) external {
        checkRole(msg.sender, Operator);
        PoolInfo storage pool = poolInfo[_pid];
        pool.maximumStakingAllowed = _maximumStakingAllowed;
    }

    function setInterestRate(
        uint256 _pid,
        uint256 _date,
        uint256 _rate
    ) external {
        checkRole(msg.sender, Operator);
        require(
            _date >= poolInfo[_pid].poolStartTime,
            "Interest date can not be earlier than pool start date"
        );
        require(
            rateInfo[_pid][rateInfo[_pid].length - 1].timestamp < _date,
            "The date should be greater than the current last date of interest "
        );

        rateInfo[_pid].push(rateInfoStruct({rate: _rate, timestamp: _date}));
    }

    //      Ensure to set the dates in ascending order
    function setInterestRatePosition(
        uint256 _pid,
        uint256 _position,
        uint256 _date,
        uint256 _rate
    ) external {
        //        assert if date is less than pool start time.
        checkRole(msg.sender, Operator);
        require(
            _date >= poolInfo[_pid].poolStartTime,
            "Interest date can not be earlier than pool start date"
        );
        // If position is zero just update

        // first record
        if ((rateInfo[_pid].length > 1) && (_position == 0)) {
            require(
                _date <= rateInfo[_pid][_position + 1].timestamp,
                "The date should be in ascending order"
            );
        }

        // middle records
        if ((_position > 0) && (_position + 1 < rateInfo[_pid].length)) {
            require(
                _date >= rateInfo[_pid][_position - 1].timestamp,
                "The date should be in ascending order"
            );
            require(
                _date <= rateInfo[_pid][_position + 1].timestamp,
                "The date should be in ascending order"
            );
        } else if (
            (_position + 1 == rateInfo[_pid].length) && (_position > 0)
        ) {
            require(
                _date >= rateInfo[_pid][_position - 1].timestamp,
                "The date should be in ascending order"
            );
        }

        rateInfo[_pid][_position].timestamp = _date;
        rateInfo[_pid][_position].rate = _rate;
    }

    // Return accumulate rewards over the given _from to _to.
    function getGeneratedReward(
        uint256 _poolindex,
        uint256 _amount,
        uint256 _fromTime,
        uint256 _toTime,
        uint256 _lockUpFactor
    ) public view returns (uint256) {
        uint256 reward = 0;
        PoolInfo memory pool = poolInfo[_poolindex];

        // invalid cases
        if (
            (_fromTime >= _toTime) ||
            (_fromTime >= pool.poolEndTime) ||
            (_toTime <= pool.poolStartTime)
        ) {
            return 0;
        }

        // if from time < pool start then from time = pool start time
        if (_fromTime < pool.poolStartTime) {
            _fromTime = pool.poolStartTime;
        }
        //  if to time > pool end then to time = pool end time
        if (_toTime > pool.poolEndTime) {
            _toTime = pool.poolEndTime;
        }

        uint256 rateSums = 0;
        uint256 iFromTime = _fromTime;
        uint256 iToTime = _toTime;

        if (rateInfo[_poolindex].length == 1) {
            iFromTime = max(_fromTime, rateInfo[_poolindex][0].timestamp);
            // avoid any negative numbers
            iToTime = max(_toTime, iFromTime);
            rateSums = (iToTime - iFromTime) * rateInfo[_poolindex][0].rate;
        } else {
            // the loop start from 1 and not from zero; ith record and i-1 record are considered for processing.
            for (uint256 i = 1; i < rateInfo[_poolindex].length; i++) {
                if (
                    rateInfo[_poolindex][i - 1].timestamp <= _toTime &&
                    rateInfo[_poolindex][i].timestamp >= _fromTime
                ) {
                    if (rateInfo[_poolindex][i - 1].timestamp <= _fromTime) {
                        iFromTime = _fromTime;
                    } else {
                        iFromTime = rateInfo[_poolindex][i - 1].timestamp;
                    }
                    if (rateInfo[_poolindex][i].timestamp >= _toTime) {
                        iToTime = _toTime;
                    } else {
                        iToTime = rateInfo[_poolindex][i].timestamp;
                    }
                    rateSums +=
                        (iToTime - iFromTime) *
                        rateInfo[_poolindex][i - 1].rate;
                }

                // Process last block
                if (i == (rateInfo[_poolindex].length - 1)) {
                    if (rateInfo[_poolindex][i].timestamp <= _fromTime) {
                        iFromTime = _fromTime;
                    } else {
                        iFromTime = rateInfo[_poolindex][i].timestamp;
                    }
                    if (rateInfo[_poolindex][i].timestamp >= _toTime) {
                        iToTime = rateInfo[_poolindex][i].timestamp;
                    } else {
                        iToTime = _toTime;
                    }

                    rateSums +=
                        (iToTime - iFromTime) *
                        rateInfo[_poolindex][i].rate;
                }
            }
        }
        reward = reward.add(
            ((rateSums.mul(_amount)).div(10**18)).mul(_lockUpFactor)
        );
        // reward = reward.add(rateSums.mul(_amount));

        return reward.div(10**18);
    }

    function pendingShare(uint256 _pid, address _user)
        public
        view
        returns (uint256)
    {
        UserInfo memory user = userInfo[_pid][_user];
        uint256 pendings = 0;
        for (uint256 h = 0; h < user.depositSeqIds.length; h++) {
            DepositInfo memory getDeposit = depositInfo[_pid][
                user.depositSeqIds[h]
            ];
            uint256 timeStamp = 0;
            if (
                block.timestamp <=
                getDeposit.depositDateTime.add(getDeposit.lockUpTime)
            ) {
                timeStamp = block.timestamp;
            } else {
                timeStamp = getDeposit.depositDateTime.add(
                    getDeposit.lockUpTime
                );
            }
            pendings = pendings.add(
                getGeneratedReward(
                    _pid,
                    getDeposit.stakedAmount,
                    getDeposit.depositDateTime,
                    timeStamp,
                    getDeposit.lockUpFactor
                )
            );
        }

        if (pendings > 0) {
            pendings = (pendings.mul(getExchangeRate(_pid))).div(10**18);
        }

        return pendings;
    }

    // Deposit LP tokens.
    function deposit(
        uint256 _pid,
        uint256 _amount,
        uint256 _lockUpTime
    ) external {
        depositInternal(_pid, _amount, _lockUpTime, false);
    }

    function reInvest(uint256 _pid, uint256 _seqId) external {
        UserInfo storage user = userInfo[_pid][msg.sender];
        (uint256 depositIndex, bool isThere) = getRemoveIndex(
            _seqId,
            user.depositSeqIds
        );
        require(isThere, "Deposit Invalid");
        DepositInfo storage _deposit = depositInfo[_pid][_seqId];
        require(
            block.timestamp >=
                _deposit.depositDateTime.add(_deposit.lockUpTime),
            "Lockup time is not yet over!"
        );
        _deposit.inactive = true;
        user.depositSeqIds[depositIndex] = user.depositSeqIds[
            user.depositSeqIds.length - 1
        ];
        user.depositSeqIds.pop();
        uint256 _pending = getGeneratedReward(
            _pid,
            _deposit.stakedAmount,
            _deposit.depositDateTime,
            _deposit.depositDateTime.add(_deposit.lockUpTime),
            _deposit.lockUpFactor
        );

        user.lastAccrued = block.timestamp;

        if (_pending > 0) {
            _pending = (_pending.mul(getExchangeRate(_pid))).div(10**18);
            user.claimedCoin += _pending;
        }

        //  Making one entry for the TotalStakeDetails By Day
        uint256 full_interest = getGeneratedReward(
            _pid,
            _deposit.stakedAmount,
            _deposit.depositDateTime,
            _deposit.depositDateTime.add(_deposit.lockUpTime),
            _deposit.lockUpFactor
        );

        uint256 _stakeEndTimeStamp = getFutureDateStartTimeStamp(
            _deposit.depositDateTime.add(_deposit.lockUpTime)
        );

        updateTotalStakeDetails(
            _pid,
            _stakeEndTimeStamp,
            _deposit.stakedAmount,
            full_interest,
            false
        );

        depositInternal(_pid, _deposit.stakedAmount, _deposit.lockUpTime, true);

        if (_pending > 0) {
            safeECoinTransfer(_pid, msg.sender, _pending);
            emit RewardPaid(msg.sender, _pending);
        }
        emit DepositReInvested(msg.sender, _pid, _deposit.stakedAmount);
    }

    function depositInternal(
        uint256 _pid,
        uint256 _amount,
        uint256 _lockUpTime,
        bool isInternal
    ) internal {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        require(
            block.timestamp >= pool.poolStartTime,
            "Pool has not started yet!"
        );
        require(
            user.amount + _amount <= pool.maximumStakingAllowed,
            "Maximum staking limit reached"
        );
        uint256 _lockUpFactor = getlockUpFactor(_pid, _lockUpTime);
        require(_lockUpFactor > 0, "Invalid LockUp Factor");
        uint256 seqId = depositSeqId.current();

        depositInfo[_pid][seqId] = DepositInfo({
            wallet: msg.sender,
            depositDateTime: block.timestamp,
            stakedAmount: _amount,
            inactive: false,
            lockUpTime: _lockUpTime,
            lockUpFactor: _lockUpFactor
        });
        if (_amount > 0) {
            user.depositSeqIds.push(seqId);
            //Making one entry for the TotalStakeDetails for Future Date
            uint256 full_interest = getGeneratedReward(
                _pid,
                _amount,
                block.timestamp,
                block.timestamp.add(_lockUpTime),
                _lockUpFactor
            );

            uint256 _stakeEndTimeStamp = getFutureDateStartTimeStamp(
                block.timestamp.add(_lockUpTime)
            );
            updateTotalStakeDetails(
                _pid,
                _stakeEndTimeStamp,
                _amount,
                full_interest,
                true
            );

            if (!isInternal) {
                user.amount = user.amount.add(_amount);
                pool.totalStaked = pool.totalStaked.add(_amount);

                IERC20(pool.token1).safeTransferFrom(
                    _sender,
                    pool.treasury,
                    _amount
                );
                IERC20(pool.token2).safeTransferFrom(
                    _sender,
                    pool.treasury,
                    _amount
                );
            }
        }
        depositSeqId.increment();
        if (!isInternal) {
            emit Deposit(_sender, _pid, _amount);
        }
    }

    function getlockUpFactor(uint256 _pid, uint256 _lockUpTime)
        internal
        view
        returns (uint256)
    {
        uint256 lockUpFactorValue;
        LockUpStruct[] memory _lockUpInfo = lockUpInfo[_pid];
        for (uint256 i; i < _lockUpInfo.length; i++) {
            if (_lockUpInfo[i].lockUpTime == _lockUpTime) {
                lockUpFactorValue = _lockUpInfo[i].lockUpFactor;
                break;
            } else {
                lockUpFactorValue = 0;
            }
        }
        return lockUpFactorValue;
    }

    function addLockUpInfo(
        uint256 _pid,
        uint256[] memory _lockUpTime,
        uint256[] memory _lockUpFactor
    ) public {
        checkRole(msg.sender, Operator);
        for (uint256 i; i < _lockUpTime.length; i++) {
            lockUpInfo[_pid].push(
                LockUpStruct({
                    lockUpTime: _lockUpTime[i],
                    lockUpFactor: _lockUpFactor[i]
                })
            );
        }
    }

    function updateLockUpInfo(
        uint256 _pid,
        uint256 _lockUpTime,
        uint256 _lockUpFactor
    ) public {
        checkRole(msg.sender, Operator);
        lockUpInfo[_pid].push(
            LockUpStruct({lockUpTime: _lockUpTime, lockUpFactor: _lockUpFactor})
        );
    }

    function updateLockUpInfoByPosition(
        uint256 _pid,
        uint256 _position,
        uint256 _lockUpTime,
        uint256 _lockUpFactor
    ) public {
        checkRole(msg.sender, Operator);
        lockUpInfo[_pid][_position] = LockUpStruct({
            lockUpTime: _lockUpTime,
            lockUpFactor: _lockUpFactor
        });
    }

    function getLockUpInfo(uint256 _pid)
        public
        view
        returns (LockUpStruct[] memory)
    {
        return lockUpInfo[_pid];
    }

    function getRemoveIndex(
        uint256 _sequenceID,
        uint256[] memory depositSequences
    ) internal pure returns (uint256, bool) {
        for (uint256 i = 0; i < depositSequences.length; i++) {
            if (_sequenceID == depositSequences[i]) {
                return (i, true);
            }
        }
        return (0, false);
    }

    function withdraw(uint256 _pid, uint256 _seqId) public {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];

        (uint256 depositIndex, bool isThere) = getRemoveIndex(
            _seqId,
            user.depositSeqIds
        );
        require(isThere, "Deposit Invalid");

        DepositInfo storage getDeposit = depositInfo[_pid][_seqId];
        require(user.amount >= getDeposit.stakedAmount, "Invalid withdraw");
        require(
            block.timestamp >=
                getDeposit.depositDateTime.add(getDeposit.lockUpTime),
            "Lockup time is not yet over!"
        );

        uint256 _amount = getDeposit.stakedAmount;

        uint256 _pending = getGeneratedReward(
            _pid,
            getDeposit.stakedAmount,
            getDeposit.depositDateTime,
            getDeposit.depositDateTime.add(getDeposit.lockUpTime),
            getDeposit.lockUpFactor
        );

        pool.totalStaked = pool.totalStaked.sub(_amount);

        //Making one entry for the TotalStakeDetails By Day
        uint256 full_interest = getGeneratedReward(
            _pid,
            _amount,
            getDeposit.depositDateTime,
            getDeposit.depositDateTime.add(getDeposit.lockUpTime),
            getDeposit.lockUpFactor
        );

        uint256 _stakeEndTimeStamp = getFutureDateStartTimeStamp(
            getDeposit.depositDateTime.add(getDeposit.lockUpTime)
        );

        updateTotalStakeDetails(
            _pid,
            _stakeEndTimeStamp,
            _amount,
            full_interest,
            false
        );

        user.lastAccrued = block.timestamp;
        user.amount = user.amount.sub(_amount);

        if (_pending > 0) {
            _pending = (_pending.mul(getExchangeRate(_pid))).div(10**18);
            user.claimedCoin += _pending;
        }

        getDeposit.inactive = true;

        user.depositSeqIds[depositIndex] = user.depositSeqIds[
            user.depositSeqIds.length - 1
        ];

        user.depositSeqIds.pop();

        if (_pending > 0) {
            safeECoinTransfer(_pid, _sender, _pending);
            emit RewardPaid(_sender, _pending);
        }
        if (_amount > 0) {
            IERC20(pool.token1).safeTransfer(_sender, _amount);
            IERC20(pool.token2).safeTransfer(_sender, _amount);
        }

        emit Withdraw(_sender, _pid, _seqId, _amount);
    }

    function updateTotalStakeDetails(
        uint256 _pid,
        uint256 _stakeEndTimeStamp,
        uint256 _amount,
        uint256 full_interest,
        bool isAdd
    ) internal {
        TotalStakeDetail memory currentStakes = totalStakeDetails[_pid][
            _stakeEndTimeStamp
        ];
        
        if (isAdd) {
            totalStakeDetails[_pid][_stakeEndTimeStamp] = TotalStakeDetail({
                amount: currentStakes.amount.add(_amount),
                interest: currentStakes.interest.add(full_interest),
                total: currentStakes.total.add(_amount.add(full_interest)),
                count: currentStakes.count + 1
            });
        } else {
            if(currentStakes.amount >= _amount){
                totalStakeDetails[_pid][_stakeEndTimeStamp] = TotalStakeDetail({
                    amount: currentStakes.amount.sub(_amount),
                    interest: currentStakes.interest.sub(full_interest),
                    total: currentStakes.total.sub(_amount.add(full_interest)),
                    count: currentStakes.count - 1
                });
            }
        }
    }

    // Safe SMiner transfer function, just in case if rounding error causes pool to not have enough SMiner.
    function safeECoinTransfer(
        uint256 _pid,
        address _to,
        uint256 _amount
    ) internal {
        PoolInfo storage _pool = poolInfo[_pid];
        require(
            _pool.rewardsBalance >= _amount,
            "Insufficient rewards balance, ask dev to add more miner to the gen pool"
        );

        IERC20 rewardCoin = IERC20(poolInfo[_pid].rewardToken);

        uint256 _e_CoinBal = rewardCoin.balanceOf(address(this));

        if (_e_CoinBal > 0) {
            if (_amount > _e_CoinBal) {
                _pool.rewardsBalance -= _e_CoinBal;
                rewardCoin.safeTransfer(_to, _e_CoinBal);
            } else {
                _pool.rewardsBalance -= _amount;
                rewardCoin.safeTransfer(_to, _amount);
            }
        }
    }

    // @notice Sets the pool end time to extend the gen pools if required.
    function setPoolEndTime(uint256 _pid, uint256 _pool_end_time) external {
        checkRole(msg.sender, Operator);
        poolInfo[_pid].poolEndTime = _pool_end_time;
    }

    function setPoolStartTime(uint256 _pid, uint256 _pool_start_time) external {
        checkRole(msg.sender, Operator);
        poolInfo[_pid].poolStartTime = _pool_start_time;
    }

    // @notice imp. only use this function to replenish rewards
    function replenishReward(uint256 _pid, uint256 _value) external {
        checkRole(msg.sender, Operator);
        require(_value > 0, "replenish value must be greater than 0");
        IERC20(poolInfo[_pid].rewardToken).safeTransferFrom(
            msg.sender,
            address(this),
            _value
        );
        poolInfo[_pid].rewardsBalance += _value;
    }

    // @notice imp. only use this function to replenish rewards
    function replenishDepositTokens(uint256 _pid, uint256 _value) external {
        checkRole(msg.sender, Operator);
        require(_value > 0, "replenish value must be greater than 0");
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        IERC20(pool.token1).safeTransferFrom(_sender, address(this), _value);
        IERC20(pool.token2).safeTransferFrom(_sender, address(this), _value);
    }

    function transferOutECoin(
        uint256 _pid,
        address _to,
        uint256 _value
    ) external {
        checkRole(msg.sender, Transfer_Out_Operator);
        PoolInfo storage pool = poolInfo[_pid];
        require(
            _value <= pool.rewardsBalance,
            "Trying to transfer out more miner than available"
        );
        pool.rewardsBalance -= _value;
        IERC20(pool.rewardToken).safeTransfer(_to, _value);
    }

    function transferOutStakes(
        address _token,
        address _to,
        uint256 _value
    ) external {
        checkRole(msg.sender, Transfer_Out_Operator);
        require(
            _value <= IERC20(_token).balanceOf(address(this)),
            "Trying to transfer out more stakes than available"
        );

        IERC20(_token).safeTransfer(_to, _value);
    }

    // @notice sets a pool's isStarted to true and increments total allocated points
    //function startPool(uint256 _pid) external onlyOperator { [RP] compilation error
    function startPool(uint256 _pid) public {
        checkRole(msg.sender, Operator);
        PoolInfo storage pool = poolInfo[_pid];
        if (!pool.isStarted) {
            pool.isStarted = true;
        }
    }

    // @notice calls startPool for all pools
    function startAllPools() external {
        checkRole(msg.sender, Operator);
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            startPool(pid);
        }
    }

    // View function to see rewards balance.
    function getRewardsBalance(uint256 _pid) external view returns (uint256) {
        return poolInfo[_pid].rewardsBalance;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function getLatestRate(uint256 _pid) external view returns (uint256) {
        return rateInfo[_pid][rateInfo[_pid].length - 1].rate;
    }

    function fetchDepositSeqList(uint256 _poolID, address _sender)
        external
        view
        returns (uint256[] memory)
    {
        return userInfo[_poolID][_sender].depositSeqIds;
    }

    function fetchDepositsInfo(uint256 _poolID, address _sender)
        external
        view
        returns (DepositInfoAndSeq[] memory)
    {
        uint256[] memory depSeqIds = userInfo[_poolID][_sender].depositSeqIds;
        DepositInfoAndSeq[] memory user_deposits = new DepositInfoAndSeq[](
            depSeqIds.length
        );
        for (uint256 i = 0; i < depSeqIds.length; i++) {
            DepositInfo memory getDeposit = depositInfo[_poolID][depSeqIds[i]];

            if (
                block.timestamp <=
                getDeposit.depositDateTime.add(getDeposit.lockUpTime)
            ) {
                uint256 pendings = getGeneratedReward(
                    _poolID,
                    getDeposit.stakedAmount,
                    getDeposit.depositDateTime,
                    block.timestamp,
                    getDeposit.lockUpFactor
                );
                if (pendings > 0) {
                    pendings = (pendings.mul(getExchangeRate(_poolID))).div(
                        10**18
                    );
                }
                user_deposits[i] = DepositInfoAndSeq({
                    seqId: depSeqIds[i],
                    deposits: getDeposit,
                    isUnlocked: false,
                    depositInterest: pendings
                });
            } else {
                uint256 pendings = getGeneratedReward(
                    _poolID,
                    getDeposit.stakedAmount,
                    getDeposit.depositDateTime,
                    getDeposit.depositDateTime.add(getDeposit.lockUpTime),
                    getDeposit.lockUpFactor
                );
                if (pendings > 0) {
                    pendings = (pendings.mul(getExchangeRate(_poolID))).div(
                        10**18
                    );
                }
                user_deposits[i] = DepositInfoAndSeq({
                    seqId: depSeqIds[i],
                    deposits: getDeposit,
                    isUnlocked: true,
                    depositInterest: pendings
                });
            }
        }
        return (user_deposits);
    }

    function getExchangeRate(uint256 _pid) public view returns (uint256) {
        PoolInfo memory _pool = poolInfo[_pid];
        IEF_LiquidityContract _iLiquidity = IEF_LiquidityContract(_pool.lp_address);

        (
            uint256 reserve0,
            uint256 reserve1,
            uint256 blockTimestampLast
        ) = _iLiquidity.getReserves();
        uint256 diff = reserve0.mul(10**18).div(reserve1);
        return diff;
    }

    function setTreasury(uint256 _pid, address _treasury) external {
        checkRole(msg.sender, Operator);
        poolInfo[_pid].treasury = _treasury;
    }

    function setLPaddress(uint256 _pid, address _lpaddress) external {
        checkRole(msg.sender, Operator);
        poolInfo[_pid].lp_address = _lpaddress;
    }

    function getTodayStartTimeStamp() public view returns (uint256) {
        return (block.timestamp - (block.timestamp % 86400));
    }

    function getFutureDateStartTimeStamp(uint256 _timestamp)
        public
        pure
        returns (uint256)
    {
        return (_timestamp - (_timestamp % 86400));
    }

    function directUpdateTotalStakeDetails(
        uint256 _pid,
        uint256 _stakeEndTimeStamp,
        uint256 _amount,
        uint256 _interest,
        uint256 _count
    ) external {
        checkRole(msg.sender, Operator);
        totalStakeDetails[_pid][_stakeEndTimeStamp] = TotalStakeDetail({
            amount: _amount,
            interest: _interest,
            total: _amount.add(_interest),
            count: _count
        });
    }
}