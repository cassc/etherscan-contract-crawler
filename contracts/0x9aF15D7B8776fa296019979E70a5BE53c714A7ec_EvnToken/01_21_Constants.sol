pragma solidity >=0.6.0 <0.8.0;
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

library Constants {
    address constant uniV2FactoryAddress = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    IUniswapV2Factory constant uniV2Factory = IUniswapV2Factory(uniV2FactoryAddress);

    address constant uniV2Router02Address = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 constant uniV2Router02 = IUniswapV2Router02(uniV2Router02Address);

    uint32 constant Future2100 = 4102448400;

    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
}