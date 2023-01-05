// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../interfaces/external/curve/ICurveFactoryRegistry.sol";
import "../interfaces/external/curve/ICurveSwaps.sol";

interface ICurveAdapter {
    function swap(
        uint256 amountIn_,
        uint256 amountOutMin_,
        address[] memory path_
    ) external payable returns (uint256 _amountOut);

    function swaps() external view returns (ICurveSwaps);

    function registry() external view returns (ICurveFactoryRegistry);
}