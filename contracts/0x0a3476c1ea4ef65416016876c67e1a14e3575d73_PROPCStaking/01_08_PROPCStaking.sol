// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IPropcToken {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract PROPCStaking is Ownable  {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;
        uint256 totalRedeemed;
        uint256 lastClaimTimestamp;
        uint256 depositTimestamp;
    }

    struct APYInfo {
        uint256 apyPercent;     // 500 = 5%, 7545 = 75.45%, 10000 = 100%
        uint256 startTime;      // The block timestamp when this APY set
        uint256 stopTime;       // The block timestamp when the next APY set
    }

    // Info of each pool.
    struct PoolInfo {
        uint256 startTime;      // The block timestamp when Rewards Token mining starts.
        IERC20 rewardsToken;
        uint256 totalStaked;
        bool    active;
        uint256 claimTimeLimit;
        uint256 penaltyFee;     // 500 = 5%, 7545 = 75.45%, 10000 = 100%
        uint256 penaltyTimeLimit;
        address penaltyWallet;
        bool isVIPPool;
        mapping (address => bool) isVIPAddress;
        mapping (uint256 => APYInfo) apyInfo;
        uint256 lastAPYIndex;
    }

    IPropcToken public propcToken;

    address public rewardsWallet;

    uint256 public totalPools;

    // Info of each pool.
    mapping(uint256 => PoolInfo) private poolInfo;

    // Info of each user that stakes tokens.
    mapping (uint256 => mapping (address => UserInfo)) private userInfo;


    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Redeem(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        IPropcToken _propc,
        address _rewardsWallet
    ) {
        propcToken = _propc;
        rewardsWallet = _rewardsWallet;
    }

    function updateRewardsWallet(address _wallet) external onlyOwner {
        require(_wallet != address(0x0), "invalid rewards wallet address");
        rewardsWallet = _wallet;
    }

    function poolLength() public view returns (uint256) {
        return totalPools;
    }

    // Can only be called by the owner.
    // Add a new pool when _pid is 0.
    // Update a pool when _pid is not 0.
    function setPool(
        uint256 _pid,
        uint256 _startTime,
        IERC20 _rewardsToken,
        uint256 _apyPercent,
        uint256 _claimTimeLimit,
        uint256 _penaltyFee,
        uint256 _penaltyTimeLimit,
        bool _active,
        address _penaltyWallet,
        bool _isVIPPool
    ) public onlyOwner {
        uint256 pid = _pid == 0 ? ++totalPools : _pid;

        PoolInfo storage pool = poolInfo[pid];

        require(_pid == 0 || pool.lastAPYIndex > 0, "pid is not exist");
        require(_pid > 0 || _apyPercent > 0, "APY should be bigger than zero when adding a new pool");
        require(_penaltyFee <= 3500, "penalty fee can not be more than 35%");

        if (_pid == 0) {
            pool.startTime      = _startTime;
        }

        if (_apyPercent != pool.apyInfo[pool.lastAPYIndex].apyPercent) {
            pool.apyInfo[pool.lastAPYIndex].stopTime = block.timestamp;     // current apy

            pool.lastAPYIndex ++;                                           // new apy
            APYInfo storage apyInfo = pool.apyInfo[pool.lastAPYIndex];
            apyInfo.apyPercent = _apyPercent;
            apyInfo.startTime = block.timestamp;
        }

        pool.rewardsToken       = _rewardsToken;
        pool.claimTimeLimit     = _claimTimeLimit;
        pool.penaltyFee         = _penaltyFee;
        pool.penaltyTimeLimit   = _penaltyTimeLimit;
        pool.active             = _active;
        pool.penaltyWallet      = _penaltyWallet;
        pool.isVIPPool          = _isVIPPool;
    }

    function addVIPAddress(uint256 _pid, address _vipAddress) external onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        require(pool.isVIPPool, "not vip pool");

        pool.isVIPAddress[_vipAddress] = true;
    }

    function addVIPAddresses(uint256 _pid, address[] memory _vipAddresses) external onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        require(pool.isVIPPool, "not vip pool");

        for (uint256 i = 0; i < _vipAddresses.length; i++) {
            pool.isVIPAddress[_vipAddresses[i]] = true;
        }
    }

    function removeVIPAddress(uint256 _pid, address _vipAddress) external onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        require(pool.isVIPPool, "not vip pool");

        pool.isVIPAddress[_vipAddress] = false;
    }

    function removeVIPAddresses(uint256 _pid, address[] memory _vipAddresses) external onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        require(pool.isVIPPool, "not vip pool");

        for (uint256 i = 0; i < _vipAddresses.length; i++) {
            pool.isVIPAddress[_vipAddresses[i]] = false;
        }
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from);
    }

    function _max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    // View function to see pending Rewards Tokens on frontend.
    function pendingRewardsToken(uint256 _pid, address _user) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];

        uint256 pendingRewards = 0;

        for (uint256 apyIndex = pool.lastAPYIndex; apyIndex > 0; apyIndex--) {
            if (pool.apyInfo[apyIndex].stopTime > 0 && user.lastClaimTimestamp >= pool.apyInfo[apyIndex].stopTime) {
                break;
            }

            if (pool.apyInfo[apyIndex].apyPercent == 0) {
                continue;
            }

            uint256 _fromTime = _max(user.lastClaimTimestamp, pool.apyInfo[apyIndex].startTime);
            uint256 _toTime = block.timestamp;

            if (pool.apyInfo[apyIndex].stopTime > 0 && block.timestamp > pool.apyInfo[apyIndex].stopTime) {
                _toTime = pool.apyInfo[apyIndex].stopTime;
            }

            if (_fromTime >= _toTime) {
                continue;
            }

            uint256 multiplier = getMultiplier(_fromTime, _toTime);
            uint256 rewardsPerAPYBlock = multiplier.mul(pool.apyInfo[apyIndex].apyPercent).mul(user.amount).div(365 days).div(10000);
            pendingRewards = pendingRewards.add(rewardsPerAPYBlock);
        }

        return pendingRewards;
    }

    function allPendingRewardsToken(address _user) public view returns (uint256[] memory) {
        uint256 length = poolLength();
        uint256[] memory pendingRewards = new uint256[](length);

        for(uint256 _pid = 1; _pid <= length; _pid++) {
            pendingRewards[_pid - 1] = pendingRewardsToken(_pid, _user);
        }
        return pendingRewards;
    }

    // Stake tokens to contract for Rewards Token allocation.
    function joinPool(uint256 _pid, uint256 _amount) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(pool.startTime < block.timestamp, "mining is not started yet");
        require(pool.active, "pool not active");
        require(!pool.isVIPPool || pool.isVIPAddress[msg.sender] == true, "not vip address");

        if (user.amount > 0) {
            uint256 pendingRewards = pendingRewardsToken(_pid, msg.sender);
            if(pendingRewards > 0) {
                safeRewardTransfer(_pid, msg.sender, pendingRewards);
                user.totalRedeemed = user.totalRedeemed.add(pendingRewards);
            }
        }

        propcToken.transferFrom(msg.sender, address(this), _amount);

        user.amount = user.amount.add(_amount);
        user.lastClaimTimestamp = block.timestamp;
        user.depositTimestamp = block.timestamp;

        pool.totalStaked = pool.totalStaked.add(_amount);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Unstake token from pool.
    function leavePool(uint256 _pid, uint256 _amount) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 pendingRewards = pendingRewardsToken(_pid, msg.sender);
        if(pendingRewards > 0) {
            safeRewardTransfer(_pid, msg.sender, pendingRewards);
            user.totalRedeemed = user.totalRedeemed.add(pendingRewards);
        }

        uint256 penaltyAmount = 0;
        if (user.depositTimestamp + pool.penaltyTimeLimit > block.timestamp) {
            penaltyAmount = _amount.mul(pool.penaltyFee).div(10000);
        }

        propcToken.transfer(msg.sender, _amount.sub(penaltyAmount));
        propcToken.transfer(pool.penaltyWallet, penaltyAmount);

        user.amount = user.amount.sub(_amount);
        user.lastClaimTimestamp = block.timestamp;
        user.depositTimestamp = block.timestamp;

        pool.totalStaked = pool.totalStaked.sub(_amount);

        emit Withdraw(msg.sender, _pid, _amount);
    }

    function _redeem(uint256 _pid, bool _require) private {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.lastClaimTimestamp + pool.claimTimeLimit < block.timestamp, "doesn't meet the claim time limit");

        uint256 pendingRewards = pendingRewardsToken(_pid, msg.sender);

        if (_require) {
            require(pendingRewards > 0, "no pending rewards");
        }

        user.lastClaimTimestamp = block.timestamp;

        if (pendingRewards > 0) {
            user.totalRedeemed += pendingRewards;
            safeRewardTransfer(_pid, msg.sender, pendingRewards);
            emit Redeem(msg.sender, _pid, pendingRewards);
        }
    }

    // Redeem currently pending rewards
    function redeem(uint256 _pid) public {
        _redeem(_pid, true);
    }

    function redeemAll() public {
        uint256[] memory pendingRewards =  allPendingRewardsToken(msg.sender);
        uint256 allPendingRewards = 0;

        for (uint256 i = 0; i < pendingRewards.length; i++) {
            allPendingRewards = allPendingRewards.add(pendingRewards[i]);
        }

        require(allPendingRewards > 0, "no pending rewards");

        for(uint _pid = 1; _pid <= poolLength(); _pid++) {
            _redeem(_pid, false);
        }
    }

    function safeRewardTransfer(uint256 _pid, address _to, uint256 _amount) internal {
        IERC20(poolInfo[_pid].rewardsToken).safeTransferFrom(rewardsWallet, _to, _amount);
    }

    function getUserInfo(uint256 _pid, address _account) public view returns(
        uint256 amount,
        uint256 totalRedeemed,
        uint256 lastClaimTimestamp,
        uint256 depositTimestamp
    ) {
        UserInfo memory user = userInfo[_pid][_account];
        return (
        user.amount,
        user.totalRedeemed,
        user.lastClaimTimestamp,
        user.depositTimestamp
        );
    }

    function getPoolInfo(uint256 _pid) public view returns(
        uint256 startTime,
        address rewardsToken,
        address penaltyWallet,
        uint256 apyPercent,
        uint256 totalStaked,
        bool    active,
        uint256 claimTimeLimit,
        uint256 penaltyFee,
        uint256 penaltyTimeLimit,
        bool isVIPPool
    ) {
        PoolInfo storage pool = poolInfo[_pid];

        startTime           = pool.startTime;
        penaltyWallet       = pool.penaltyWallet;
        isVIPPool           = pool.isVIPPool;
        rewardsToken        = address(pool.rewardsToken);
        apyPercent          = pool.apyInfo[pool.lastAPYIndex].apyPercent;
        totalStaked         = pool.totalStaked;
        active              = pool.active;
        claimTimeLimit      = pool.claimTimeLimit;
        penaltyFee          = pool.penaltyFee;
        penaltyTimeLimit    = pool.penaltyTimeLimit;
    }
}