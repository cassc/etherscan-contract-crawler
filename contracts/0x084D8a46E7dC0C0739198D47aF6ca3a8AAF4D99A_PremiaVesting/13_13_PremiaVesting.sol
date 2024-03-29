// SPDX-License-Identifier: BUSL-1.1
// For further clarification please see https://license.premia.legal

pragma solidity ^0.8.0;

import {SafeERC20} from "@solidstate/contracts/utils/SafeERC20.sol";
import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";

import {Ownable} from "@solidstate/contracts/access/ownable/Ownable.sol";
import {OwnableStorage} from "@solidstate/contracts/access/ownable/OwnableStorage.sol";

/// @author Premia
/// @title Vesting contract, releasing the allocations over the course of a given period
contract PremiaVesting is Ownable {
    using SafeERC20 for IERC20;

    error PremiaVesting__InvalidAmount();

    // The premia token
    IERC20 public premia;

    // The timestamp at which release ends
    uint256 public endTimestamp;
    // The timestamp at which last withdrawal has been done
    uint256 public lastWithdrawalTimestamp;

    // Amount available to withdraw. We leave this as internal, as this only gets updated on withdrawal.
    // `getAmountAvailableToWithdraw` returns a more up to date value, as it sums this value with pending update amount.
    // Once `endTimestamp` is passed, this value is ignored (We dont update it anymore, and we dont check it)
    uint256 internal amountAvailableToWithdraw;

    //////////////////////////////////////////////////
    //////////////////////////////////////////////////
    //////////////////////////////////////////////////

    // @param _premia The premia token
    constructor(
        IERC20 _premia,
        uint256 _startTimestamp,
        uint256 _releasePeriod
    ) {
        OwnableStorage.layout().owner = msg.sender;

        premia = _premia;
        endTimestamp = _startTimestamp + _releasePeriod;
        lastWithdrawalTimestamp = _startTimestamp;
    }

    //////////////////////////////////////////////////
    //////////////////////////////////////////////////
    //////////////////////////////////////////////////

    function getAmountAvailableToWithdraw() external view returns (uint256) {
        if (block.timestamp >= endTimestamp)
            return premia.balanceOf(address(this));

        return amountAvailableToWithdraw + _calculateUpdateAmount();
    }

    function withdraw(address _to, uint256 _amount) external onlyOwner {
        _update();

        if (
            block.timestamp < endTimestamp &&
            _amount > amountAvailableToWithdraw
        ) revert PremiaVesting__InvalidAmount();

        premia.safeTransfer(_to, _amount);

        if (block.timestamp < endTimestamp) {
            amountAvailableToWithdraw -= _amount;
        }
    }

    function _update() internal {
        if (
            block.timestamp == lastWithdrawalTimestamp ||
            block.timestamp >= endTimestamp
        ) return;

        uint256 updateAmount = _calculateUpdateAmount();
        lastWithdrawalTimestamp = block.timestamp;
        amountAvailableToWithdraw += updateAmount;
    }

    function _calculateUpdateAmount() internal view returns (uint256) {
        uint256 elapsedTime = block.timestamp - lastWithdrawalTimestamp;
        uint256 timeLeft = endTimestamp - lastWithdrawalTimestamp;
        uint256 balance = premia.balanceOf(address(this));

        return ((balance - amountAvailableToWithdraw) * elapsedTime) / timeLeft;
    }
}