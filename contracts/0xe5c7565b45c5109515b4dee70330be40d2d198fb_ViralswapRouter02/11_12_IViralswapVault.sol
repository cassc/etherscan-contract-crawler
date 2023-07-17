// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IViralswapVault {

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    
    function factory() external view returns (address);
    function tokenIn() external view returns (address);
    function tokenOut() external view returns (address);
    function viralswapRouter02() external view returns (address);
    function availableQuota() external view returns (uint);
    function tokenOutPerTokenIn() external view returns (uint);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function getQuoteOut(address _tokenIn, uint _amountIn) external view returns (uint amountOut);
    function getQuoteIn(address _tokenOut, uint _amountOut) external view returns (uint amountIn);

    function buy(uint amountOut, address to) external;
    function sync() external;

    function initialize(address, address) external;
    function addQuota(uint) external;
}