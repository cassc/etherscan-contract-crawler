// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface XAssetInterface {

  enum AssetType { AssetBalance, UnRealizedPnl, TotalNotional }

  /*********************************
  *          For storage           *
  *********************************/
  struct AssetRecord {
    int192 balance;
    uint64 blockNumber;
  }

  /*********************************
  *            For query           *
  *********************************/
  struct AssetDetailRecord {
    address symbol;
    int192 balance;
    AssetType assetType;
  }

  struct BatchAssetRecord {
    AssetDetailRecord[] records;
    uint64 blockNumber;
  }

}