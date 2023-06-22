// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

interface IRepayFacet {
    /// @notice a loan has been repaid with interests by its borrower
    /// @param loanId loan identifier
    event Repay(uint256 indexed loanId);

    function repay(uint256[] memory loanIds) external;
}