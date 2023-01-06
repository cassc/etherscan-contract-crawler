// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../access/OwnerIsCreator.sol";
import "../access/ECDSA.sol";
import "../access/SignatureWriteAccessController.sol";
import "./interfaces/XAssetReadWriteInterface.sol";
import "./interfaces/XOracleReadableInterface.sol";
import "./interfaces/XAssetInterface.sol";
import "./interfaces/XErrorInterface.sol";

/**
 * @title XOracle.sol
 * @dev This contract is responsible for providing interfaces and methods
 * for the owner to update asset balances and unrealized pnl,
 * also it provides an API for user from the public to query asset data
 * @author Lawson Cheng
 */
contract XOracle is SignatureWriteAccessController, XAssetInterface, XOracleReadableInterface, XErrorInterface {

  using ECDSA for bytes32;

  // @notice Event with address of the last updater
  event AssetUpdated(address leaderAddress);
  // @notice Broadcast asset added/removed events
  event AssetAdded(address tokenAddress, AssetType assetType);
  event AssetRemoved(address tokenAddress, AssetType assetType);

  // @dev mapping stores all X asset contract's address
  mapping(address => XAssetReadWriteInterface) private xAssets;
  // @dev stores all keys of X asset contracts
  address[] private xAssetList;

  // @dev Current batch id, we only accept the next request with batch id + 1
  uint256 public batchId;

  /**
  * @dev Update an asset's balance with block timestamp and the latest balance value
  * @param batchId_: the latest batchId
  * @param message_: encoded message
  * @param signature_: signature of the signer
  */
  function updateAssets(
    uint256 batchId_,
    bytes memory message_,
    bytes memory signature_
  ) external checkAccess {
    // check params
    if(batchId_ != batchId + 1) {
      revert UnexpectedBatchID();
    }
    // decode message
    (
      address source,
      uint64 timestamp,
      uint64 blockNumber,
      address[] memory assets,
      int192[] memory balances,
      AssetType[] memory assetTypes
    ) = _decodeMessage(
      message_,
      signature_
    );
    // check data signer
    if(!isSignerValid(source)) {
      revert InvalidDataSigner();
    }
    if(assets.length != balances.length || balances.length != assetTypes.length) {
      revert MalformedData();
    }

    // do update one by one
    for(uint8 i; i < assets.length; ++i) {
      if(!checkAssetExistence(assets[i], assetTypes[i])) {
        revert AssetNotFound(assets[i], assetTypes[i]);
      }
      address assetKey = getKey(assets[i], assetTypes[i]);
      xAssets[assetKey].update(blockNumber, balances[i], timestamp);
    }
    batchId++;
    // broadcast update event
    emit AssetUpdated(msg.sender);
  }

  /************************************
  *                User               *
  ************************************/

  function getRecordsAtIndex(uint256 _index) external view override returns (BatchAssetRecord memory) {
    uint256 numberOfAssets = xAssetList.length;
    AssetDetailRecord[] memory records = new AssetDetailRecord[](numberOfAssets);
    uint64 blockNumber;
    for(uint256 i; i < numberOfAssets; ++i) {
      (AssetDetailRecord memory _record, uint64 _blockNumber) = xAssets[xAssetList[i]].getRecordAtIndex(_index);
      if(i == 0) {
        blockNumber = _blockNumber;
      } else if(blockNumber != _blockNumber){
        revert InconsistentBlockNumber();
      }
      records[i] = _record;
    }
    return BatchAssetRecord({
      records: records,
      blockNumber: blockNumber
    });

  }

  /************************************
  *               Admin               *
  ************************************/

  /**
  * @dev accept all ownerships and become the new owner of all asset and pnl contracts
  * @param addresses the addresses of all asset and pnl contracts
  */
  function acceptOwnerships(OwnableInterface[] calldata addresses) external onlyOwner {
    for(uint8 i = 0; i < addresses.length; ++i) {
      addresses[i].acceptOwnership();
    }
  }

  /**
  * @dev Creates a new asset balance contract
  * @param tokenAddress: the token address
  * @param assetType: the type of asset
  * @param assetAddress: the address fo the AssetBalance contract
  */
  function addAsset(
    address tokenAddress,
    AssetType assetType,
    XAssetReadWriteInterface assetAddress
  ) external onlyOwner {
    if(checkAssetExistence(tokenAddress, assetType)) {
      revert DuplicatedAsset(tokenAddress, assetType);
    }
    address assetKey = getKey(tokenAddress, assetType);
    xAssets[assetKey] = assetAddress;
    xAssetList.push(assetKey);
    emit AssetAdded(tokenAddress, assetType);
  }

  /**
  * @dev Removes asset from asset balance list
  * @param tokenAddress: the token address
  * @param assetType: the type of asset
  */
  function removeAsset(
    address tokenAddress,
    AssetType assetType
  ) external onlyOwner {
    if(!checkAssetExistence(tokenAddress, assetType)) {
      revert AssetNotFound(tokenAddress, assetType);
    }
    address assetKey = getKey(tokenAddress, assetType);
    delete xAssets[assetKey];
    // remove it from list
    for(uint8 i; i < xAssetList.length; ++i) {
      // found asset at index i
      if(assetKey == xAssetList[i]) {
        // remove asset key
        delete xAssetList[i];
        // shift all element towards left to remove the gap
        for(uint8 j = i; j < xAssetList.length - 1; ++j) {
          xAssetList[j] = xAssetList[j+1];
        }
        // remove the last empty element
        xAssetList.pop();
        break;
      }
    }
    emit AssetRemoved(tokenAddress, assetType);
  }

  /************************************
  *           Helper functions        *
  ************************************/

  function getKey(address tokenAddress, AssetType assetType) internal pure returns (address){
    return address(uint160(uint256(keccak256(abi.encodePacked(tokenAddress, assetType)))));
  }

  function checkAssetExistence(address tokenAddress, AssetType assetType) internal view returns (bool) {
    return address(xAssets[getKey(tokenAddress, assetType)]) != address(0);
  }

  /**
* @dev Disassemble the message into different types of data
  *      and also returns the source address of the signer
  * @param message_: encoded message
  * @param signature_: signature of the signer
  */
  function _decodeMessage(bytes memory message_, bytes memory signature_)
  internal
  pure
  returns (
    address,
    uint64,
    uint64,
    address[] memory,
    int192[] memory,
    AssetType[] memory
  )
  {
    // get signer address
    address source = _getSource(message_, signature_);
    // Decode the message
    (
      uint64 timestamp,
      uint64 blockNumber,
      address[] memory assets,
      int192[] memory balances,
      AssetType[] memory assetTypes
    ) = abi.decode(
      message_,
      (uint64, uint64, address[], int192[], AssetType[])
    );
    return (source, timestamp, blockNumber, assets, balances, assetTypes);
  }

  /**
  * @dev Recovers the source address which signed a message
  * @param message_: encoded message
  * @param signature_: signature of the signer
  */
  function _getSource(bytes memory message_, bytes memory signature_) internal pure returns (address) {
    (bytes32 r, bytes32 s, uint8 v) = abi.decode(signature_, (bytes32, bytes32, uint8));
    return keccak256(message_).toEthSignedMessageHash().recover(v, r, s);
  }
}