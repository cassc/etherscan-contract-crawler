// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;


import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@overnight-contracts/connectors/contracts/stuff/Thena.sol";
import "../PayoutListener.sol";


contract BscPayoutListener is PayoutListener {

    address[] public qsSyncPools;

    address[] public pancakeSkimPools;
    address public pancakeDepositWallet;

    IERC20 public usdPlus;

    address[] public thenaSkimPools;
    address[] public thenaSkimBribes;

    address[] public wombatSkimPools;

    address public rewardWallet;

    // ---  events

    event QsSyncPoolsUpdated(uint256 index, address pool);
    event QsSyncPoolsRemoved(uint256 index, address pool);
    event PancakeSkimPoolsUpdated(address[] pool);
    event PancakeDepositWalletUpdated(address wallet);
    event UsdPlusUpdated(address usdPlus);
    event SkimReward(address pool, uint256 amount);
    event TotalSkimReward(uint256 amount);
    event ThenaSkimUpdated(address[] pools, address[] bribes);
    event ThenaSkimReward(address pool, address bribe, uint256 amount);
    event WombatSkimUpdated(address[] pools);
    event RewardWalletUpdated(address wallet);
    event RewardWalletSend(uint256 amount);

    // --- setters

    function setQsSyncPools(address[] calldata _qsSyncPools) external onlyAdmin {

        uint256 minLength = (qsSyncPools.length < _qsSyncPools.length) ? qsSyncPools.length : _qsSyncPools.length;

        // replace already exists
        for (uint256 i = 0; i < minLength; i++) {
            qsSyncPools[i] = _qsSyncPools[i];
            emit QsSyncPoolsUpdated(i, _qsSyncPools[i]);
        }

        // add if need
        if (minLength < _qsSyncPools.length) {
            for (uint256 i = minLength; i < _qsSyncPools.length; i++) {
                qsSyncPools.push(_qsSyncPools[i]);
                emit QsSyncPoolsUpdated(i, _qsSyncPools[i]);
            }
        }

        // truncate if need
        if (qsSyncPools.length > _qsSyncPools.length) {
            uint256 removeCount = qsSyncPools.length - _qsSyncPools.length;
            for (uint256 i = 0; i < removeCount; i++) {
                address qsPool = qsSyncPools[qsSyncPools.length - 1];
                qsSyncPools.pop();
                emit QsSyncPoolsRemoved(qsSyncPools.length, qsPool);
            }
        }
    }

    function setPancakeSkimPools(address[] calldata _pancakeSkimPools) external onlyAdmin {
        require(_pancakeSkimPools.length != 0, "Zero pools not allowed");
        pancakeSkimPools = _pancakeSkimPools;
        emit PancakeSkimPoolsUpdated(_pancakeSkimPools);
    }

    function setWombatSkimPools(address[] calldata _wombatSkimPools) external onlyAdmin {
        wombatSkimPools = _wombatSkimPools;
        emit WombatSkimUpdated(_wombatSkimPools);
    }

    function setRewardWallet(address _wallet) external onlyAdmin {
        require(_wallet != address(0), "Zero address not allowed");
        rewardWallet = _wallet;
        emit RewardWalletUpdated(_wallet);
    }

    function setPancakeDepositWallet(address _pancakeDepositWallet) external onlyAdmin {
        require(_pancakeDepositWallet != address(0), "Zero address not allowed");
        pancakeDepositWallet = _pancakeDepositWallet;
        emit PancakeDepositWalletUpdated(_pancakeDepositWallet);
    }

    function setUsdPlus(address _usdPlus) external onlyAdmin {
        require(_usdPlus != address(0), "Zero address not allowed");
        usdPlus = IERC20(_usdPlus);
        emit UsdPlusUpdated(_usdPlus);
    }

    function setThenaSkimPools(address[] calldata _thenaSkimPools, address[] calldata _thenaSkimBribes) external onlyAdmin {
        require(_thenaSkimPools.length != 0, "Zero pools not allowed");
        require(_thenaSkimBribes.length != 0, "Zero pools not allowed");
        require(_thenaSkimPools.length == _thenaSkimBribes.length, "Pools and bribes not equal");
        thenaSkimPools = _thenaSkimPools;
        thenaSkimBribes = _thenaSkimBribes;
        emit ThenaSkimUpdated(_thenaSkimPools, _thenaSkimBribes);
    }

    // ---  constructor

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __PayoutListener_init();
    }

    // ---  logic

    function getAllQsSyncPools() external view returns (address[] memory) {
        return qsSyncPools;
    }

    function payoutDone() external override onlyExchanger {
        _coneSync();
        _pancakeSkim();
        _thenaSkim();
        _wombatSkim();
        _sendToRewardWallet();
    }

    function _wombatSkim() internal {

        for (uint256 i = 0; i < wombatSkimPools.length; i++) {
            address pool = wombatSkimPools[i];
            WombatPool(pool).skim(address(this));
        }
    }

    function _coneSync() internal {
        for (uint256 i = 0; i < qsSyncPools.length; i++) {
            QsSyncPool(qsSyncPools[i]).sync();
        }
    }

    function _pancakeSkim() internal {
        uint256 usdPlusBalanceBefore = usdPlus.balanceOf(address(this));
        for (uint256 i = 0; i < pancakeSkimPools.length; i++) {
            address pool = pancakeSkimPools[i];
            uint256 usdPlusBalance = usdPlus.balanceOf(address(this));
            QsSyncPool(pool).skim(address(this));
            uint256 delta = usdPlus.balanceOf(address(this)) - usdPlusBalance;
            emit SkimReward(pool, delta);
        }
        uint256 totalDelta = usdPlus.balanceOf(address(this)) - usdPlusBalanceBefore;
        if (totalDelta > 0) {
            usdPlus.transfer(pancakeDepositWallet, totalDelta);
        }
        emit TotalSkimReward(totalDelta);
    }

    function _thenaSkim() internal {
        for (uint256 i = 0; i < thenaSkimPools.length; i++) {
            address pool = thenaSkimPools[i];
            address bribe = thenaSkimBribes[i];
            uint256 usdPlusBalanceBeforeSkim = usdPlus.balanceOf(address(this));
            IPair(pool).skim(address(this));
            uint256 amount = usdPlus.balanceOf(address(this)) - usdPlusBalanceBeforeSkim;
            if (amount > 0) {
                usdPlus.approve(bribe, amount);
                IBribe(bribe).notifyRewardAmount(address(usdPlus), amount);
                emit ThenaSkimReward(pool, bribe, amount);
            }
        }
    }

    function _sendToRewardWallet() internal {
        require(rewardWallet != address(0), "rewardWallet is zero");
        uint256 balance = usdPlus.balanceOf(address(this));
        if (balance > 0) {
            usdPlus.transfer(rewardWallet, balance);
            emit RewardWalletSend(balance);
        }
    }
}


interface QsSyncPool {
    function sync() external;
    function skim(address to) external;
}

interface WombatPool{
    function skim(address _to) external returns (uint256 amount);
}