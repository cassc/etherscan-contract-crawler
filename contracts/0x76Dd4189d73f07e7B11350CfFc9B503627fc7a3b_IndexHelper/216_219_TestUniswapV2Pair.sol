// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "./uniswap-v2/interfaces/IUniswapV2Pair.sol";
import "./uniswap-v2/UniswapV2ERC20.sol";

contract TestUniswapV2Pair is UniswapV2ERC20 {
    address public factory;
    address public token0;
    address public token1;

    uint112 internal reserve0;
    uint112 internal reserve1;
    uint32 internal blockTimestampLast;

    function getReserves()
        public
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        )
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    constructor(
        address _token0,
        address _token1,
        uint112 _reserve0,
        uint112 _reserve1
    ) {
        factory = msg.sender;
        token0 = _token0;
        token1 = _token1;
        reserve0 = _reserve0;
        reserve1 = _reserve1;
    }
}