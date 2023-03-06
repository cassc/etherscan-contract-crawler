// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IRouter {

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

}