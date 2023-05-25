// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IPancakeRouter {
  function factory() external pure returns (address);

  // solhint-disable-next-line func-name-mixedcase
  function WETH() external pure returns (address);

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
}