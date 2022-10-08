// SPDX-License-Identifier: LICENSED
pragma solidity ^0.7.0;

interface ISwapper {
    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        address _to
    ) external;

    function getAmountsIn(uint256 amountOut, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function GetReceiverAddress(address[] memory path)
        external
        view
        returns (address);

    function getOptimumPath(address token0, address token1)
        external
        view
        returns (address[] memory);
}