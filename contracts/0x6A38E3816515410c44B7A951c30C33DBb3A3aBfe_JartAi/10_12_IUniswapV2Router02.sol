/*
     ____.  _____ _____________________    _____  .___ 
    |    | /  _  \\______   \__    ___/   /  _  \ |   |
    |    |/  /_\  \|       _/ |    |     /  /_\  \|   |
/\__|    /    |    \    |   \ |    |    /    |    \   |
\________\____|__  /____|_  / |____| /\ \____|__  /___|
                 \/       \/         \/         \/     


Transform words into stunning art 

Website: https://jart.ai/
Twitter: https://twitter.com/jart_ai
Telegram: https://t.me/jart_ai

Total supply: 420,690,000 tokens
Tax: 4% (1% - LP, 1% - operational costs, 2% marketing)
*/


// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {IUniswapV2Router} from "./IUniswapV2Router.sol";

interface IUniswapV2Router02 is IUniswapV2Router {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}