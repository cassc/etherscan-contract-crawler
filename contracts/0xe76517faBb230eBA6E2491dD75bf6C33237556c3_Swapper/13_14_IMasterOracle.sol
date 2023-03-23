// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IMasterOracle {
    function quote(address tokenIn_, address tokenOut_, uint256 amountIn_) external view returns (uint256 _amountOut);
}