// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface ISwapRouter {
    function factory() external pure returns (address);

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);
}
