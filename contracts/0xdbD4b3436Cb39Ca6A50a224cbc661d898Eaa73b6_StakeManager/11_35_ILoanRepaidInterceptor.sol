// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

interface ILoanRepaidInterceptor {
    function beforeLoanRepaid(address nftAsset, uint256 nftTokenId) external returns (bool);

    function afterLoanRepaid(address nftAsset, uint256 nftTokenId) external returns (bool);
}