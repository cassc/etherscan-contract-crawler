//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {CommonInterest} from "./CommonInterest.sol";
import {Math} from "../lib/Math.sol";
import {Calendar} from "../lib/Calendar.sol";

/**
    @title SimpleInterest
    @author iMe Lab

    @notice Implementation of simple interest accrual
    @dev https://en.wikipedia.org/wiki/Interest#Types_of_interest
 */
abstract contract SimpleInterest is CommonInterest {
    constructor(uint64 anchor) {
        _simpleAnchor = anchor;
    }

    uint64 private immutable _simpleAnchor;
    mapping(address => int256) private _simpleDeposit;
    int256 private _totalSimpleDeposit;
    mapping(address => uint256) private _simpleGrowth;
    uint256 private _totalSimpleGrowth;

    function _deposit(
        address depositor,
        uint256 amount,
        uint64 at
    ) internal virtual override(CommonInterest) {
        amount *= 1e18;
        uint256 growthIncrease = (amount * _interestRate) / 1e18;
        uint256 elapsed = Calendar.periods(_simpleAnchor, at, _accrualPeriod);
        int256 depoDiff = int256(amount) - int256(growthIncrease * elapsed);
        _simpleDeposit[depositor] += depoDiff;
        _simpleGrowth[depositor] += growthIncrease;
        _totalSimpleGrowth += growthIncrease;
        _totalSimpleDeposit += depoDiff;
    }

    function _withdrawal(
        address depositor,
        uint256 amount,
        uint64 at
    ) internal virtual override(CommonInterest) {
        uint256 debt = _debt(depositor, at);
        if (amount > debt) {
            revert WithdrawalOverDebt();
        } else if (amount == debt) {
            _withdrawal(depositor);
        } else {
            uint256 growth = _simpleGrowth[depositor];
            uint64 periods = Calendar.periods(
                _simpleAnchor,
                at,
                _accrualPeriod
            );
            uint256 percent = (amount * 1e36) / debt;
            if (percent > 1e18) percent = 1e18;
            uint256 growthDecrease = (growth * (1e18 - percent)) / 1e18;
            int256 depoDecrease = int256(amount * 1e18) -
                int256((growth * periods * (1e18 - percent)) / 1e18);
            _totalSimpleDeposit -= depoDecrease;
            _totalSimpleGrowth -= growthDecrease;
            _simpleDeposit[depositor] -= depoDecrease;
            _simpleGrowth[depositor] -= growthDecrease;
        }
    }

    function _withdrawal(address depositor) internal virtual override {
        int256 deposit = _simpleDeposit[depositor];
        if (deposit != 0) {
            _totalSimpleDeposit -= deposit;
            _simpleDeposit[depositor] = 0;
        }
        uint256 growth = _simpleGrowth[depositor];
        if (growth != 0) {
            _totalSimpleGrowth -= growth;
            _simpleGrowth[depositor] = 0;
        }
    }

    function _debt(
        address depositor,
        uint64 at
    ) internal view virtual override(CommonInterest) returns (uint256) {
        int256 deposit = _simpleDeposit[depositor];
        uint256 growth = _simpleGrowth[depositor];
        uint256 periods = Calendar.periods(_simpleAnchor, at, _accrualPeriod);
        int256 debt = int256(deposit) + int256(periods * growth);
        if (debt < 0) return 0;
        else return Math.fromX18(uint256(debt));
    }

    function _totalDebt(
        uint64 at
    ) internal view virtual override returns (uint256) {
        int256 deposit = _totalSimpleDeposit;
        uint256 growth = _totalSimpleGrowth;
        uint256 periods = Calendar.periods(_simpleAnchor, at, _accrualPeriod);
        int256 debt = int256(deposit) + int256(periods * growth);
        if (debt < 0) return 0;
        else return Math.fromX18(uint256(debt));
    }
}