// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

interface IAMM {
    function swapExactInput(
        address tokenA,
        address tokenB,
        uint24 fee,
        uint256 amountIn,
        uint256 amountOutMin
    ) external returns (uint256);

    function buySweep(
        address token,
        uint256 amountIn,
        uint256 amountOutMin
    ) external returns (uint256);

    function sellSweep(
        address token,
        uint256 amountIn,
        uint256 amountOutMin
    ) external returns (uint256);

    function sequencer() external view returns (address);

    function poolFee() external view returns (uint24);

    function getTWAPrice() external view returns (uint256 amountOut);

    function getPrice() external view returns (uint256 amountOut);
}