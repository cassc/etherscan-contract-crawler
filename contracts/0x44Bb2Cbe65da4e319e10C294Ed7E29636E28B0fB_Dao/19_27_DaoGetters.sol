// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./DaoState.sol";
import "../Constants.sol";

contract Getters is State {
    using SafeMath for uint256;
    using Decimal for Decimal.D256;

    function balanceOf(address account) public view returns (uint256) {
        return _state.accounts[account].balance;
    }

    function totalSupply() public view returns (uint256) {
        return _state.balance.supply;
    }

    /**
     * Global
     */

    function dollar() public view returns (IDollar) {
        return _state.provider.dollar;
    }

    function oracle() public view returns (IOracle) {
        return _state.provider.oracle;
    }

    function pool() public view returns (address) {
        return _state.provider.pool;
    }

    function coupon() public view returns (ICoupon) {
        return _state.provider.coupon;
    }

    function dontdiememe() public view returns (address) {
        return _state.provider.dontdiememe;
    }

    function totalBonded() public view returns (uint256) {
        return _state.balance.bonded;
    }

    function totalStaged() public view returns (uint256) {
        return _state.balance.staged;
    }

    function totalCouponStaged() public view returns (uint256) {
        return _state.balance.couponStaged;
    }

    function totalNet() public view returns (uint256) {
        return dollar().totalSupply().add(_state.balance.couponStaged);
    }

    /**
     * Account
     */

    function balanceOfStaged(address account) public view returns (uint256) {
        return _state.accounts[account].staged;
    }

    function balanceOfCouponStaged(address account)
        public
        view
        returns (uint256)
    {
        return _state.accounts[account].couponStaged;
    }

    function balanceOfBonded(address account) public view returns (uint256) {
        uint256 _totalNet = totalNet();
        if (_totalNet == 0) {
            return 0;
        }
        return totalBonded().mul(balanceOf(account)).div(_totalNet);
    }

    function statusOf(address account) public view returns (Account.Status) {
        if (_state.accounts[account].lockedUntil > epoch()) {
            return Account.Status.Locked;
        }

        return
            epoch() >= _state.accounts[account].fluidUntil
                ? Account.Status.Frozen
                : Account.Status.Fluid;
    }

    function fluidUntil(address account) public view returns (uint256) {
        return _state.accounts[account].fluidUntil;
    }

    function lockedUntil(address account) public view returns (uint256) {
        return _state.accounts[account].lockedUntil;
    }

    /**
     * Epoch
     */

    function epoch() public view returns (uint256) {
        return _state.epoch.current;
    }

    function epochTime() public view returns (uint256) {
        Constants.EpochStrategy memory current = Constants.getEpochStrategy();

        return epochTimeWithStrategy(current);
    }

    function epochTimeWithStrategy(Constants.EpochStrategy memory strategy)
        private
        view
        returns (uint256)
    {
        return
            blockTimestamp().sub(strategy.start).div(strategy.period).add(
                strategy.offset
            );
    }

    // Overridable for testing
    function blockTimestamp() internal view returns (uint256) {
        return block.timestamp;
    }

    function totalBondedAt(uint256 _epoch) public view returns (uint256) {
        return _state.epochs[_epoch].bonded;
    }

    function bootstrapping() public view returns (bool) {
        return dollar().totalSupply() <= Constants.getBootstrappingSupply();
    }
}