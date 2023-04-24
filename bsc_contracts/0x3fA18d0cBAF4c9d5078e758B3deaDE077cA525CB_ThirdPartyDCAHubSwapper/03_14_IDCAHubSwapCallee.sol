// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import './IDCAHub.sol';

/**
 * @title The interface for handling flash swaps
 * @notice Users that want to execute flash swaps must implement this interface
 */
interface IDCAHubSwapCallee {
  // solhint-disable-next-line func-name-mixedcase
  function DCAHubSwapCall(
    address sender,
    IDCAHub.TokenInSwap[] calldata tokens,
    uint256[] calldata borrowed,
    bytes calldata data
  ) external;
}