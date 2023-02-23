interface IBNBVaultLogic {
    // function router() external view returns (address);

    function addLiquidityETH(address token, address user, uint256 amount0, uint256 amount1) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function swapBnbToPosi(address user, uint256 amount) external payable returns (uint256 amountOut);

    function swapPosiToBnb(address user, uint256 amount) external returns (uint256 amountOut);

    function removeLiquidityETH(address user, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin) external returns (uint256 amountToken, uint256 amountETH);

    function boostedRewards() external view returns (uint256);
}