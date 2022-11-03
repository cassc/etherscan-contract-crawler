// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "./libraries/UniswapV2Library.sol";
import "./interfaces/IUniswapFactory.sol";
import "./interfaces/IUniswapRouter02.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IWETH.sol";

contract JOY_Migrator {
    IUniswapRouter02 public swapRouter;
    address public FACTORY_ADDRESS = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public JOY_V1_ADDRESS = 0xdb4D1099D53e92593430e33483Db41c63525f55F;
    address public WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public swapPair;

    event RemovedLiquidity(uint256 amountWeth);

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
    }

    constructor() {
        swapRouter = IUniswapRouter02(address(ROUTER_ADDRESS));
        swapPair = IUniswapFactory(swapRouter.factory()).getPair(JOY_V1_ADDRESS,WETH_ADDRESS);
    }

    function removeLiquidityFromLP(uint256 liquidity, uint deadline) public ensure(deadline) returns (uint amountWeth) {
        address pair = UniswapV2Library.pairFor(FACTORY_ADDRESS, JOY_V1_ADDRESS, WETH_ADDRESS);
        IUniswapV2Pair(pair).transferFrom(msg.sender, address(pair), liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = IUniswapV2Pair(pair).burn(address(this));
        (address token0,) = UniswapV2Library.sortTokens(JOY_V1_ADDRESS, WETH_ADDRESS);
        (, amountWeth) = JOY_V1_ADDRESS == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountWeth > 0, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
        IWETH(WETH_ADDRESS).transfer(msg.sender, amountWeth);
        emit RemovedLiquidity(amountWeth);
    }

    function removeLiquidity(uint deadline) public ensure(deadline) returns (uint amountWeth) {
        address pair = UniswapV2Library.pairFor(FACTORY_ADDRESS, JOY_V1_ADDRESS, WETH_ADDRESS);
        uint256 liquidity = IUniswapV2Pair(pair).balanceOf(msg.sender);
        IUniswapV2Pair(pair).transferFrom(msg.sender, address(pair), liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = IUniswapV2Pair(pair).burn(address(this));
        (address token0,) = UniswapV2Library.sortTokens(JOY_V1_ADDRESS, WETH_ADDRESS);
        (, amountWeth) = JOY_V1_ADDRESS == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountWeth > 0, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
        IWETH(WETH_ADDRESS).transfer(msg.sender, amountWeth);
        emit RemovedLiquidity(amountWeth);
    }

}