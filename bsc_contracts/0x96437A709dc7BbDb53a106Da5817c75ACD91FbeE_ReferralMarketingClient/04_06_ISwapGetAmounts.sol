interface ISwapGetAmounts {
    function getAmountsIn(uint amountOut, address[] memory path) external view returns (uint[] memory amounts);
}