// SPDX-License-Identifier: ISC

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../base/TaxedStaking.sol";
import "../lib/StakingUtils.sol";

contract AutocompundStaking is TaxedStaking {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    uint256 public lastCompund;
    StakingUtils.AutoCompundConfiguration autoConfig;
    EnumerableSet.AddressSet internal stakeholders;

    event ClaimedReward(address indexed account, uint256 amount);

    function __AutocompundStaking_init(
        StakingUtils.StakingConfiguration memory config,
        StakingUtils.TaxConfiguration memory taxConfig,
        StakingUtils.AutoCompundConfiguration memory _autoConfig
    ) public onlyInitializing {
        __TaxedStaking_init(config, taxConfig);
        __AutocompundStaking_init_unchained(_autoConfig);
    }

    function __AutocompundStaking_init_unchained(StakingUtils.AutoCompundConfiguration memory _autoConfig)
        public
        onlyInitializing
    {
        autoConfig = _autoConfig;
    }

    function runCompund(uint256 batchSize) external {
        uint256 steps;
        uint256 totalPefromanceFee;
        uint256 totalCompundFee;
        uint256 currentIndex = lastCompund;
        while (steps < batchSize) {
            steps++;
            (uint256 compundFee, uint256 performaceTax) = compundForAccount(stakeholders.at(currentIndex));
            totalPefromanceFee += performaceTax;
            totalCompundFee += compundFee;

            currentIndex = (currentIndex + 1) % stakeholders.length();
            if (currentIndex == lastCompund) {
                break;
            }
        }

        lastCompund = currentIndex;
        IERC20(configuration.rewardsToken).safeTransfer(msg.sender, totalCompundFee);
        IERC20(configuration.rewardsToken).safeTransfer(taxConfiguration.hpayFeeAddress, totalPefromanceFee);
        emit ClaimedReward(msg.sender, totalCompundFee);
    }

    function compundForAccount(address account) public updateReward(account) returns (uint256, uint256) {
        uint256 performaceTax = (rewards[account] * autoConfig.performaceFee) / 10_000;
        uint256 compundFee = (rewards[account] * autoConfig.compundReward) / 10_000;
        rewards[account] -= compundFee + performaceTax;
        _compound(account);
        return (compundFee, performaceTax);
    }

    function currentReward(uint256 batchSize) public view returns (uint256) {
        uint256 steps;
        uint256 totalCompundFee;
        uint256 currentIndex = lastCompund;
        while (steps < batchSize) {
            steps++;
            totalCompundFee += (earned(stakeholders.at(currentIndex)) * autoConfig.compundReward) / 10_000;

            currentIndex = (currentIndex + 1) % stakeholders.length();
            if (currentIndex == lastCompund) {
                break;
            }
        }
        return totalCompundFee;
    }

    function _stake(uint256 _amount) internal virtual override {
        TaxedStaking._stake(_amount);
        stakeholders.add(msg.sender);
    }

    function _withdraw(uint256 _amount) internal virtual override {
        TaxedStaking._withdraw(_amount);
        if (_balances[msg.sender] == 0) {
            stakeholders.remove(msg.sender);
        }
    }

    function totalStakeHolders() public view returns (uint256) {
        return stakeholders.length();
    }

    function setPerformanceFee(uint256 _fee) public onlyRole(MANAGER_ROLE) {
        autoConfig.performaceFee = _fee;
    }

    function setCompundReward(uint256 _reward) public onlyRole(MANAGER_ROLE) {
        autoConfig.compundReward = _reward;
    }

    uint256[47] private __gap;
}