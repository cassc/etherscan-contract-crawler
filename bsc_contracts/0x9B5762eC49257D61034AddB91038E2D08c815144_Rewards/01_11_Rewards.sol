// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./RewardsBase.sol";
import "./interfaces/IHook.sol";
import "./interfaces/IRewards.sol";

import "hardhat/console.sol";

contract Rewards is RewardsBase, IHook, IRewards {
    // caller which can call methods `bonus`
    address internal caller;

    error AccessDenied();
    error AlreadySetup();

    function initialize(
        address sellingToken,
        uint256[] memory timestamps,
        uint256[] memory prices,
        uint256[] memory thresholds,
        uint256[] memory bonuses
    ) external initializer {
        __Rewards_init(sellingToken, timestamps, prices, thresholds, bonuses);
    }

    modifier onlyCaller() {
        if (_msgSender() != caller) {
            revert AccessDenied();
        }
        _;
    }

    function setupCaller() external override {
        if (caller != address(0)) {
            revert AlreadySetup();
        }
        caller = _msgSender();
    }

    function onClaim(address account) external onlyCaller {
        //
        if (participants[account].exists == true) {
            _claim(account, participants[account].groupName);
        }

    }

    /**
    @param amount amount in sellingtokens that need to add to `account`
    */
    function onUnstake(
        address, /*instance*/
        address account,
        uint64, /*duration*/
        uint256 amount,
        uint64 /*rewardsFraction*/
    ) external onlyCaller {
        // 
        uint256 inputAmount = _getNeededInputAmount(amount, getTokenPrice());

        // here we didn't claim immediately. contract may not contains enough tokens and can revert all transactions.
        _addBonus(account, inputAmount, false); 
    }


}