// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IUniswapV2Router.sol";
import "./Distributor.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";

abstract contract DexBaseUSDT {
    bool internal inSwapAndLiquify;
    IUniswapV2Router internal uniswapV2Router;
    address internal uniswapV2PairAddress;
    IUniswapV2Pair internal uniswapV2Pair;
    Distributor internal distributor;
    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor(address _routerAddress, address _usdtAddress) {
        uniswapV2Router = IUniswapV2Router(_routerAddress);
        uniswapV2PairAddress = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), _usdtAddress);
        uniswapV2Pair = IUniswapV2Pair(uniswapV2PairAddress);
        distributor = new Distributor();
    }
}
