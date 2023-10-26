// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/ITokenRegistry.sol";
import "../libraries/GrtLibrary.sol";

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
contract TokenRegistry is ITokenRegistry, AccessControl {
  TokenKey[] public tokenKeys;

  bytes32 public constant override TOKEN_CONTRACT_ROLE =
    keccak256("TOKEN_CONTRACT_ROLE");

  constructor(address superUser) {
    GrtLibrary.checkZeroAddress(superUser, "super user");
    _setupRole(DEFAULT_ADMIN_ROLE, superUser);
  }

  function getTokenKey(uint256 _tokenId)
    public
    view
    override
    returns (TokenKey memory tokenKey)
  {
    return _binarySearch(_tokenId, 0, tokenKeys.length);
  }

  function addBatchMetadata(TokenKey calldata _tokenKey)
    public
    override
    onlyRole(TOKEN_CONTRACT_ROLE)
  {
    if (tokenKeys.length > 0) {
      TokenKey memory lastBatch = tokenKeys[tokenKeys.length - 1];
      if (_tokenKey.key != (lastBatch.key + lastBatch.count)) {
        revert InvalidBatchData();
      }
    }

    tokenKeys.push(_tokenKey);
    emit BatchURIUpdated(
      tokenKeys.length - 1,
      _tokenKey.liquidUri,
      _tokenKey.redeemedUri
    );
  }

  function updateBatchMetadata(
    uint256 _batchIndex,
    string calldata _liquidUri,
    string calldata _redeemedUri
  ) public override onlyRole(TOKEN_CONTRACT_ROLE) {
    _validateBatch(_batchIndex);
    tokenKeys[_batchIndex].liquidUri = _liquidUri;
    tokenKeys[_batchIndex].redeemedUri = _redeemedUri;
    lockBatchMetadata(_batchIndex);
    emit BatchURIUpdated(_batchIndex, _liquidUri, _redeemedUri);
  }

  function lockBatchMetadata(uint256 _batchIndex)
    public
    override
    onlyRole(TOKEN_CONTRACT_ROLE)
  {
    _validateBatch(_batchIndex);
    if (tokenKeys[_batchIndex].locked) {
      revert BatchLocked(_batchIndex);
    }
    tokenKeys[_batchIndex].locked = true;
    emit BatchMetadataLocked(_batchIndex);
  }

  /// @dev Check if the provided batch index exists, reverting if not
  /// @param _batchIndex The index of the batch to check
  function _validateBatch(uint256 _batchIndex) internal view {
    if (_batchIndex >= tokenKeys.length) {
      revert InvalidBatchIndex();
    }
  }

  /// @dev Check if a token exists in a batch
  /// @param _tokenId The id of the token to check
  /// @param _batch The the batch to check
  function _validateTokenInBatch(uint256 _tokenId, TokenKey memory _batch)
    internal
    pure
    returns (TokenKey memory)
  {
    if (_tokenId >= _batch.key && _tokenId <= _batch.key + _batch.count - 1) {
      return _batch;
    }
    revert InvalidTokenId();
  }

  /// @dev Execute a recursive binary search algorithm for the token key that contains _tokenId
  /// @param _tokenId The id of the token to search for
  /// @param _startIndex The index to start the recursive search at
  /// @param _endIndex The index to end the recursive search at
  /// @return _tokenKey The token key
  function _binarySearch(
    uint256 _tokenId,
    uint256 _startIndex,
    uint256 _endIndex
  ) internal view returns (TokenKey memory _tokenKey) {
    uint256 length = _endIndex - _startIndex;
    if (length == 0) {
      revert InvalidTokenId();
    }
    if (length == 1) {
      TokenKey memory batch = tokenKeys[_startIndex];
      return _validateTokenInBatch(_tokenId, batch);
    }

    uint256 middle = _startIndex + length / 2;
    TokenKey memory middleBatch = tokenKeys[middle];

    if (_tokenId < middleBatch.key) {
      return _binarySearch(_tokenId, _startIndex, middle);
    } else if (_tokenId > middleBatch.key + middleBatch.count - 1) {
      return _binarySearch(_tokenId, middle, _endIndex);
    } else {
      return _validateTokenInBatch(_tokenId, middleBatch);
    }
  }
}