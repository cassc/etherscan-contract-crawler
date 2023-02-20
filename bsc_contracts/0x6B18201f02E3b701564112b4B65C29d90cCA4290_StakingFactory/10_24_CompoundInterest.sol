//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {CommonInterest} from "./CommonInterest.sol";
import {Math} from "../lib/Math.sol";
import {Calendar} from "../lib/Calendar.sol";

/**
    @title CompoundInterest
    @author iMe Lab

    @notice Implementation of compound interest accrual
    @dev https://en.wikipedia.org/wiki/Compound_interest
 */
abstract contract CompoundInterest is CommonInterest {
    constructor(uint64 anchor) {
        _compoundAnchor = anchor;
    }

    uint64 private immutable _compoundAnchor;
    mapping(address => uint256) private _compoundDeposit;
    uint256 private _totalCompoundDeposit;

    function _deposit(
        address depositor,
        uint256 amount,
        uint64 at
    ) internal virtual override(CommonInterest) {
        uint256 effect = _converge(
            amount,
            _interestRate,
            at,
            _compoundAnchor,
            _accrualPeriod
        );

        _totalCompoundDeposit += effect;
        _compoundDeposit[depositor] += effect;
    }

    function _withdrawal(
        address recipient,
        uint256 amount,
        uint64 at
    ) internal virtual override(CommonInterest) {
        uint256 debt = _debt(recipient, at);

        if (amount > debt) {
            revert WithdrawalOverDebt();
        } else if (amount == debt) {
            _withdrawal(recipient);
        } else {
            uint256 diff = _converge(
                amount,
                _interestRate,
                at,
                _compoundAnchor,
                _accrualPeriod
            );
            uint256 deposit = _compoundDeposit[recipient];
            if (diff > deposit) diff = deposit;
            _compoundDeposit[recipient] -= diff;
            _totalCompoundDeposit -= diff;
        }
    }

    function _withdrawal(address recipient) internal virtual override {
        uint256 deposit = _compoundDeposit[recipient];
        if (deposit != 0) {
            _totalCompoundDeposit -= deposit;
            _compoundDeposit[recipient] = 0;
        }
    }

    function _debt(
        address recipient,
        uint64 at
    ) internal view virtual override returns (uint256) {
        return
            _converge(
                _compoundDeposit[recipient],
                _interestRate,
                _compoundAnchor,
                at,
                _accrualPeriod
            );
    }

    function _totalDebt(
        uint64 at
    ) internal view virtual override returns (uint256) {
        return
            _converge(
                _totalCompoundDeposit,
                _interestRate,
                _compoundAnchor,
                at,
                _accrualPeriod
            );
    }

    /**
        @notice Yields money value, converged to specified point in time

        @return Converged amount of money [fixed]
     */
    function _converge(
        uint256 sum,
        uint256 interest,
        uint64 from,
        uint64 to,
        uint32 period
    ) private pure returns (uint256) {
        uint64 periods = Calendar.periods(from, to, period);
        if (periods == 0) return sum;
        uint256 lever = Math.powerX33(1e33 + interest * 1e15, periods) / 1e15;
        uint256 converged = to < from ? (sum * 1e36) / lever : sum * lever;
        return Math.fromX18(converged);
    }
}