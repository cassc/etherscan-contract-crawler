// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./PoolStakeManager.sol";
import "../IRegistry.sol";

contract RegisterableStakeManager is PoolStakeManager {
    event TopUp(
        address indexed account,
        uint256 staked,
        bytes32 planId,
        bytes32 stakeId,
        uint256 timestamp,
        uint256 deadline,
        uint256 period,
        uint256 apy,
        uint256 emergencyTax,
        bool compound,
        address[] tokenForPair,
        uint256[] pricePerStable,
        bool[] stakedTokenMoreExpensive,
        uint256 pips
    );

    IRegistry internal _registry;

    function __init_register(
        address token_,
        address router_,
        IRegistry register
    ) external virtual {
        _registry = register;
        StakeManager.initialize(token_, 8, router_);
    }

    function getRegistry() external view returns (address) {
        return address(_registry);
    }

    function _unregisterStake(address owner, bytes32 stakeId) internal override {
        _registry.deleteEntry(owner, stakeId);
    }

    function _registerStake(
        address owner,
        bytes32 stakeId,
        uint256 amount
    ) internal override {
        _registry.createEntry(owner, stakeId, amount);
    }

    function getCombinableStakes(
        address owner,
        uint256 amount,
        bytes32 planId
    ) public view override returns (bytes32[] memory) {
        amount;
        Plan memory plan = plans[planId];
        bytes32[] memory userStakeIds = userStakes[owner];
        uint256 excludedAmount = 0;
        for (uint256 i = 0; i < userStakeIds.length; i++) {
            Stake memory userStake = stakes[userStakeIds[i]];
            if (
                plans[userStake.planId].minimalAmount > plan.minimalAmount &&
                plans[userStake.planId].period > plan.period
            ) {
                excludedAmount++;
                delete userStakeIds[i];
            }
        }

        bytes32[] memory userStakesToBeCombined = new bytes32[](userStakeIds.length - excludedAmount);
        uint256 stakeIter = 0;
        for (uint256 i = 0; i < userStakeIds.length; i++) {
            if (userStakeIds[i] != bytes32(0)) {
                userStakesToBeCombined[stakeIter] = userStakeIds[i];
                stakeIter++;
            }
        }
        return userStakesToBeCombined;
    }

    function _stakeCombined(
        address sender,
        uint256 amount,
        bytes32 planId,
        bool compound,
        bytes32[] memory stakes_
    ) internal override returns (bytes32) {
        Stake storage _ongoingStake = stakes[stakes_[0]];
        Plan memory _plan = plans[planId];
        compound = compoundEnabled ? compound : false;
        _emitTopUp(
            sender,
            amount,
            planId,
            stakes_[0],
            _ongoingStake.depositTime,
            _ongoingStake.depositTime + 1 days * _plan.period,
            _plan,
            compound
        );
        tvl += amount;
        //Subtract old revenue
        Plan memory _oldPlan = plans[_ongoingStake.planId];
        uint256 oldExpectedRewards = _calculateRewards(
            _ongoingStake,
            _calculateLastWithdrawn(_ongoingStake),
            _ongoingStake.depositTime + 1 days * _oldPlan.period
        );
        //Add new revenue
        uint256 expectedRewards = _calculateRewards(
            Stake(
                sender,
                _ongoingStake.amount + amount,
                _ongoingStake.depositTime,
                planId,
                compound,
                compoundPeriod,
                _ongoingStake.depositTime + 1 days * _plan.period
            ),
            _calculateLastWithdrawn(_ongoingStake),
            _ongoingStake.depositTime + 1 days * _plan.period
        );
        _addExpectedRewards(expectedRewards - oldExpectedRewards);
        _ongoingStake.compound = compound;
        _ongoingStake.amount += amount;
        _ongoingStake.lastWithdrawn = _calculateLastWithdrawn(_ongoingStake);
        _ongoingStake.planId = planId;
        return stakes_[0];
    }

    function _emitTopUp(
        address account,
        uint256 amount,
        bytes32 planId,
        bytes32 stakeId,
        uint256 depositTime,
        uint256 deadline,
        Plan memory plan,
        bool compound
    ) internal {
        (
            address[] memory tokenAddresses,
            uint256[] memory priceComparison,
            bool[] memory stakedMoreExpensive
        ) = _calculateTokenPrice();
        emit TopUp(
            account,
            amount,
            planId,
            stakeId,
            depositTime,
            deadline,
            plan.period,
            plan.apy,
            plan.emergencyTax,
            compound,
            tokenAddresses,
            priceComparison,
            stakedMoreExpensive,
            calculatoryPips
        );
    }

    uint256[50] private gap;
}