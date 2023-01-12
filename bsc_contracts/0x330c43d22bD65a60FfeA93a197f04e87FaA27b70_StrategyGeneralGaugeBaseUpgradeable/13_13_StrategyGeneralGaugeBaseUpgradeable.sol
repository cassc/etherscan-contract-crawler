// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./StrategyBaseUpgradeable.sol";
import "../interfaces/ILiquidDepositor.sol";
import "../linSpirit/interfaces/ISpiritGauge.sol";
import "../linSpirit/interfaces/ILinSpiritStrategy.sol";

contract StrategyGeneralGaugeBaseUpgradeable is StrategyBaseUpgradeable {
    // Token addresses
    address public gauge;
    address public rewardToken;
    string public __NAME__;

    constructor() public {}

    function initialize(
        string memory _name,
        address _rewardToken,
        address _gauge,
        address _lp,
        address _depositor
    ) public initializer {
        __Ownable_init();
        initializeStrategyBase(_lp, _depositor);
        rewardToken = _rewardToken;
        gauge = _gauge;
        __NAME__ = _name;
    }
    
    function balanceOfPool() public override view returns (uint256) {
        uint256 amount = ISpiritGauge(gauge).balanceOf(address(this));
        return amount;
    }

    function getHarvestable() external view returns (uint256) {
        uint256 _pendingReward = ISpiritGauge(gauge).rewards(address(this));
        return _pendingReward;
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(gauge, _want);
            ISpiritGauge(gauge).depositAll();
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        ISpiritGauge(gauge).withdraw(_amount);
        return _amount;
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        ISpiritGauge(gauge).getReward();
        uint256 _rewardBalance = IERC20(rewardToken).balanceOf(address(this));
        IERC20(rewardToken).safeTransfer(
            ILiquidDepositor(depositor).treasury(),
            _rewardBalance
        );
    }
}