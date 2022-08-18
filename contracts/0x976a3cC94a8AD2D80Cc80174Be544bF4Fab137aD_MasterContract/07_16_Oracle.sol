// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IMaster.sol";
import "./interfaces/IMetaDataOracle.sol";

contract MetaDataOracle is AccessControl, IMetaDataOracle {
  
  /// @notice struct for response
  struct Response {
    address providerAddress;
    address callerAddress;
    string json;
  }

  bytes32 public constant PROVIDER_ROLE = keccak256("PROVIDER_ROLE");

  event MetadataRequested(address sender, uint id, uint tokenId);
  event MetaDataReturned(string json, address caller, uint id);
  event ProviderAdded(address provider);
  event ProviderRemoved(address provider);
  event ProvidersThresholdChanged(uint n);

  /// @notice how many contracts may refer to it
  uint private numProviders = 0;
  uint private providersThreshold = 1;
  uint private randNonce = 0;

  mapping(uint256 => bool) private pendingRequests;
  mapping(uint256 => Response[]) private idToResponses;

  event Received(address, uint);

  constructor() {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  receive() external payable {
      emit Received(msg.sender, msg.value);
  }

  function takeRole(address caller) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    _setupRole(PROVIDER_ROLE, caller);
  }

  /// @notice Funcrtion that create request for metadata
  /// @param tokenId the token we are interested in
  /// @return id - ID of request
  function requestMetaData(uint tokenId) external override returns (uint256) {
    require(numProviders > 0, " No data providers not yet added.");
    randNonce++;
    
    uint id = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % 1000;
    pendingRequests[id] = true;

    emit MetadataRequested(msg.sender, id, tokenId);
    return id;
  }

  function returnMetadata(string memory json, address callerAddress, uint256 id, uint tokenId) external override onlyRole(PROVIDER_ROLE) {
    require(pendingRequests[id], "Request not found.");
    Response memory res = Response(msg.sender, callerAddress, json);
    idToResponses[id].push(res);
    uint numResponses = idToResponses[id].length;

    if (numResponses == providersThreshold) {
      string memory resJSON = "";

      for (uint i=0; i < idToResponses[id].length; i++) {
        resJSON = idToResponses[id][i].json;
      }

      delete pendingRequests[id];
      delete idToResponses[id];

      IMaster(callerAddress).fulfillMetaDataRequest(resJSON, id, tokenId);
      emit MetaDataReturned(resJSON, callerAddress, id);
    }
  }

  function addProvider(address provider) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    require(!hasRole(PROVIDER_ROLE, provider), "Provider already added.");

    _grantRole(PROVIDER_ROLE, provider);
    numProviders++;

    emit ProviderAdded(provider);
  }

  function removeProvider(address provider) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    require(!hasRole(PROVIDER_ROLE, provider), "Address is not a recognized provider.");
    require (numProviders > 1, "Cannot remove the only provider.");
    _revokeRole(PROVIDER_ROLE, provider);
    numProviders--;
    
    emit ProviderRemoved(provider);
  }

  function setProvidersThreshold(uint threshold) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    require(threshold > 0, "Threshold cannot be zero.");
    providersThreshold = threshold;
    
    emit ProvidersThresholdChanged(providersThreshold);
  }
}