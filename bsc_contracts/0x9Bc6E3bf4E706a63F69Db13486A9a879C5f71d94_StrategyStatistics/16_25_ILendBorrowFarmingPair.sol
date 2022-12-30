// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

struct FarmingPair {
    address tokenA;
    address tokenB;
    address xTokenA;
    address xTokenB;
    address swap;
    address swapMaster;
    address lpToken;
    uint256 poolID;
    address rewardsToken;
    address[][] path;
    address[] pathTokenA2BNB;
    address[] pathTokenB2BNB;
    address[] pathRewards2BNB;
    uint256 percentage;
}

interface ILendBorrowFarmingPair {
    function getFarmingPairs() external view returns (FarmingPair[] memory);

    function getPriceFromLpToToken(
        address lpToken,
        uint256 value,
        address token,
        address swap,
        address[] memory path
    ) external view returns (uint256);

    function getPriceFromTokenToLp(
        address lpToken,
        uint256 value,
        address token,
        address swap,
        address[] memory path
    ) external view returns (uint256);

    function checkPercentages() external view;

    function findPath(uint256 id, address token)
        external
        view
        returns (address[] memory path);
}