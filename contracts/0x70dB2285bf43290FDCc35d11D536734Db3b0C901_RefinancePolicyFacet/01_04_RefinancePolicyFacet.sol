// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "xy3/interfaces/IXY3.sol";
import "./Errors.sol";

contract RefinancePolicyFacet {

    function lenderRefinanceCheck(uint32 _loanId, Offer memory _offer) view external {
        LoanInfo memory loanInfo = IXY3(address(this)).getLoanInfo(_loanId);
        if (
            block.timestamp > loanInfo.maturityDate ||
            block.timestamp < loanInfo.maturityDate - 1 hours
        ) {
            revert LenderRefinanceTimeNotMeet();
        }
        (
            uint256 payoffAmount,
            uint256 adminFee,
            uint256 minServiceFee,

        ) = IXY3(address(this)).getMinimalRefinanceAmounts(_loanId);
        uint256 minTotal = payoffAmount + adminFee + minServiceFee;
        if (_offer.borrowAmount < minTotal) {
            revert LenderRefinanceBorrowAmountNotMeet();
        }
        if (_offer.repayAmount > minTotal + 0.05 ether) {
            revert LenderRefinanceRepayAmountNotMeet();
        }
        if (_offer.borrowDuration != 1 days) {
            revert LenderRefinanceDurationNotMeet();
        }
    }
}