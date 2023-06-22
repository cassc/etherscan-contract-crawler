// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IUniswapV2Pair } from "./IUniswapV2Pair.sol";

contract Reader {
    struct Token {
        address addr;
        string name;
        string symbol;
        uint8 decimals;
    }

    function getToken(address tokenAddress) public view returns (Token memory) {
        ERC20 token = ERC20(tokenAddress);
        
        return Token({
            addr: tokenAddress,
            name: token.name(),
            symbol: token.symbol(),
            decimals: token.decimals()
        });
    }

    function getTokensAndReserves(address pairAddress) public view returns (Token memory, Token memory, uint112, uint112){
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        
        Token memory token0 = getToken(pair.token0());
        Token memory token1 = getToken(pair.token1());
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();

        return (token0, token1, reserve0, reserve1);
    }
}