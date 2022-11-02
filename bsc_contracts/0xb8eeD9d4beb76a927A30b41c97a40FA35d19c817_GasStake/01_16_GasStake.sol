// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./interface/IGas.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";


contract GasStake is ReentrancyGuard, AccessControlEnumerable {

    using SafeERC20 for IERC20;
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    uint256 public swapRatio = 8 * 1e17;

    address public gas = 0x11Fde929C835fB7aC499ab8a42563cEcFA550867;
    address public usdt = 0xD83ba15A1e3e9ff17E817C57e550465414D5b887;
    uint256 public bonusRatio = 3;
    uint256 public bonusInterval = 24 * 60 * 60;
    uint256 public nextBonusTime = 0;
    
    constructor() {
        _grantRole(OPERATOR_ROLE, _msgSender());
    }

    struct UserInfo {
        uint256 amount;
        uint256 debt;
        uint256 valid;
        uint256 enableBurnAmount;
        uint256 burnedAmount;
        uint256 totalReward;
        uint256 availableReward;
    }

    mapping(address => UserInfo) public userInfoList;

    uint256 public accAwardPerShare;
    uint256 public totalStakeAmount;
    uint256 public totalBonusAmount;
    uint256 public totalBonusUsedAmount;

    function baseInit(
        address _gas, 
        uint256 _bonusRatio,
        uint256 _swapRatio,
        uint256 _bonusInterval
    ) external onlyRole(OPERATOR_ROLE) {
        gas = _gas;
        bonusRatio = _bonusRatio;
        swapRatio = _swapRatio;
        bonusInterval = _bonusInterval;
    }

    function recharge(uint256 amount) external nonReentrant {
        require(amount > 0, "GasStake: incorrect amount.");
        totalBonusAmount += amount;
        IERC20(usdt).safeTransferFrom(msg.sender, address(this), amount);
    }

    function award() external nonReentrant {
        require(totalStakeAmount != 0 , "GasStake: can not award.");
        require(block.timestamp >= nextBonusTime, "GasStake: already award.");
        nextBonusTime = block.timestamp + bonusInterval;
        uint256 bonusAmount = (totalBonusAmount - totalBonusUsedAmount) * bonusRatio / 1000 ;
        totalBonusUsedAmount += bonusAmount;
        accAwardPerShare += bonusAmount * 1e18 / totalStakeAmount;
    }

    function deposit(uint256 amount) external nonReentrant {
        UserInfo storage userInfo = userInfoList[msg.sender];
        userInfo.amount += amount; 
        userInfo.enableBurnAmount += amount;
        userInfo.valid += amount * swapRatio / 1e18;
        userInfo.debt += amount * accAwardPerShare / 1e18;
        totalStakeAmount += amount;
        IERC20(gas).safeTransferFrom(msg.sender, address(this), amount);
    }

    function pending(address _addr) public view returns (uint256) {
       return userInfoList[_addr].amount * accAwardPerShare / 1e18 - userInfoList[_addr].debt;
    }

    function withdraw() external nonReentrant {
        require(userInfoList[msg.sender].amount > 0, "GasStake: insufficient balance.");
        UserInfo storage userInfo = userInfoList[msg.sender];
        uint256 amount = userInfo.amount;
        userInfo.availableReward += pending(msg.sender);
        userInfo.enableBurnAmount = 0;
        userInfo.valid = 0;
        userInfo.debt = 0;
        userInfo.amount = 0;
        totalStakeAmount -= amount;
        IERC20(gas).safeTransfer(msg.sender, amount);
    }

    function harvest() external nonReentrant {
        UserInfo storage userInfo = userInfoList[msg.sender];
        uint256 _pending = pending(msg.sender);
        uint256 availableReward = userInfo.availableReward;
        require(userInfo.amount > 0 && (availableReward + _pending) > 0 , "GasStake: can not harvest.");
        userInfo.availableReward += _pending;
        uint256 harvestAmount = userInfo.availableReward;
        uint256 destroyAmount = harvestAmount * 1e18 / swapRatio;
        if(harvestAmount > userInfo.valid) {
            harvestAmount = userInfo.valid;
            destroyAmount = userInfo.amount;
            userInfo.debt = 0;
        }
        require(userInfo.amount >= destroyAmount, "GasStake: available burn amount not enough.");
        userInfo.valid -= harvestAmount;
        userInfo.amount -= destroyAmount;
        userInfo.debt = userInfo.amount * accAwardPerShare / 1e18;
        userInfo.burnedAmount += destroyAmount;
        userInfo.totalReward += harvestAmount;
        userInfo.availableReward -= harvestAmount;
        userInfo.enableBurnAmount -= destroyAmount;
        totalStakeAmount -= destroyAmount;

        IERC20(usdt).safeTransfer(msg.sender, harvestAmount);
        IGas(gas).burn(destroyAmount);
    }
}