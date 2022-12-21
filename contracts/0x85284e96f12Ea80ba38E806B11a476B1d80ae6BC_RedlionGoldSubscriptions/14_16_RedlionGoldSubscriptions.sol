// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '../../libraries/interfaces/ISubscriptions.sol';
import '../../libraries/interfaces/ISubscriptionsManager.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';

/// @title Redlion Gold Subscriptions
/// @author Gui "Qruz" Rodrigues
/// @notice A ERC-721 serving as a subscription token to Redlion services (https://www.redlion.red)
contract RedlionGoldSubscriptions is
  ERC721,
  Pausable,
  ISubscriptions,
  AccessControl
{
  /*///////////////////////////////////////////////////////////////
                             VARIABLES
  ///////////////////////////////////////////////////////////////*/

  using Counters for Counters.Counter;

  Counters.Counter index;

  /// @notice base uri for metadata
  string public baseURI = 'https://nft.redlion.news/metadata/subscription/0/';

  address currentManager;
  bytes32 public constant MANAGER = keccak256('MANAGER');
  bytes32 public constant OWNER = keccak256('OWNER');

  uint supply;

  address[] subscribersList;
  uint256[] timestamps;
  mapping(address => uint) subscribersListIndex;

  /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
  ///////////////////////////////////////////////////////////////*/

  /// @notice Contructor function defining inital values
  /// @dev the souldbound issuer is null because we do not need it, the user has full control of its token (burnable)
  /// @param _manager the manager contract
  constructor(address _manager) ERC721('Redlion Gold Subscriptions', 'RLSUBS') {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(OWNER, msg.sender);
    _setManager(_manager);
  }

  function subscribe(address to) external onlyRole(MANAGER) whenNotPaused {
    require(
      ISubscriptionsManager(currentManager).isSubscribed(to) == false,
      'WALLET_ALREADY_SUBSCRIBED'
    );

    index.increment();
    uint256 tokenId = index.current();
    _mint(to, tokenId);
    uint256 subIndex = subscribersList.length;
    subscribersListIndex[to] = subIndex;
    timestamps.push(block.timestamp);
    subscribersList.push(to);
  }

  function subscribers() external view returns (address[] memory) {
    return subscribersList;
  }

  /*///////////////////////////////////////////////////////////////
                          OWNER FUNCTIONS
  ///////////////////////////////////////////////////////////////*/

  function withdraw() public onlyRole(OWNER) {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function _setManager(address _manager) internal {
    if (currentManager != address(0)) {
      _revokeRole(MANAGER, currentManager);
    }
    _grantRole(MANAGER, _manager);
    currentManager = _manager;
  }

  /// @notice Sets athe new super subcription manager contract
  /// @dev There can only be only one manager contract to avoid obsolete permissions
  /// @param _manager The subscription manager contract address
  function setManager(address _manager) public onlyRole(OWNER) {
    _setManager(_manager);
  }

  /*///////////////////////////////////////////////////////////////
                              UTILITY
  ///////////////////////////////////////////////////////////////*/

  function pause() public onlyRole(OWNER) {
    _pause();
  }

  function unpause() public onlyRole(OWNER) {
    _unpause();
  }

  function setBaseURI(string memory _uri) public onlyRole(OWNER) {
    baseURI = _uri;
  }

  function _baseURI() internal view override(ERC721) returns (string memory) {
    return baseURI;
  }

  function isSubscribed(
    address target
  ) public view override(ISubscriptions) returns (bool) {
    return balanceOf(target) >= 1;
  }

  function when(
    address target
  ) public view override(ISubscriptions) returns (uint256) {
    if (!isSubscribed(target)) return 0;

    return timestamps[subscribersListIndex[target]];
  }

  function subscriptionId(
    address target
  ) public view override(ISubscriptions) returns (bytes memory) {
    require(isSubscribed(target), 'WALLET_NOT_SUBSCRIBED');
    bytes memory subId = abi.encodePacked('S', subscribersListIndex[target]);
    return subId;
  }

  function totalSupply() public view returns (uint) {
    return supply;
  }

  /*///////////////////////////////////////////////////////////////
                                MISC
  ///////////////////////////////////////////////////////////////*/

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721) {
    require(
      ISubscriptionsManager(currentManager).isSubscribed(to) == false,
      'WALLET_ALREADY_SUBSCRIBED'
    );
    super._beforeTokenTransfer(from, to, tokenId);
    // Update subscribers list
    if (from != address(0)) {
      uint arrIndex = subscribersListIndex[from];
      subscribersList[arrIndex] = to;
      timestamps[arrIndex] = block.timestamp;
      delete subscribersListIndex[from];
      subscribersListIndex[to] = arrIndex;
    } else {
      if (from == address(0)) {
        supply++;
      } else if (to == address(0)) {
        supply--;
      }
    }
  }

  // The following functions are overrides required by Solidity.

  function supportsInterface(
    bytes4 interfaceId
  ) public view override(ERC721, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}