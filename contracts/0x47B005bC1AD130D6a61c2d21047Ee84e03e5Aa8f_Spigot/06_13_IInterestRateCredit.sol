// SPDX-License-Identifier: GPL-3.0
// Copyright: https://github.com/test-org2222/Line-Of-Credit/blog/master/COPYRIGHT.md

 pragma solidity ^0.8.16;

interface IInterestRateCredit {
    struct Rate {
        // The interest rate charged to a Borrower on borrowed / drawn down funds
        // in bps, 4 decimals
        uint128 dRate;
        // The interest rate charged to a Borrower on the remaining funds available, but not yet drawn down (rate charged on the available headroom)
        // in bps, 4 decimals
        uint128 fRate;
        // The time stamp at which accrued interest was last calculated on an ID and then added to the overall interestAccrued (interest due but not yet repaid)
        uint256 lastAccrued;
    }

    /**
     * @notice - allows `lineContract to calculate how much interest is owed since it was last calculated charged at time `lastAccrued`
     * @dev    - pure function that only calculates interest owed. Line is responsible for actually updating credit balances with returned value
     * @dev    - callable by `lineContract`
     * @param id - position id on Line to look up interest rates for
     * @param drawnBalance the balance of funds that a Borrower has drawn down on the credit line
     * @param facilityBalance the remaining balance of funds that a Borrower can still drawn down on a credit line (aka headroom)
     *
     * @return - the amount of interest to be repaid for this interest period
     */

    function accrueInterest(bytes32 id, uint256 drawnBalance, uint256 facilityBalance) external returns (uint256);

    /**
     * @notice - updates interest rates on a lender's position. Updates lastAccrued time to block.timestamp
     * @dev    - MUST call accrueInterest() on Line before changing rates. If not, lender will not accrue interest over previous interest period.
     * @dev    - callable by `line`
     * @return - if call was successful or not
     */
    function setRate(bytes32 id, uint128 dRate, uint128 fRate) external returns (bool);

    function getInterestAccrued(
        bytes32 id,
        uint256 drawnBalance,
        uint256 facilityBalance
    ) external view returns (uint256);

    function getRates(bytes32 id) external view returns (uint128, uint128);
}