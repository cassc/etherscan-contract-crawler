// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

interface ILendPoolLoan {
    function setFlashLoanLocking(
        address nftAsset,
        uint256 tokenId,
        bool locked
    ) external;

    function approveFlashLoanLocker(address locker, bool approved) external;

    function approveLoanRepaidInterceptor(address interceptor, bool approved) external;

    function addLoanRepaidInterceptor(address nftAsset, uint256 tokenId) external;

    function deleteLoanRepaidInterceptor(address nftAsset, uint256 tokenId) external;

    function getLoanRepaidInterceptors(address nftAsset, uint256 tokenId) external view returns (address[] memory);

    function getCollateralLoanId(address nftAsset, uint256 nftTokenId) external view returns (uint256);
}