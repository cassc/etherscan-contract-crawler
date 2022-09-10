// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface ILoanManager {
    enum StatusType {
        NOT_EXISTS,
        NEW,
        RESOLVED
    }

    struct Loan {
        address loanContract;
        uint64 notesNftId;
        StatusType status;
    }

    function registerLoan(address _lender, bytes32 _loanType) external returns (uint32);

    function mintObligationReceipt(uint32 _loanId, address _borrower) external;

    function resolveLoan(uint32 _loanId) external;

    function promissoryNoteToken() external view returns (address);

    function obligationReceiptToken() external view returns (address);

    function getLoanData(uint32 _loanId) external view returns (Loan memory);

    function isValidLoanId(uint32 _loanId, address _loanContract) external view returns (bool);
}