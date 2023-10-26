// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

interface IRouter {
    function createPoolFromUni(
        address tradeToken,
        address poolToken,
        uint24 fee,
        bool reverse
    ) external;

    function createPoolFromSushi(
        address tradeToken,
        address poolToken,
        bool reverse
    ) external;

    function getLsBalance(
        address tradeToken,
        address poolToken,
        uint24 fee,
        bool reverse,
        address user
    ) external view returns (uint256);

    function getLsBalance2(
        address tradeToken,
        address poolToken,
        bool reverse,
        address user
    ) external view returns (uint256);

    function getLsPrice(
        address tradeToken,
        address poolToken,
        uint24 fee,
        bool reverse
    ) external view returns (uint256);

    function getLsPrice2(
        address tradeToken,
        address poolToken,
        bool reverse
    ) external view returns (uint256);

    function addLiquidity(
        address tradeToken,
        address poolToken,
        uint24 fee,
        bool reverse,
        uint256 amount
    ) external payable;

    function addLiquidity2(
        address tradeToken,
        address poolToken,
        bool reverse,
        uint256 amount
    ) external payable;

    function removeLiquidity(
        address tradeToken,
        address poolToken,
        uint24 fee,
        bool reverse,
        uint256 lsAmount,
        uint256 bondsAmount,
        address receipt
    ) external;

    function removeLiquidity2(
        address tradeToken,
        address poolToken,
        bool reverse,
        uint256 lsAmount,
        uint256 bondsAmount,
        address receipt
    ) external;

    function openPosition(
        address tradeToken,
        address poolToken,
        uint24 fee,
        bool reverse,
        uint8 direction,
        uint16 leverage,
        uint256 position
    ) external payable;

    function openPosition2(
        address tradeToken,
        address poolToken,
        bool reverse,
        uint8 direction,
        uint16 leverage,
        uint256 position
    ) external payable;

    function addMargin(uint32 tokenId, uint256 margin) external payable;

    function closePosition(uint32 tokenId, address receipt) external;

    function liquidate(uint32 tokenId, address receipt) external;

    function liquidateByPool(address poolAddress, uint32 positionId, address receipt) external;

    function withdrawERC20(address poolToken) external;

    function withdrawETH() external;

    function repayLoan(
        address tradeToken,
        address poolToken,
        uint24 fee,
        bool reverse,
        uint256 amount,
        address receipt
    ) external payable;

    function repayLoan2(
        address tradeToken,
        address poolToken,
        bool reverse,
        uint256 amount,
        address receipt
    ) external payable;

    function exit(uint32 tokenId, address receipt) external;

    event TokenCreate(uint32 tokenId, address pool, address sender, uint32 positionId);
}