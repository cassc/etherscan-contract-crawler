//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CommonInterest} from "./CommonInterest.sol";
import {Calendar} from "../lib/Calendar.sol";
import {Sorter} from "../lib/Sorter.sol";
import {PRBMathUD60x18Typed as Math, PRBMath} from "prb-math/contracts/PRBMathUD60x18Typed.sol";

/**
    @title SimpleInterest
    @author iMe Group

    @notice Contract, implementing simple interest accrual.
    Implements only logical accrual, without actual token transfer
 */
abstract contract SimpleInterest is CommonInterest {
    mapping(address => uint256) private _simpleDeposits;
    uint256 private _totalSimpleDeposit = 0;
    uint256 private _simpleAnchor;

    constructor(uint256 anchor) {
        _simpleAnchor = anchor;
    }

    function _deposit(
        address investor,
        uint256 amount,
        uint256 at
    ) internal virtual override {
        uint256 increase = _simpleConverge(amount, at, _simpleAnchor);

        _simpleDeposits[investor] += increase;
        _totalSimpleDeposit += increase;
    }

    function _withdrawal(
        address investor,
        uint256 amount,
        uint256 at
    ) internal virtual override {
        uint256 deposit = _simpleDeposits[investor];
        uint256 available = _simpleConverge(deposit, _simpleAnchor, at);

        if (amount < available) {
            uint256 decrease = _simpleConverge(amount, at, _simpleAnchor);

            decrease = Sorter.min(decrease, deposit);

            _totalSimpleDeposit -= decrease;
            _simpleDeposits[investor] -= decrease;
        } else if (amount == available) {
            _totalSimpleDeposit -= deposit;
            delete _simpleDeposits[investor];
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
        return _simpleConverge(_simpleDeposits[investor], _simpleAnchor, at);
    }

    function _totalDebt(uint256 at)
        internal
        view
        virtual
        override
        returns (uint256)
    {
        return _simpleConverge(_totalSimpleDeposit, _simpleAnchor, at);
    }

    function _simpleConverge(
        uint256 sum,
        uint256 from,
        uint256 to
    ) private view returns (uint256) {
        bool backwards = to < from;
        (from, to) = (Sorter.min(from, to), Sorter.max(from, to));

        PRBMath.UD60x18 memory m = Math.add(
            Math.fromUint(1),
            Math.mul(
                _accrualPercent(),
                Math.fromUint(Calendar.countPeriods(from, to, _accrualPeriod()))
            )
        );

        if (backwards) {
            return Math.toUint(Math.div(Math.fromUint(sum), m));
        } else {
            return Math.toUint(Math.mul(Math.fromUint(sum), m));
        }
    }
}