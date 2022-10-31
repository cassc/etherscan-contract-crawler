//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {TimeContext} from "./TimeContext.sol";
import {Calendar} from "../lib/Calendar.sol";
import {PRBMathUD60x18Typed as Math, PRBMath} from "prb-math/contracts/PRBMathUD60x18Typed.sol";
import {SimpleInterest} from "./SimpleInterest.sol";
import {CompoundInterest} from "./CompoundInterest.sol";
import {Sorter} from "../lib/Sorter.sol";

/**
    @title FlexibleInterest
    @author iMe Group

    @notice Contract fragment, implementing flexible interest accrual.
    "Flexible" means actual accrual strategy of an investor may change.
 */
abstract contract FlexibleInterest is SimpleInterest, CompoundInterest {
    constructor(uint256 anchor)
        SimpleInterest(anchor)
        CompoundInterest(anchor)
    {}

    enum AccrualStrategy {
        Simple,
        Compound
    }

    mapping(address => uint256) private _impacts;
    uint256 private _totalImpact;

    /**
        @dev Yields personal impact of a participant
     */
    function _impactOf(address participant) internal view returns (uint256) {
        return _impacts[participant];
    }

    /**
        @dev Yields summary impact across all participants
     */
    function _overallImpact() internal view returns (uint256) {
        return _totalImpact;
    }

    /**
        @dev Yields accrual strategy of an investor
     */
    function _accrualStrategyOf(address investor)
        internal
        view
        returns (AccrualStrategy)
    {
        return
            _impactOf(investor) >= _flexibleThreshold()
                ? AccrualStrategy.Compound
                : AccrualStrategy.Simple;
    }

    /**
        @dev Minimal impact needed for compound accrual
    */
    function _flexibleThreshold() internal view virtual returns (uint256);

    function _deposit(
        address investor,
        uint256 amount,
        uint256 at
    ) internal override(SimpleInterest, CompoundInterest) {
        AccrualStrategy currentStrategy = _accrualStrategyOf(investor);

        _impacts[investor] += amount;
        _totalImpact += amount;

        if (currentStrategy == AccrualStrategy.Compound) {
            CompoundInterest._deposit(investor, amount, at);
        }
        /* (currentStrategy == AccrualStrategy.Simple) */
        else {
            AccrualStrategy desiredStrategy = _accrualStrategyOf(investor);

            if (desiredStrategy == AccrualStrategy.Simple) {
                SimpleInterest._deposit(investor, amount, at);
            }
            /* (desiredStrategy == AccrualStrategy.Compound) */
            else {
                uint256 debt = SimpleInterest._debtOf(investor, at);
                SimpleInterest._withdrawal(investor, debt, at);
                CompoundInterest._deposit(investor, debt + amount, at);
            }
        }
    }

    function _withdrawal(
        address investor,
        uint256 amount,
        uint256 at
    ) internal override(SimpleInterest, CompoundInterest) {
        AccrualStrategy currentStrategy = _accrualStrategyOf(investor);

        uint256 impactDecrease = Sorter.min(_impacts[investor], amount);
        _impacts[investor] -= impactDecrease;
        _totalImpact -= impactDecrease;

        if (currentStrategy == AccrualStrategy.Simple) {
            SimpleInterest._withdrawal(investor, amount, at);
        }
        /* (currentStrategy == AccrualStrategy.Compound) */
        else {
            AccrualStrategy desiredStrategy = _accrualStrategyOf(investor);

            if (desiredStrategy == AccrualStrategy.Compound) {
                CompoundInterest._withdrawal(investor, amount, at);
            }
            /* (desiredStrategy == AccrualStrategy.Simple) */
            else {
                uint256 debt = CompoundInterest._debtOf(investor, at);
                CompoundInterest._withdrawal(investor, debt, at);
                SimpleInterest._deposit(investor, debt - amount, at);
            }
        }
    }

    function _debtOf(address investor, uint256 at)
        internal
        view
        override(SimpleInterest, CompoundInterest)
        returns (uint256)
    {
        return
            SimpleInterest._debtOf(investor, at) +
            CompoundInterest._debtOf(investor, at);
    }

    function _totalDebt(uint256 at)
        internal
        view
        override(SimpleInterest, CompoundInterest)
        returns (uint256)
    {
        return SimpleInterest._totalDebt(at) + CompoundInterest._totalDebt(at);
    }
}