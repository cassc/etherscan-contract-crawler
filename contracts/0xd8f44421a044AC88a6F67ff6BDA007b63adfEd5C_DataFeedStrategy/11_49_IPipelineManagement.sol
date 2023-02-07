//SPDX-License-Identifier: MIT
pragma solidity >=0.8.8 <0.9.0;

import {IGovernable} from '@defi-wonderland/solidity-utils/solidity/interfaces/IGovernable.sol';
import {IBridgeSenderAdapter} from '../bridges/IBridgeSenderAdapter.sol';

interface IPipelineManagement is IGovernable {
  // STATE VARIABLES

  /// @notice Gets the whitelisted nonce of a pipeline
  /// @param _chainId Identifier number of the chain
  /// @param _poolSalt Identifier of the pool
  /// @return _whitelistedNonce The nonce of the observation from which the oracle is fed
  function whitelistedNonces(uint32 _chainId, bytes32 _poolSalt) external view returns (uint24 _whitelistedNonce);

  /// @notice Returns whether a bridge sender adapter is whitelisted or not
  /// @param _bridgeSenderAdapter Address of the bridge sender adapter
  /// @return _isWhitelisted Whether the bridge sender adapter is whitelisted or not
  function whitelistedAdapters(IBridgeSenderAdapter _bridgeSenderAdapter) external view returns (bool _isWhitelisted);

  /// @notice Gets the destination domain id
  /// @param _bridgeSenderAdapter Address of the bridge sender adapter
  /// @param _chainId Identifier number of the chain
  /// @return _destinationDomainId Domain id of the destination chain
  function destinationDomainIds(IBridgeSenderAdapter _bridgeSenderAdapter, uint32 _chainId) external view returns (uint32 _destinationDomainId);

  /// @notice Gets the address of the DataReceiver contract
  /// @param _bridgeSenderAdapter Address of the bridge sender adapter
  /// @param _destinationDomainId Domain id of the destination chain
  /// @return _dataReceiver Address of the DataReceiver contract
  function receivers(IBridgeSenderAdapter _bridgeSenderAdapter, uint32 _destinationDomainId) external view returns (address _dataReceiver);

  // EVENTS

  /// @notice Emitted when a pipeline is whitelisted
  /// @param _chainId Identifier number of the chain
  /// @param _poolSalt Identifier of the pool
  /// @param _whitelistedNonce The nonce of the observation from which the oracle is fed
  event PipelineWhitelisted(uint32 _chainId, bytes32 indexed _poolSalt, uint24 _whitelistedNonce);

  /// @notice Emitted when the whitelist status of a bridge sender adapter is updated
  /// @param _bridgeSenderAdapter Address of the bridge sender adapter
  /// @param _isWhitelisted Whether the bridge sender adapter is whitelisted or not
  event AdapterWhitelisted(IBridgeSenderAdapter _bridgeSenderAdapter, bool _isWhitelisted);

  /// @notice Emitted when a destination domain id is set
  /// @param _bridgeSenderAdapter Address of the bridge sender adapter
  /// @param _chainId Identifier number of the chain
  /// @param _destinationDomainId Domain id of the destination chain
  event DestinationDomainIdSet(IBridgeSenderAdapter _bridgeSenderAdapter, uint32 _chainId, uint32 _destinationDomainId);

  /// @notice Emitted when a DataReceiver contract is set
  /// @param _bridgeSenderAdapter Address of the bridge sender adapter
  /// @param _destinationDomainId Domain id of the destination chain
  /// @param _dataReceiver Address of the DataReceiver contract
  event ReceiverSet(IBridgeSenderAdapter _bridgeSenderAdapter, uint32 _destinationDomainId, address _dataReceiver);

  // ERRORS

  /// @notice Thrown if the pipeline is already whitelisted
  error AlreadyAllowedPipeline();

  /// @notice Thrown if the pool is not whitelisted
  error UnallowedPool();

  /// @notice Thrown if the pipeline is not whitelisted
  error UnallowedPipeline();

  /// @notice Thrown if the nonce is below the whitelisted nonce
  error WrongNonce();

  /// @notice Thrown if the bridge sender adapter is not whitelisted
  error UnallowedAdapter();

  /// @notice Thrown if the destination domain id is not set
  error DestinationDomainIdNotSet();

  /// @notice Thrown if the DataReceiver contract is not set
  error ReceiverNotSet();

  // FUNCTIONS

  /// @notice Whitelists a pipeline
  /// @param _chainId Identifier number of the chain
  /// @param _poolSalt Identifier of the pool
  function whitelistPipeline(uint32 _chainId, bytes32 _poolSalt) external;

  /// @notice Whitelists several pipelines
  /// @param _chainIds Identifier number of each chain
  /// @param _poolSalts Identifier of each pool
  function whitelistPipelines(uint32[] calldata _chainIds, bytes32[] calldata _poolSalts) external;

  /// @notice Whitelists a bridge sender adapter
  /// @param _bridgeSenderAdapter Address of the bridge sender adapter
  /// @param _isWhitelisted Whether to whitelist the bridge sender adapter or not
  function whitelistAdapter(IBridgeSenderAdapter _bridgeSenderAdapter, bool _isWhitelisted) external;

  /// @notice Whitelists several bridge sender adapters
  /// @param _bridgeSenderAdapters Addresses of the bridge sender adapters
  /// @param _isWhitelisted Whether to whitelist each bridge sender adapter or not
  function whitelistAdapters(IBridgeSenderAdapter[] calldata _bridgeSenderAdapters, bool[] calldata _isWhitelisted) external;

  /// @notice Sets a destination domain id
  /// @param _bridgeSenderAdapter Address of the bridge sender adapter
  /// @param _chainId Identifier number of the chain
  /// @param _destinationDomainId Domain id of the destination chain
  function setDestinationDomainId(
    IBridgeSenderAdapter _bridgeSenderAdapter,
    uint32 _chainId,
    uint32 _destinationDomainId
  ) external;

  /// @notice Sets several destination domain ids
  /// @param _bridgeSenderAdapters Addresses of the bridge sender adapters
  /// @param _chainIds Identifier number of each chain
  /// @param _destinationDomainIds Domain id of each destination chain
  function setDestinationDomainIds(
    IBridgeSenderAdapter[] calldata _bridgeSenderAdapters,
    uint32[] calldata _chainIds,
    uint32[] calldata _destinationDomainIds
  ) external;

  /// @notice Sets a DataReceiver contract
  /// @param _bridgeSenderAdapter Address of the bridge sender adapter
  /// @param _destinationDomainId Domain id of the destination chain
  /// @param _dataReceiver Address of the DataReceiver contract
  function setReceiver(
    IBridgeSenderAdapter _bridgeSenderAdapter,
    uint32 _destinationDomainId,
    address _dataReceiver
  ) external;

  /// @notice Sets several DataReceiver contracts
  /// @param _bridgeSenderAdapters Addresses of the bridge sender adapters
  /// @param _destinationDomainIds Domain id of each destination chain
  /// @param _dataReceivers Address of each DataReceiver contract
  function setReceivers(
    IBridgeSenderAdapter[] calldata _bridgeSenderAdapters,
    uint32[] calldata _destinationDomainIds,
    address[] calldata _dataReceivers
  ) external;

  /// @notice Gets the salt of each whitelisted pool
  function whitelistedPools() external view returns (bytes32[] memory);

  /// @notice Gets the id of each whitelisted chain
  function whitelistedChains() external view returns (uint256[] memory);

  /// @notice Returns whether a pool is whitelisted or not
  /// @param _poolSalt Identifier of the pool
  /// @return _isWhitelisted Whether the pool is whitelisted or not
  function isWhitelistedPool(bytes32 _poolSalt) external view returns (bool _isWhitelisted);

  /// @notice Returns whether a pipeline is whitelisted or not
  /// @param _chainId Identifier number of the chain
  /// @param _poolSalt Identifier of the pool
  /// @return _isWhitelisted Whether the pipeline is whitelisted or not
  function isWhitelistedPipeline(uint32 _chainId, bytes32 _poolSalt) external view returns (bool _isWhitelisted);

  /// @notice Validates whether a bridge sender adapter is set up for a particular chain
  /// @param _bridgeSenderAdapter Address of the bridge sender adapter
  /// @param _chainId Identifier number of the chain
  /// @return _destinationDomainId Domain id of the destination chain
  /// @return _dataReceiver Address of the DataReceiver contract
  function validateSenderAdapter(IBridgeSenderAdapter _bridgeSenderAdapter, uint32 _chainId)
    external
    view
    returns (uint32 _destinationDomainId, address _dataReceiver);
}