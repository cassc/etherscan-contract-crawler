// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

interface ILendPoolLoan {
    function getCollateralLoanId(address nftAsset, uint256 nftTokenId) external view returns (uint256);

    function borrowerOf(uint256 loanId) external view returns (address);
}