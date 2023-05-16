// SPDX-License-Identifier: MIT

// solhint-disable-next-line
pragma solidity 0.8.2;

interface SwapRouter {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}