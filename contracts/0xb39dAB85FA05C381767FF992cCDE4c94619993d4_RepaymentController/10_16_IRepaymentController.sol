// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IRepaymentController {
    // ============== Lifeycle Operations ==============

    function repay(uint256 loanId) external;

    function claim(uint256 loanId) external;

    function repayPartMinimum(uint256 loanId) external;

    function repayPart(uint256 loanId, uint256 amount) external;

    function closeLoan(uint256 loanId) external;

    // ============== View Functions ==============

    function getInstallmentMinPayment(uint256 loanId)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function amountToCloseLoan(uint256 loanId) external returns (uint256, uint256);
}