// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ITokenSale {
    function userBalance(address, uint256) external view returns (uint256);

    function getRoundEndTime(uint256 roundId) external view returns (uint256);

    function getRoundStartTime(uint256 roundId) external view returns (uint256);

    function rounds(uint256)
        external
        returns (
            uint256 startTime,
            uint256 endTime,
            uint256 duration,
            uint256 minAmount,
            uint256 maxAmount,
            uint256 purchasePrice,
            uint256 tokensSold,
            uint256 totalPurchaseAmount,
            uint256 tokenSaleType,
            uint256 paymentPercent,
            bool isPublic,
            bool isEnded
        );
}