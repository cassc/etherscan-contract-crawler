//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {CommonInterest} from "./CommonInterest.sol";
import {SimpleInterest} from "./SimpleInterest.sol";
import {CompoundInterest} from "./CompoundInterest.sol";

/**
    @title FlexibleInterest
    @author iMe Lab

    @notice Contract fragment, implementing flexible interest accrual.
    "Flexible" means actual accrual strategy of an investor may change.
 */
abstract contract FlexibleInterest is SimpleInterest, CompoundInterest {
    constructor(uint256 compoundThreshold) {
        _compoundThreshold = compoundThreshold;
    }

    uint256 internal immutable _compoundThreshold;
    mapping(address => uint256) private _impact;
    uint256 private _accumulatedImpact;

    function _deposit(
        address depositor,
        uint256 amount,
        uint64 at
    ) internal override(SimpleInterest, CompoundInterest) {
        uint256 impact = _impact[depositor];
        _impact[depositor] += amount;
        _accumulatedImpact += amount;

        if (impact >= _compoundThreshold) {
            CompoundInterest._deposit(depositor, amount, at);
        } else {
            if (impact + amount >= _compoundThreshold) {
                uint256 debt = SimpleInterest._debt(depositor, at);
                if (debt != 0) SimpleInterest._withdrawal(depositor);
                CompoundInterest._deposit(depositor, debt + amount, at);
            } else {
                SimpleInterest._deposit(depositor, amount, at);
            }
        }
    }

    function _withdrawal(
        address depositor,
        uint256 amount,
        uint64 at
    ) internal override(SimpleInterest, CompoundInterest) {
        uint256 impact = _impact[depositor];
        uint256 decrease = (amount < impact) ? amount : impact;
        _impact[depositor] -= decrease;
        _accumulatedImpact -= decrease;

        if (impact > _compoundThreshold) {
            if (impact - decrease > _compoundThreshold) {
                CompoundInterest._withdrawal(depositor, amount, at);
            } else {
                uint256 debt = CompoundInterest._debt(depositor, at);
                if (debt != 0) CompoundInterest._withdrawal(depositor);
                if (amount != debt)
                    SimpleInterest._deposit(depositor, debt - amount, at);
            }
        } else {
            SimpleInterest._withdrawal(depositor, amount, at);
        }
    }

    function _withdrawal(
        address depositor
    ) internal override(SimpleInterest, CompoundInterest) {
        uint256 impact = _impact[depositor];
        if (impact >= _compoundThreshold)
            CompoundInterest._withdrawal(depositor);
        else SimpleInterest._withdrawal(depositor);
        _accumulatedImpact -= impact;
        _impact[depositor] = 0;
    }

    function _debt(
        address depositor,
        uint64 at
    )
        internal
        view
        override(SimpleInterest, CompoundInterest)
        returns (uint256)
    {
        if (_impact[depositor] >= _compoundThreshold)
            return CompoundInterest._debt(depositor, at);
        else return SimpleInterest._debt(depositor, at);
    }

    function _totalDebt(
        uint64 at
    )
        internal
        view
        override(SimpleInterest, CompoundInterest)
        returns (uint256)
    {
        return CompoundInterest._totalDebt(at) + SimpleInterest._totalDebt(at);
    }

    function _totalImpact() internal view returns (uint256) {
        return _accumulatedImpact;
    }

    function _impactOf(address investor) internal view returns (uint256) {
        return _impact[investor];
    }
}