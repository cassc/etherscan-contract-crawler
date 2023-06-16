pragma solidity 0.8.15;

interface IUniswapWrapper {
    function getPrice(
        address poolAddress,
        uint32 twapInterval
    ) external view returns (uint256 priceX96);

    function swapV3(
        address tokenIn,
        bytes memory _path,
        uint256 _amount,
        uint256 amountOutMinimum
    ) external returns (uint256 amountOut);

    function router() external view returns (address);

    function getAmountOut(
        bytes memory path,
        uint256 amountIn
    ) external returns (uint256 amountOut);
}