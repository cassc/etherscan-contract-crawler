// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC165} from '@openzeppelin/contracts/utils/introspection/IERC165.sol';

interface IJBPaymentTerminal is IERC165 {
  function acceptsToken(address token, uint256 projectId) external view returns (bool);

  function currencyForToken(address token) external view returns (uint256);

  function decimalsForToken(address token) external view returns (uint256);

  // Return value must be a fixed point number with 18 decimals.
  function currentEthOverflowOf(uint256 projectId) external view returns (uint256);

  function pay(
    uint256 projectId,
    uint256 amount,
    address token,
    address beneficiary,
    uint256 minReturnedTokens,
    bool preferClaimedTokens,
    string calldata memo,
    bytes calldata metadata
  ) external payable returns (uint256 beneficiaryTokenCount);

  function addToBalanceOf(
    uint256 projectId,
    uint256 amount,
    address token,
    string calldata memo,
    bytes calldata metadata
  ) external payable;
}