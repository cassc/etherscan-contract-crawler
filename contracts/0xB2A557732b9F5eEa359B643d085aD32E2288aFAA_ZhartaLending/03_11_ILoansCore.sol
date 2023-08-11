// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ILoansCore {
    struct Collateral {
        address contractAddress;
        uint256 tokenId;
        uint256 amount;
    }

    struct Loan {
        uint256 id;
        uint256 amount;
        uint256 interest;
        uint256 maturity;
        uint256 startTime;
        Collateral[100] collaterals;
        uint256 paidPrincipal;
        uint256 paidInterestAmount;
        bool started;
        bool invalidated;
        bool paid;
        bool defaulted;
        bool canceled;
    }

    function getLoan(
        address _borrower,
        uint256 _loanId
    ) external view returns (Loan memory);
}