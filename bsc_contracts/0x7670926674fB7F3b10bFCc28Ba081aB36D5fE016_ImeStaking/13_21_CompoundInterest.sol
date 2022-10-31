//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CommonInterest} from "./CommonInterest.sol";
import {Calendar} from "../lib/Calendar.sol";
import {Sorter} from "../lib/Sorter.sol";
import {PRBMathUD60x18Typed as Math, PRBMath} from "prb-math/contracts/PRBMathUD60x18Typed.sol";

/**
    @title CompoundInterest
    @author iMe Group

    @notice Contract, implementing interest accrual via compound strategy
 */
abstract contract CompoundInterest is CommonInterest {
    mapping(address => uint256) private _compoundDeposits;
    uint256 private _totalCompoundDeposit;
    uint256 private _compoundAnchor;

    constructor(uint256 anchor) {
        _compoundAnchor = anchor;
    }

    function _deposit(
        address investor,
        uint256 amount,
        uint256 at
    ) internal virtual override {
        uint256 increase = _compoundConverge(amount, at, _compoundAnchor);

        _compoundDeposits[investor] += increase;
        _totalCompoundDeposit += increase;
    }

    function _withdrawal(
        address investor,
        uint256 amount,
        uint256 at
    ) internal virtual override {
        uint256 deposit = _compoundDeposits[investor];
        uint256 available = _compoundConverge(deposit, _compoundAnchor, at);

        if (amount < available) {
            uint256 decrease = _compoundConverge(amount, at, _compoundAnchor);

            decrease = Sorter.min(decrease, deposit);

            _totalCompoundDeposit -= decrease;
            _compoundDeposits[investor] -= decrease;
        } else if (amount == available) {
            _totalCompoundDeposit -= deposit;
            delete _compoundDeposits[investor];
        } else {
            revert("Not enough tokens for withdrawal");
        }
    }

    function _debtOf(address investor, uint256 at)
        internal
        view
        virtual
        override
        returns (uint256)
    {
        return
            _compoundConverge(_compoundDeposits[investor], _compoundAnchor, at);
    }

    function _totalDebt(uint256 at)
        internal
        view
        virtual
        override
        returns (uint256)
    {
        return _compoundConverge(_totalCompoundDeposit, _compoundAnchor, at);
    }

    function _compoundConverge(
        uint256 sum,
        uint256 from,
        uint256 to
    ) private view returns (uint256) {
        bool backwards = from > to;
        (from, to) = (Sorter.min(from, to), Sorter.max(from, to));

        PRBMath.UD60x18 memory m = Math.powu(
            Math.add(Math.fromUint(1), _accrualPercent()),
            Calendar.countPeriods(from, to, _accrualPeriod())
        );

        if (backwards) {
            return Math.toUint(Math.div(Math.fromUint(sum), m));
        } else {
            return Math.toUint(Math.mul(Math.fromUint(sum), m));
        }
    }
}