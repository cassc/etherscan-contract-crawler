// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

interface ILendPool {
    function borrow(
        address reserveAsset,
        uint256 amount,
        address nftAsset,
        uint256 nftTokenId,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function repay(address nftAsset, uint256 nftTokenId, uint256 amount) external returns (uint256, bool);

    function redeem(address nftAsset, uint256 nftTokenId, uint256 amount, uint256 bidFine) external returns (uint256);

    function getNftDebtData(
        address nftAsset,
        uint256 nftTokenId
    )
        external
        view
        returns (
            uint256 loanId,
            address reserveAsset,
            uint256 totalCollateral,
            uint256 totalDebt,
            uint256 availableBorrows,
            uint256 healthFactor
        );

    function getNftAuctionData(
        address nftAsset,
        uint256 nftTokenId
    )
        external
        view
        returns (uint256 loanId, address bidderAddress, uint256 bidPrice, uint256 bidBorrowAmount, uint256 bidFine);
}