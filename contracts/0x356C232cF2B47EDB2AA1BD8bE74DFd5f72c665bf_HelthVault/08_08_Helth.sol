// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

interface IDankToken {
    function mint(address to, uint256 amount) external;
    function totalSupply() external view returns (uint256);
    function transferUnderlying(address to, uint256 value) external returns (bool);
    function fragmentToDank(uint256 value) external view returns (uint256);
    function dankToFragment(uint256 dank) external view returns (uint256);
    function balanceOfUnderlying(address who) external view returns (uint256);
    function burn(uint256 amount) external;
}

interface IKalmToken {
    function mint(address to, uint256 amount) external;
    function totalSupply() external view returns (uint256);
}

contract HelthVault is Ownable {
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
        uint256 lockEndedTimestamp;
        uint256 lockStartTimestamp;
    }

    struct PoolInfo {
        uint256 total;
        uint256 duration;
        uint256 kalmScalingFactor; // Used to calculate fraction of locked to $KALM rewards. 1,000,000 = 1:1
    }

    IDankToken public dank;
    IKalmToken public kalm;

    uint256 public total;
    bool public depositsEnabled;

    // {duration: {address: UserInfo}}
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    PoolInfo[] public poolInfo;

    // Events
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event LogSetLockDuration(uint256 duration);
    event LogSetDepositsEnabled(bool enabled);
    event LogPoolAddition(uint256 indexed pid, uint256 rate, uint256 duration);
    event SetKalmAddress(IKalmToken kalmAddress);
    event RewardPaid(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(IDankToken _dank, bool _depositsEnabled) {
        dank = _dank;
        depositsEnabled = _depositsEnabled;
    }

    /// @notice onlyOwner - enables Kalm rewards by setting address
    function setKalmAddress(IKalmToken _address) external onlyOwner {
        kalm = _address;
        emit SetKalmAddress(_address);
    }

    /// @notice onlyOwner - enables Kalm rewards by setting address
    function addVault(uint256 _duration, uint256 _rewardRate) external onlyOwner {
        poolInfo.push(PoolInfo({
            total: 0,
            kalmScalingFactor: _rewardRate,
            duration: _duration
        }));
        emit LogPoolAddition(poolInfo.length - 1, _rewardRate, _duration);
    }

    /// @notice onlyOwner - set new kalm reward rate
    function updateRewardRate(uint256 _pid, uint256 _rewardRate) external onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        pool.kalmScalingFactor = _rewardRate;
    }

    /// @notice onlyOwner - set new kalm reward rate
    function setDepositsEnabled() external onlyOwner {
        require(!depositsEnabled, "deposits already enabled");
        depositsEnabled = true;
        emit LogSetDepositsEnabled(true);
    }

    function deposit(uint256 _pid, uint256 _amount) external {
        require(depositsEnabled, "deposits not enabled yet");
        require(_amount > 0, "invalid amount");

        PoolInfo storage pool = poolInfo[_pid];
        require(pool.duration > 0, "invalid pool index");

        UserInfo storage user = userInfo[_pid][msg.sender];
        user.lockEndedTimestamp = block.timestamp + pool.duration;
        user.lockStartTimestamp = block.timestamp;

        IERC20(address(dank)).safeTransferFrom(address(msg.sender), address(this), _amount);
        dank.burn(_amount);

        total += _amount;
        user.amount += _amount;
        pool.total += _amount;
        emit Deposit(msg.sender, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount) external {
        require(_amount > 0, "invalid amount");

        PoolInfo storage pool = poolInfo[_pid];
        require(pool.kalmScalingFactor > 0, "invalid duration");

        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.lockEndedTimestamp <= block.timestamp, "still locked");
        require(user.amount >= _amount, "invalid amount");

        total -= _amount;
        user.amount -= _amount;
        pool.total -= _amount;

        user.lockEndedTimestamp = block.timestamp + pool.duration;

        dank.mint(address(msg.sender), _amount);
        claim(_pid);

        emit Withdraw(msg.sender, _amount);
    }

    /// @notice - claim all available $KALM rewards
    function claim(uint256 _pid) public {
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= 0, "nothing locked");

        uint256 rewards = pendingRewards(_pid, address(msg.sender));

        user.lockEndedTimestamp = block.timestamp + poolInfo[_pid].duration;
        user.lockStartTimestamp = block.timestamp;

        if (rewards > 0) {
            kalm.mint(address(msg.sender), rewards);
            emit RewardPaid(msg.sender, _pid, rewards);
        }
    }

    /// @notice - kalm rewards only accumulate until end of lock period
    /// @notice - need to claim to reset kalm accumulation
    function pendingRewards(uint256 _pid, address _address) 
        public 
        view 
        returns (uint256) {
        if (address(kalm) == address(0)) {
            // kalm rewards not enabled yet
            return 0;
        }
        UserInfo memory user = userInfo[_pid][_address];
        if (user.amount == 0) {
            return 0;
        }

        if (block.timestamp > user.lockEndedTimestamp) {
            // maximum rewards
            return (user.amount  * poolInfo[_pid].kalmScalingFactor) / 1e6;
        } 

        return (
            user.amount 
            * poolInfo[_pid].kalmScalingFactor 
            * (block.timestamp - user.lockStartTimestamp)
        ) / (poolInfo[_pid].duration * 1e6);
    }
}