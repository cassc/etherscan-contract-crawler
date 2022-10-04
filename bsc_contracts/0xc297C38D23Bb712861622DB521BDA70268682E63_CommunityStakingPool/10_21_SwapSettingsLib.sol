// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

library SwapSettingsLib {
 
    function netWorkSettings(
    )
        internal
        view
        returns(address,address)
    {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        if ((chainId == 0x1) || (chainId == 0x3) || (chainId == 0x4) || (chainId == 0x539) || (chainId == 0x7a69)) {  //+ localganache chainId, used for fork 
            // Ethereum-Uniswap
            return( 
                0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, //uniswapRouter
                0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f  //uniswapRouterFactory
            );
        } else if(chainId == 0x89) {
            // Matic-QuickSwap
            return( 
                0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff, //uniswapRouter
                0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32  //uniswapRouterFactory
            );
        } else if(chainId == 0x38) {
            // Binance-PancakeSwap
            return( 
                0x10ED43C718714eb63d5aA57B78B54704E256024E, //uniswapRouter
                0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73  //uniswapRouterFactory
            );
        } else {
            revert("unsupported chain");
        }
    }

}