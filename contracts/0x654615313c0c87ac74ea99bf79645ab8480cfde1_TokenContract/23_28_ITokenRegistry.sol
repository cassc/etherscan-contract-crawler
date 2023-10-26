// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./IGrtWines.sol";

/*
  _______ .______     .___________.____    __    ____  __  .__   __.  _______     _______.
 /  _____||   _  \    |           |\   \  /  \  /   / |  | |  \ |  | |   ____|   /       |
|  |  __  |  |_)  |   `---|  |----` \   \/    \/   /  |  | |   \|  | |  |__     |   (----`
|  | |_ | |      /        |  |       \            /   |  | |  . `  | |   __|     \   \    
|  |__| | |  |\  \----.   |  |        \    /\    /    |  | |  |\   | |  |____.----)   |   
 \______| | _| `._____|   |__|         \__/  \__/     |__| |__| \__| |_______|_______/    
                                                                                     
*/

/// @title Token Registry
/// @author Developed by Labrys on behalf of GRT Wines
/// @custom:contributor mfbevan (mfbevan.eth)
/// @notice Stores the token URIs in batches allowing for an arbitrary number of tokens to be minted at a time
interface ITokenRegistry is IGrtWines {
  //################
  //#### STRUCTS ####

  /// @dev Parameters for the Token URIs in a release
  /// @param liquidUri The base uri for the liquid token metadata
  /// @param redeemedUri The base uri for the liquid token metadata
  /// @param owner The current owner of the token
  /// @param key The id of the first token in the batch
  /// @param count The number of tokens in the batch
  /// @param locked Is this token batch locked from having its token uri being set
  struct TokenKey {
    string liquidUri;
    string redeemedUri;
    uint256 key;
    uint16 count;
    bool locked;
  }

  //################
  //#### EVENTS ####

  /// @dev Emitted when a token URI is successfully updated
  /// @param batchIndex The index of the batch that was updated
  /// @param liquidUri The updated liquid token URI
  /// @param redeemedUri The updated redeemed token URI
  event BatchURIUpdated(
    uint256 indexed batchIndex,
    string liquidUri,
    string redeemedUri
  );

  /// @dev Emitted when token metadata is successfully locked
  /// @param batchIndex The index of the batch that was locked
  event BatchMetadataLocked(uint256 indexed batchIndex);

  //################
  //#### ERRORS ####

  /// @dev Thrown if a transaction attempts to update the metadata for a batch that has already had an update (locked)
  /// @param batchId The id of the batch being queried
  error BatchLocked(uint256 batchId);

  /// @dev Thrown if querying a batch index that does not exist yet
  error InvalidBatchIndex();

  /// @dev Thrown if batch metadata is added in a non-consecutive order
  error InvalidBatchData();

  /// @dev Thrown if searching for a token that does not exist in the TokenRegistry
  error InvalidTokenId();

  //###################
  //#### FUNCTIONS ####

  /// @notice Get the token key corresponding to a token
  /// @dev If the owner of the token in the owners mapping is the zero address, return the address of the DropManager
  /// @param _tokenId Id of the token
  /// @return tokenKey - the token key containing the liquid and redeemed token URIs
  function getTokenKey(uint _tokenId)
    external
    view
    returns (TokenKey memory tokenKey);

  /// @notice Add a new metadata batch
  /// @dev New batch will be pushed to the end of the tokenKeys array
  /// @dev Only accessible to TOKEN_CONTRACT_ROLE
  /// @dev Emites a {BatchURIUpdated} event
  /// @param _tokenKey The new token batch to add
  function addBatchMetadata(TokenKey calldata _tokenKey) external;

  /// @notice Update the metadata URI for a token batch
  /// @dev Token URIs may only be updated once, and this function will call {lockBatchMetadata}
  /// @dev Only accessible to TOKEN_CONTRACT_ROLE
  /// @dev Emits a {BatchURIUpdated} event
  /// @param _batchIndex The index of the batch to update in the tokenKeys array
  /// @param _liquidUri The new liquid token URI to set
  /// @param _redeemedUri The new redeemed token URI to set
  function updateBatchMetadata(
    uint256 _batchIndex,
    string calldata _liquidUri,
    string calldata _redeemedUri
  ) external;

  /// @notice Lock the capability for a batch to be updated
  /// @dev This behaves like a fuse and cannot be undone
  /// @dev Emits a {BatchMetadataLocked} event
  /// @dev Only accessible to TOKEN_CONTRACT_ROLE
  /// @param _batchIndex The index of the batch to lock
  function lockBatchMetadata(uint256 _batchIndex) external;

  //#################
  //#### GETTERS ####

  function TOKEN_CONTRACT_ROLE() external returns (bytes32 role);
}