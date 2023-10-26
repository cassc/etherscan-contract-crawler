// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

interface IRepayFacet {
    /// @notice a loan has been repaid with interests by its borrower
    /// @param loanId loan identifier
    event Repay(uint256 indexed loanId);

    function repay(uint256[] memory loanIds) external;

    function toRepay(uint256 loanId) external view returns (uint256 amount);
}