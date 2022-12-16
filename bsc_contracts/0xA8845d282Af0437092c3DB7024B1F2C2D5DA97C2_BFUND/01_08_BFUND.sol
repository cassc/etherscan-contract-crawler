// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IUniswapV2Router01.sol";
import "./interfaces/IUniswapV2Factory.sol";

contract BFUND is ERC20, Ownable {
    constructor(address _router, address _initTo) ERC20("BFUND Token", "BFUND") {
        _mint(_initTo, 369000000000000000000000000);
        IUniswapV2Router01 _uniswapV2Router = IUniswapV2Router01(_router);
        // Create a pancake pair for this BFUND token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(
                address(this),
                0x55d398326f99059fF775485246999027B3197955
            ); // Create pancake pair BFUND/USDT
    }
}