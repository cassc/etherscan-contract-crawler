// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./DaoState.sol";
import "./DaoGetters.sol";

contract Setters is State, Getters {
    using SafeMath for uint256;

    /**
     * Global
     */

    function incrementTotalBonded(uint256 amount) internal {
        _state.balance.bonded = _state.balance.bonded.add(amount);
    }

    function decrementTotalBonded(uint256 amount, string memory reason)
        internal
    {
        _state.balance.bonded = _state.balance.bonded.sub(amount, reason);
    }

    /**
     * Account
     */

    function incrementBalanceOf(address account, uint256 amount) internal {
        _state.accounts[account].balance = _state.accounts[account].balance.add(
            amount
        );
        _state.balance.supply = _state.balance.supply.add(amount);
    }

    function decrementBalanceOf(
        address account,
        uint256 amount,
        string memory reason
    ) internal {
        _state.accounts[account].balance = _state.accounts[account].balance.sub(
            amount,
            reason
        );
        _state.balance.supply = _state.balance.supply.sub(amount, reason);
    }

    function incrementBalanceOfStaged(address account, uint256 amount)
        internal
    {
        _state.accounts[account].staged = _state.accounts[account].staged.add(
            amount
        );
        _state.balance.staged = _state.balance.staged.add(amount);
    }

    function decrementBalanceOfStaged(
        address account,
        uint256 amount,
        string memory reason
    ) internal {
        _state.accounts[account].staged = _state.accounts[account].staged.sub(
            amount,
            reason
        );
        _state.balance.staged = _state.balance.staged.sub(amount, reason);
    }

    function incrementBalanceOfCouponStaged(address account, uint256 amount)
        internal
    {
        incrementBalanceOfStaged(account, amount);
        _state.accounts[account].couponStaged = _state
            .accounts[account]
            .couponStaged
            .add(amount);
        _state.balance.couponStaged = _state.balance.couponStaged.add(amount);
    }

    function decrementBalanceOfCouponStaged(
        address account,
        uint256 amount,
        string memory reason
    ) internal {
        decrementBalanceOfStaged(account, amount, reason);
        _state.accounts[account].couponStaged = _state
            .accounts[account]
            .couponStaged
            .sub(amount, reason);
        _state.balance.couponStaged = _state.balance.couponStaged.sub(
            amount,
            reason
        );
    }

    function unfreeze(address account) internal {
        _state.accounts[account].fluidUntil = epoch().add(
            Constants.getDAOExitLockupEpochs()
        );
    }

    /**
     * Epoch
     */

    function incrementEpoch() internal {
        _state.epoch.current = _state.epoch.current.add(1);
    }

    function snapshotTotalBonded() internal {
        _state.epochs[epoch()].bonded = _state.balance.bonded;
    }
}