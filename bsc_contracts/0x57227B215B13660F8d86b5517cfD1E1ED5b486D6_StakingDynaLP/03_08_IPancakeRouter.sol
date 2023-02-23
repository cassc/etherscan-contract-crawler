// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IPancakeRouter {
    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function WETH() external pure returns (address);
}