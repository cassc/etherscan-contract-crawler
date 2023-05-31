// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import { BatchType, IAbstractBatchStorage, Batch } from "./IBatchStorage.sol";

interface IThreeXBatchProcessing {
  function batchStorage() external returns (IAbstractBatchStorage);

  function getBatch(bytes32 batchId) external view returns (Batch memory);

  function depositForMint(uint256 amount_, address account_) external;

  function depositForRedeem(uint256 amount_) external;

  function claim(bytes32 batchId_, address account_) external returns (uint256);

  function withdrawFromBatch(
    bytes32 batchId_,
    uint256 amountToWithdraw_,
    address account_
  ) external returns (uint256);

  function withdrawFromBatch(
    bytes32 batchId_,
    uint256 amountToWithdraw_,
    address _withdrawFor,
    address _recipient
  ) external returns (uint256);
}