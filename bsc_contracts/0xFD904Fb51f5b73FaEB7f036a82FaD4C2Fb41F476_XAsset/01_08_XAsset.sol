// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../access/OwnerIsCreator.sol";
import "./interfaces/XAssetReadWriteInterface.sol";
import "./interfaces/XErrorInterface.sol";

/**
 * @title XAsset.sol
 * @dev Stores the balance of an asset with 5 historical records
 * @author Lawson Cheng
 */
contract XAsset is XAssetReadWriteInterface,  OwnerIsCreator, XErrorInterface {

  // the asset name and type
  address internal immutable TOKEN_ADDRESS;
  AssetType internal immutable ASSET_TYPE;

  // number of historical record of the contract stored
  uint8 constant STORAGE_SIZE = 5;

  // timestamp of the observation made of the latest data
  uint64 internal observationTimestamp;

  // Stores the latest record including historical data
  // @notice The latest record at index 0
  mapping(uint256 => AssetRecord) internal records;

  /**
  * @dev creates an AssetBalance instance
  * @param _tokenAddress: the asset token address
  * @param _assetType: the asset type (Asset or Pnl)
  */
  constructor(
    address _tokenAddress,
    AssetType _assetType
  ) {
    TOKEN_ADDRESS = _tokenAddress;
    ASSET_TYPE = _assetType;
  }

  /**
  * @dev update balance of the asset
  * @param blockNumber: the block number where the update transaction is happened
  * @param balance: the latest balance of that asset
  */
  function update(uint64 blockNumber, int192 balance, uint64 _observationTimestamp) external override onlyOwner {
    if(_observationTimestamp <= observationTimestamp) {
      revert InvalidObservationTimestamp();
    }
    records[4] = records[3];
    records[3] = records[2];
    records[2] = records[1];
    records[1] = records[0];
    records[0] = AssetRecord({
      balance: balance,
      blockNumber: blockNumber
    });
    observationTimestamp = _observationTimestamp;
  }

  /**
  * @dev returns all historical balance records
  */
  function getRecordAtIndex(uint256 _index) external view override returns (AssetDetailRecord memory, uint64) {
    if(_index + 1 > STORAGE_SIZE) {
      revert ExceededStorageLimit(STORAGE_SIZE);
    }
    return (
      AssetDetailRecord({
        symbol: TOKEN_ADDRESS,
        assetType: ASSET_TYPE,
        balance: records[_index].balance
      }),
      records[_index].blockNumber
    );
  }

}