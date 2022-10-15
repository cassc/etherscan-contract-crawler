// SPDX-License-Identifier: MIT
// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "IERC20.sol";
import "SafeERC20.sol";
import "SafeMath.sol";

contract PreGenesisRewardPoolFixedYield {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // governance
    address public operator;
    address public transferOutOperator;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many  tokens the user has provided.
        uint256 accruedCoin; // Interest accrued till date.
        uint256 claimedCoin; // Interest claimed till date
        uint256 lastAccrued; // Last date when the interest was claimed
    }
    // Info for rates at different dates
    struct rateInfoStruct {
        uint256 timestamp;
        uint256 rate;
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 token; // Address of investment token contract.
        bool isStarted; // if lastRewardTime has passed
        uint256 maximumStakingAllowed;
    }

    rateInfoStruct[][] public rateInfo;

    IERC20 public e_Coin;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    //    uint256 public totalAllocPoint = 0;

    // The time when miner mining starts.
    uint256 public poolStartTime;

    // The time when miner mining ends.
    uint256 public poolEndTime;

    //    uint256 public s_minerPerSecond = 1;//0.000694 ether; // 600/(10*24*60*60)
    uint256 public runningTime = 10 days; // 10 days

    uint256 public rewardsBalance = 0;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardPaid(address indexed user, uint256 amount);

    constructor(
        address _e_Coin,
        uint256 _poolStartTime
    ) public {
        require(block.timestamp < _poolStartTime, "late");
        if (_e_Coin != address(0)) e_Coin = IERC20(_e_Coin);
        poolStartTime = _poolStartTime;
        poolEndTime = poolStartTime + runningTime;
        operator = msg.sender;
        transferOutOperator = msg.sender;
    }

    modifier onlyOperator() {
        require(operator == msg.sender, "MinerRewardPool: caller is not the operator");
        _;
    }

    modifier onlyTransferOutOperator() {
        require(transferOutOperator == msg.sender, "MinerRewardPool: caller is not the transfer out operator");
        _;
    }

    function checkPoolDuplicate(IERC20 _token) internal view {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            require(poolInfo[pid].token != _token, "MinerRewardPool: existing pool?");
        }
    }

    function poolLength() public view returns (uint256){
        return poolInfo.length;
    }

    // Add a new farm to the pool. Can only be called by the owner.
    function add(
        IERC20 _token,
        bool _withUpdate,
        uint256 _rate,
        uint256 _maximumStakingAllowed
    ) public onlyOperator {
        checkPoolDuplicate(_token);
        poolInfo.push(PoolInfo({
        token : _token,
        isStarted : false,
        maximumStakingAllowed : _maximumStakingAllowed
        }));
        rateInfo.push().push(rateInfoStruct({
        rate : _rate,
        timestamp : block.timestamp
        }));
    }

    // Update maxStaking. Can only be called by the owner.
    function setMaximumStakingAllowed(uint256 _pid, uint256 _maximumStakingAllowed) external onlyOperator {
        PoolInfo storage pool = poolInfo[_pid];
        pool.maximumStakingAllowed = _maximumStakingAllowed;
    }

    function setInterestRate(uint256 _pid, uint256 _date, uint256 _rate) external onlyOperator {

        require(_date >= poolStartTime, "Interest date can not be earlier than pool start date");
        require ( rateInfo[_pid][rateInfo[_pid].length-1].timestamp < _date, "The date should be greater than the current last date of interest ");

        rateInfo[_pid].push(rateInfoStruct({
        rate : _rate,
        timestamp : _date
        }));
    }
    //      Ensure to set the dates in ascending order
    function setInterestRatePosition(uint256 _pid, uint256 _position, uint256 _date, uint256 _rate) external onlyOperator {
        //        assert if date is less than pool start time.
        require(_date >= poolStartTime, "Interest date can not be earlier than pool start date");
        // If position is zero just update

        // first record
        if ((rateInfo[_pid].length > 1) && (_position == 0))
        {
            require(_date <= rateInfo[_pid][_position + 1].timestamp, "The date should be in ascending order");
        }


        // middle records
        if ((_position > 0) && (_position + 1 < rateInfo[_pid].length))
        {
            require(_date >= rateInfo[_pid][_position - 1].timestamp, "The date should be in ascending order");
            require(_date <= rateInfo[_pid][_position + 1].timestamp, "The date should be in ascending order");

        }
        else if ((_position + 1 == rateInfo[_pid].length) && (_position > 0))
        {
            require(_date >= rateInfo[_pid][_position - 1].timestamp, "The date should be in ascending order");
        }

        rateInfo[_pid][_position].timestamp = _date;
        rateInfo[_pid][_position].rate = _rate;

    }

    // Return accumulate rewards over the given _from to _to block.
    function getGeneratedReward(uint _poolindex, uint _amount, uint256 _fromTime, uint256 _toTime) public view returns (uint256) {

        uint256 reward = 0;
        // invalid cases
        if ((_fromTime >= _toTime) || (_fromTime >= poolEndTime) || (_toTime <= poolStartTime)) {
            return 0;
        }

        // if from time < pool start then from time = pool start time
        if (_fromTime < poolStartTime) {
            _fromTime = poolStartTime;
        }
        //  if to time > pool end then to time = pool end time
        if (_toTime > poolEndTime) {
            _toTime = poolEndTime;
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
                if (rateInfo[_poolindex][i - 1].timestamp <= _toTime && rateInfo[_poolindex][i].timestamp >= _fromTime) {
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
                    rateSums += (iToTime - iFromTime) * rateInfo[_poolindex][i - 1].rate;
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

                    rateSums += (iToTime - iFromTime) * rateInfo[_poolindex][i].rate;
                }
            }
        }
        reward = (rateSums * _amount);
        reward =reward /(1000000000000000000);
        return reward;
    }

    // View function to see pending SMiner on frontend.
    function pendingShare(uint256 _pid, address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_pid][_user];
        return getGeneratedReward(_pid, user.amount, user.lastAccrued, block.timestamp);
    }

    // Deposit LP tokens.
    function deposit(uint256 _pid, uint256 _amount) external {
        require(block.timestamp >= poolStartTime, "Pool has not started yet!");
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        require(user.amount + _amount <= pool.maximumStakingAllowed, "Maximum staking limit reached");

        if (user.amount > 0) {
            uint256 _pending = getGeneratedReward(_pid, user.amount, user.lastAccrued, block.timestamp);
            if (_pending > 0) {
                user.accruedCoin += _pending;
                user.lastAccrued = block.timestamp;
            }
        }
        if (_amount > 0) {
            pool.token.safeTransferFrom(_sender, address(this), _amount);
            user.amount = user.amount.add(_amount);
            user.lastAccrued = block.timestamp;
        }
        emit Deposit(_sender, _pid, _amount);
    }

    // Withdraw  tokens.
    function withdraw(uint256 _pid, uint256 _amount) external {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        require(user.amount >= _amount, "Withdrawal: Invalid");
        uint256 _pending = getGeneratedReward(_pid, user.amount, user.lastAccrued, block.timestamp);
        user.accruedCoin += _pending;
        user.lastAccrued = block.timestamp;
        _pending = (user.accruedCoin).sub(user.claimedCoin);
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
        }
        if (_pending > 0) {
            user.claimedCoin += _pending;
        }
        if (_pending > 0) {
            safeECoinTransfer(_sender, _pending);
            emit RewardPaid(_sender, _pending);
        }
        if (_amount > 0) {
            pool.token.safeTransfer(_sender, _amount);
        }
        emit Withdraw(_sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 _amount = user.amount;
        user.amount = 0;
        pool.token.safeTransfer(msg.sender, _amount);
        emit EmergencyWithdraw(msg.sender, _pid, _amount);
    }

    // Safe SMiner transfer function, just in case if rounding error causes pool to not have enough SMiner.
    function safeECoinTransfer(address _to, uint256 _amount) internal {

        require(rewardsBalance >= _amount, "Insufficient rewards balance, ask dev to add more miner to the gen pool");
        uint256 _e_CoinBal = e_Coin.balanceOf(address(this));

        if (_e_CoinBal > 0) {
            if (_amount > _e_CoinBal) {
                rewardsBalance -= _e_CoinBal;
                e_Coin.safeTransfer(_to, _e_CoinBal);
            } else {
                rewardsBalance -= _amount;
                e_Coin.safeTransfer(_to, _amount);
            }
        }
    }

    function setOperator(address _operator) external onlyOperator {
        operator = _operator;
    }

    function setTransferOutOperator(address _operator) external onlyTransferOutOperator {
        transferOutOperator = _operator;
    }

    // @notice Sets the pool end time to extend the gen pools if required.
    function setPoolEndTime(uint256 _pool_end_time) external onlyOperator {
        poolEndTime = _pool_end_time;
    }

    function setPoolStartTime(uint256 _pool_start_time) external onlyOperator {
        poolStartTime = _pool_start_time;
    }

    // @notice imp. only use this function to replenish rewards
    function replenishReward(uint256 _value) external onlyOperator {
        require(_value > 0, "replenish value must be greater than 0");
        IERC20(e_Coin).safeTransferFrom(msg.sender, address(this), _value);
        rewardsBalance += _value;
    }


    // @notice can only transfer out the rewards balance and not user fund.
    function transferOutECoin(address _to, uint256 _value) external onlyTransferOutOperator {
        require(_value <= rewardsBalance, "Trying to transfer out more miner than available");
        rewardsBalance -= _value;
        IERC20(e_Coin).safeTransfer(_to, _value);
    }

    // @notice sets a pool's isStarted to true and increments total allocated points
    //function startPool(uint256 _pid) external onlyOperator { [RP] compilation error
    function startPool(uint256 _pid) public onlyOperator {

        PoolInfo storage pool = poolInfo[_pid];
        if (!pool.isStarted)
        {
            pool.isStarted = true;
        }
    }

    // @notice calls startPool for all pools
    function startAllPools() external onlyOperator {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            startPool(pid);
        }
    }

    // View function to see rewards balance.
    function getRewardsBalance() external view returns (uint256) {
        return rewardsBalance;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
    function getLatestRate(uint256 _pid) external view returns(uint256){
        return rateInfo[_pid][rateInfo[_pid].length - 1].rate;
    }
}