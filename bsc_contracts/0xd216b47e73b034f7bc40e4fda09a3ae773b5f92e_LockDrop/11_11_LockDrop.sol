// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {SafeERC20, IERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";
import {ReentrancyGuard} from "openzeppelin/security/ReentrancyGuard.sol";
import {IPool} from "../interfaces/IPool.sol";
import {IWETH} from "../interfaces/IWETH.sol";
import {ILevelMaster} from "../interfaces/ILevelMaster.sol";

contract LockDrop is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeERC20 for IWETH;

    struct UserInfo {
        uint256 amount;
        uint256 boostedAmount;
        uint256 rewardDebt;
    }

    uint256 private constant PRECISION = 1e6;
    uint256 private baseRewards;
    /// @notice share of rewards distributed for early depositor
    uint256 private bonusRewards;

    IERC20 public rewardToken;
    IWETH public immutable weth;

    // Level Pool
    IERC20 public immutable lp;
    IPool public immutable pool;
    /// @notice the time contract start to accept deposit
    uint256 private immutable depositTime;
    /// @notice from that time user cannot deposit nor withdraw, rewards start to emit
    uint256 private immutable startRewardTime;
    /// @notice rewards emission completed, user can withdraw
    uint256 private immutable unlockTime;
    /// @notice total amount of locked token
    uint256 private totalAmount;
    /// @notice early deposit user take some bonus point when calculate reward
    uint256 private totalBoostedAmount;
    /// @notice in emergency situation, user allowed to withdraw their token anytime but without reward
    bool public enableEmergency;

    // Level Master
    ILevelMaster public levelMaster;
    uint256 public levelMasterPoolId;

    mapping(address => UserInfo) public userInfo;

    constructor(
        address _weth,
        address _lp,
        address _pool,
        uint256 _depositTime,
        uint256 _startRewardTime,
        uint256 _unlockTime,
        uint256 _baseRewards,
        uint256 _bonusRewards
    ) {
        require(
            block.timestamp <= _depositTime && _depositTime < _startRewardTime && _startRewardTime < _unlockTime,
            "LockDrop::constructor: Time not valid"
        );
        weth = IWETH(_weth);
        lp = IERC20(_lp);
        pool = IPool(_pool);
        depositTime = _depositTime;
        startRewardTime = _startRewardTime;
        unlockTime = _unlockTime;
        baseRewards = _baseRewards;
        bonusRewards = _bonusRewards;
    }

    modifier canDeposit() {
        _checkDepositTime(block.timestamp);
        _;
    }

    function _checkDepositTime(uint256 _now) internal view {
        require(depositTime <= _now, "LockDrop::deposit: deposit not started");
        require(_now < startRewardTime, "LockDrop::deposit: deposit ended");
    }

    // =============== VIEWS ===============

    function claimableRewards(address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 _now = block.timestamp;
        if (totalAmount == 0 || user.amount == 0 || _now < startRewardTime) {
            return 0;
        }

        uint256 time = _now <= unlockTime ? _now - startRewardTime : unlockTime - startRewardTime;
        uint256 lockDuration = unlockTime - startRewardTime;

        uint256 reward = (user.amount * time * baseRewards) / lockDuration / totalAmount;
        uint256 bonusReward = (user.boostedAmount * time * bonusRewards) / lockDuration / (totalBoostedAmount);

        return reward + bonusReward - user.rewardDebt;
    }

    function info()
        public
        view
        returns (
            uint256 _depositTime,
            uint256 _startRewardTime,
            uint256 _unlockTime,
            uint256 _baseRewards,
            uint256 _bonusRewards,
            uint256 _totalAmount,
            uint256 _totalBoostedAmount
        )
    {
        _depositTime = depositTime;
        _startRewardTime = startRewardTime;
        _unlockTime = unlockTime;
        _baseRewards = baseRewards;
        _bonusRewards = bonusRewards;
        _totalAmount = totalAmount;
        _totalBoostedAmount = totalBoostedAmount;
    }

    // =============== USER FUNCTIONS ===============

    /// @notice Deposit ERC20 token. Deposited token will be add to Level Pool, then the LP is locked to this contract
    function deposit(address _token, uint256 _amount, uint256 _minLpAmount, address _to)
        external
        nonReentrant
        canDeposit
    {
        uint256 lockAmount = _addLiquidity(_token, _amount, _minLpAmount);
        _update(_to, lockAmount, startRewardTime);
        emit Deposited(msg.sender, _to, _token, _amount, lockAmount);
    }

    /// @notice Deposit ETH token. Deposited token will be add to Level Pool, then the LP is locked to this contract
    function depositETH(uint256 _minLpAmount, address _to) external payable nonReentrant canDeposit {
        uint256 _amount = msg.value;
        uint256 lockAmount = _addLiquidityETH(_amount, _minLpAmount);

        _update(_to, lockAmount, startRewardTime);

        emit ETHDeposited(msg.sender, _to, _amount, lockAmount);
    }

    /// @notice withdraw LP token then stake to farm contract
    /// @param _unstake if true LP will be sent to user instead of depositing to level master
    function withdraw(address _to, bool _unstake) public {
        require(unlockTime <= block.timestamp, "LockDrop::withdraw: locked");

        UserInfo storage user = userInfo[msg.sender];
        uint256 amount = user.amount;
        if (amount == 0) {
            return;
        }

        uint256 rewards = claimableRewards(msg.sender);
        delete userInfo[msg.sender];

        if (rewards != 0) {
            rewardToken.safeTransfer(_to, rewards);
        }

        if (_unstake) {
            lp.safeTransfer(_to, amount);
        } else {
            lp.safeIncreaseAllowance(address(levelMaster), amount);
            levelMaster.deposit(levelMasterPoolId, amount, _to);
        }
        emit Withdrawn(msg.sender, _to, amount, rewards);
    }

    function claimRewards(address _to) public {
        require(rewardToken != IERC20(address(0)), "LockDrop::claimRewards: reward not set");
        require(startRewardTime <= block.timestamp, "LockDrop::claimRewards: reward not emitted");
        UserInfo storage user = userInfo[msg.sender];
        uint256 rewards = claimableRewards(msg.sender);
        user.rewardDebt = user.rewardDebt + rewards;
        rewardToken.safeTransfer(_to, rewards);

        emit ClaimRewards(msg.sender, _to, rewards);
    }

    function emergencyWithdraw(address _to) external {
        require(enableEmergency, "LockDrop::emergencyWithdraw: not in emergency");

        uint256 amount = userInfo[msg.sender].amount;
        if (amount != 0) {
            delete userInfo[msg.sender];
            lp.safeTransfer(_to, amount);
            emit EmergencyWithdrawn(msg.sender, _to);
        }
    }

    // =============== RESTRICTED ===============

    function setEmergency(bool _enableEmergency) external onlyOwner {
        if (enableEmergency != _enableEmergency) {
            enableEmergency = _enableEmergency;
            emit EmergencySet(_enableEmergency);
        }
    }

    function setBaseRewards(uint256 _baseReward) external onlyOwner {
        require(block.timestamp < startRewardTime, "LockDrop::setBaseRewards: Cannot update after reward time start");
        baseRewards = _baseReward;

        emit BaseRewardUpdated(_baseReward);
    }

    function setBonusRewards(uint256 _bonusReward) external onlyOwner {
        require(block.timestamp < startRewardTime, "LockDrop::setBonusRewards: Cannot update after reward time start");
        bonusRewards = _bonusReward;

        emit BonusRewardUpdated(bonusRewards);
    }

    function setRewardToken(address _rewardToken) external onlyOwner {
        require(rewardToken == IERC20(address(0)), "LockDrop::reward token already set");
        rewardToken = IERC20(_rewardToken);
        emit RewardTokenSet(_rewardToken);
    }

    function setLevelMaster(address _levelMaster, uint256 _poolId) external onlyOwner {
        require(levelMaster == ILevelMaster(address(0)), "LockDrop::reward token already set");
        levelMaster = ILevelMaster(_levelMaster);
        levelMasterPoolId = _poolId;
        emit LevelMasterSet(_levelMaster, _poolId);
    }

    function recoverFund(address _receiver) external onlyOwner {
        require(rewardToken != IERC20(address(0)), "LockDrop::reward token not set");
        require(_receiver != address(0), "LockDrop::receiver is invalid");
        uint256 amount = rewardToken.balanceOf(address(this));
        rewardToken.safeTransfer(_receiver, amount);
        emit FundRecovered(amount, _receiver);
    }

    // ===============  INTERNAL ===============

    function _update(address _to, uint256 _lockAmount, uint256 _startRewardTime) internal {
        uint256 _now = block.timestamp;
        uint256 boostedAmount = (_startRewardTime > _now ? _startRewardTime - _now : 0) * _lockAmount;

        UserInfo storage user = userInfo[_to];
        user.boostedAmount += boostedAmount;
        user.amount += _lockAmount;

        totalBoostedAmount += boostedAmount;
        totalAmount += _lockAmount;
    }

    function _addLiquidity(address _token, uint256 _amount, uint256 _minLpAmount) internal returns (uint256) {
        uint256 currentBalance = lp.balanceOf(address(this));
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20(_token).safeIncreaseAllowance(address(pool), _amount);
        pool.addLiquidity(address(lp), _token, _amount, _minLpAmount, address(this));
        return lp.balanceOf(address(this)) - currentBalance;
    }

    function _addLiquidityETH(uint256 _amount, uint256 _minLpAmount) internal returns (uint256) {
        uint256 currentBalance = lp.balanceOf(address(this));
        weth.deposit{value: _amount}();
        weth.safeIncreaseAllowance(address(pool), _amount);
        pool.addLiquidity(address(lp), address(weth), _amount, _minLpAmount, address(this));
        return lp.balanceOf(address(this)) - currentBalance;
    }

    // ===============  EVENTS ===============
    event EmergencySet(bool enableEmergency);
    event Deposited(address indexed sender, address indexed to, address token, uint256 amount, uint256 lockAmount);
    event ETHDeposited(address indexed sender, address indexed to, uint256 amount, uint256 lockAmount);
    event EmergencyWithdrawn(address indexed sender, address indexed to);
    event Withdrawn(address indexed sender, address indexed to, uint256 amount, uint256 rewards);
    event ClaimRewards(address indexed sender, address indexed to, uint256 rewards);
    event BaseRewardUpdated(uint256 baseRewards);
    event BonusRewardUpdated(uint256 bonusRewards);
    event RewardTokenSet(address token);
    event LevelMasterSet(address levelMaster, uint256 poolId);
    event FundRecovered(uint256 amount, address receiver);
}