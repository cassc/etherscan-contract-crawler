// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import './extensions/TakeAndRunSwap.sol';
import './extensions/TakeRunSwapAndTransfer.sol';
import './extensions/TakeRunSwapsAndTransferMany.sol';
import './extensions/TakeManyRunSwapAndTransferMany.sol';
import './extensions/TakeManyRunSwapsAndTransferMany.sol';
import './extensions/CollectableWithGovernor.sol';
import './extensions/RevokableWithGovernor.sol';
import './extensions/GetBalances.sol';
import './extensions/TokenPermit.sol';
import './extensions/PayableMulticall.sol';

/**
 * @notice This contract implements all swap extensions, so it can be used by EOAs or other contracts that do not have the extensions
 */
contract SwapProxy is
  TakeAndRunSwap,
  TakeRunSwapAndTransfer,
  TakeRunSwapsAndTransferMany,
  TakeManyRunSwapAndTransferMany,
  TakeManyRunSwapsAndTransferMany,
  CollectableWithGovernor,
  RevokableWithGovernor,
  GetBalances,
  TokenPermit,
  PayableMulticall
{
  constructor(address _swapperRegistry, address _governor) SwapAdapter(_swapperRegistry) Governable(_governor) {}
}