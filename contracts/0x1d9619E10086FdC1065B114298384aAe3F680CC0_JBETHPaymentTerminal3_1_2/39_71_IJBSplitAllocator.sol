// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC165} from '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import {JBSplitAllocationData} from '../structs/JBSplitAllocationData.sol';

/// @title Split allocator
/// @notice Provide a way to process a single split with extra logic
/// @dev The contract address should be set as an allocator in the adequate split
interface IJBSplitAllocator is IERC165 {
  /// @notice This function is called by JBPaymentTerminal.distributePayoutOf(..), during the processing of the split including it
  /// @dev Critical business logic should be protected by an appropriate access control. The token and/or eth are optimistically transfered to the allocator for its logic.
  /// @param data the data passed by the terminal, as a JBSplitAllocationData struct:
  function allocate(JBSplitAllocationData calldata data) external payable;
}