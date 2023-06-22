// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { IUniswapV2Router01 } from "./IUniswapV2Router01.sol";

interface IUniswapV2Router01Collection is IUniswapV2Router01 {
    function marketplaceAdmin() external view returns (address _marketplaceAdmin);
    function marketplaceWallet() external view returns (address _marketplaceWallet);
    function marketplaceFee() external view returns (uint _marketplaceFee);
    function royaltyFeeCap(address collection) external view returns (uint _royaltyFeeCap);

    function addLiquidityCollection(
        address tokenA,
        address collectionB,
        uint amountADesired,
        uint[] memory tokenIdsB,
        uint amountAMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETHCollection(
        address collection,
        uint[] memory tokenIds,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidityCollection(
        address tokenA,
        address collectionB,
        uint liquidity,
        uint[] memory tokenIdsB,
        uint amountAMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHCollection(
        address collection,
        uint liquidity,
        uint[] memory tokenIds,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
/*
    function removeLiquidityWithPermitCollection(
        address tokenA,
        address collectionB,
        uint liquidity,
        uint[] memory tokenIdsB,
        uint amountAMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermitCollection(
        address collection,
        uint liquidity,
        uint[] memory tokenIds,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
*/
    function swapExactTokensForTokensCollection(
        uint[] memory tokenIdsIn,
        uint amountOutMin,
        address[] calldata path,
        bool capRoyaltyFee,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokensCollection(
        uint[] memory tokenIdsOut,
        uint amountInMax,
        address[] memory path,
        bool capRoyaltyFee,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactTokensForETHCollection(uint[] memory tokenIdsIn, uint amountOutMin, address[] calldata path, bool capRoyaltyFee, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokensCollection(uint[] memory tokenIdsOut, address[] memory path, bool capRoyaltyFee, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function getAmountsOutCollection(uint[] memory tokenIdsIn, address[] memory path, bool capRoyaltyFee) external view returns (uint[] memory amounts);
    function getAmountsInCollection(uint[] memory tokenIdsOut, address[] memory path, bool capRoyaltyFee) external view returns (uint[] memory amounts);
}