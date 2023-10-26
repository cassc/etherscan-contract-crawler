// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./LoanLibrary.sol";

interface ILoanCore {
    function getLoan(uint256 loanId) external view returns (LoanLibrary.LoanData calldata loanData);
}