// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IWETHGateway {
  function depositETH(
    uint256 minUsdcAmountOut,
    uint256 numberOfReleases
  ) external payable;
}