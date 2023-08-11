// SPDX-License-Identifier: GPL-3.0
// Copyright: https://github.com/credit-cooperative/Line-Of-Credit/blob/master/COPYRIGHT.md

 pragma solidity ^0.8.16;

import {IInterestRateCredit} from "../../interfaces/IInterestRateCredit.sol";

contract InterestRateCredit is IInterestRateCredit {
    // 1 Julian astronomical year in seconds to use in calculations for rates = 31557600 seconds
    uint256 constant ONE_YEAR = 365.25 days;
    // Must divide by 100 too offset bps in numerator and divide by another 100 to offset % and get actual token amount
    uint256 constant BASE_DENOMINATOR = 10000;
    // = 31557600 * 10000 = 315576000000;
    uint256 constant INTEREST_DENOMINATOR = ONE_YEAR * BASE_DENOMINATOR;

    address immutable lineContract;

    mapping(bytes32 => Rate) public rates; // position id -> lending rates

    /**
     * @notice Interest rate / acrrued interest calculation contract for Line of Credit contracts
     */
    constructor() {
        lineContract = msg.sender;
    }

    ///////////  MODIFIERS  ///////////

    modifier onlyLineContract() {
        require(msg.sender == lineContract, "InterestRateCred: only line contract.");
        _;
    }

    /// see IInterestRateCredit.accrueInterest
    function accrueInterest(
        bytes32 id,
        uint256 drawnBalance,
        uint256 facilityBalance
    ) external override onlyLineContract returns (uint256 accrued) {
        accrued = _accrueInterest(id, drawnBalance, facilityBalance);
        // update last timestamp in storage
        rates[id].lastAccrued = block.timestamp;
    }

    function getInterestAccrued(
        bytes32 id,
        uint256 drawnBalance,
        uint256 facilityBalance
    ) external view returns (uint256) {
        return _accrueInterest(id, drawnBalance, facilityBalance);
    }

    function _accrueInterest(
        bytes32 id,
        uint256 drawnBalance,
        uint256 facilityBalance
    ) internal view returns (uint256) {
        Rate memory rate = rates[id];

        // get time since interest was last accrued iwth these balances
        uint256 timespan = block.timestamp - rate.lastAccrued;

        return (_calculateInterestOwed(rate.dRate, drawnBalance, timespan) +
            _calculateInterestOwed(rate.fRate, (facilityBalance - drawnBalance), timespan));
    }

    /**
     * @notice - total interest to accrue based on apr, balance, and length of time
     * @dev    - r = APR in bps, x = # tokens, t = time
     *         - interest = (r * x * t) / 1yr / 100
     * @param  bpsRate  - interest rate (APR) to charge against balance in bps (4 decimals)
     * @param  balance  - current balance for interest rate tier to charge interest against
     * @param  timespan - total amount of time that interest should be charged for
     *
     * @return interestOwed
     */
    function _calculateInterestOwed(
        uint256 bpsRate,
        uint256 balance,
        uint256 timespan
    ) internal pure returns (uint256) {
        return (bpsRate * balance * timespan) / INTEREST_DENOMINATOR;
    }

    /// see IInterestRateCredit.setRate
    function setRate(bytes32 id, uint128 dRate, uint128 fRate) external onlyLineContract returns (bool) {
        rates[id] = Rate({dRate: dRate, fRate: fRate, lastAccrued: block.timestamp});
        return true;
    }

    function getRates(bytes32 id) external view returns (uint128, uint128) {
        return (rates[id].dRate, rates[id].fRate);
    }
}