// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '../../libraries/ERC721Soulbound.sol';
import '../../libraries/interfaces/ISubscriptions.sol';
import '../../libraries/interfaces/ISubscriptionsManager.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import 'hardhat/console.sol';

/// @title Redlion Red Subscriptions
/// @author Gui "Qruz" Rodrigues
/// @notice An ERC-721 Soulbound contract that disables any transfers except from and to the null address (0x0) allowing minting and burning of tokens
/// @dev IERC721Soulbound is a custom made interface according to the EIP-5484 proposal (https://github.com/ethereum/EIPs/blob/master/EIPS/eip-5484.md)
contract RedlionRedSubscriptions is
  ERC721,
  ERC721Soulbound,
  Pausable,
  ISubscriptions,
  AccessControl
{
  /*///////////////////////////////////////////////////////////////
                             VARIABLES
  ///////////////////////////////////////////////////////////////*/

  using Counters for Counters.Counter;

  Counters.Counter index;

  uint256 public MAX_SUPPLY = 100;

  /// @notice base uri for metadata
  string public baseURI = 'https://nft.redlion.news/metadata/subscription/1/';

  address currentManager;

  bytes32 public constant MANAGER = keccak256('MANAGER');
  bytes32 public constant OWNER = keccak256('OWNER');

  uint supply;

  uint256[] timestamps;
  address[] subscribersList;
  mapping(address => uint) subscribersListIndex;

  /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
  ///////////////////////////////////////////////////////////////*/

  /// @notice Contructor function defining inital values
  /// @dev the souldbound issuer is null because we do not need it, the user has full control of its token (burnable)
  /// @param _manager the manager contract
  constructor(
    address _manager
  )
    ERC721('Redlion Red Subscriptions', 'RLSSUB')
    ERC721Soulbound(address(0))
  {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(OWNER, msg.sender);
    _setManager(_manager);
  }

  /**
   * Subscription function role gated to the manager contract.
   * Users cannot already have an active subscription (ISubscriptionManager interface).
   *
   * Token Ids start at 1.
   *
   * @dev The subscriber Index will be the length of the current subscribers array (starting at 0). TokenId != Subscriber Index
   * @param to target address
   */
  function subscribe(address to) public onlyRole(MANAGER) whenNotPaused {
    require(supply < MAX_SUPPLY, 'MAX_SUPPLY_REACHED');
    require(
      ISubscriptionsManager(currentManager).isSubscribed(to) == false,
      'WALLET_ALREADY_SUBSCRIBED'
    );

    index.increment();
    uint256 tokenId = index.current();
    _soulbind(to, tokenId, BurnAuth.OwnerOnly);

    subscribersListIndex[to] = subscribersList.length;
    timestamps.push(block.timestamp);
    subscribersList.push(to);
    supply++;
  }

  /*///////////////////////////////////////////////////////////////
                              BURNING
  ///////////////////////////////////////////////////////////////*/

  /// @notice Function that allows the user to burn its token when it becomes osbolete
  /// @dev This action does not refund the user, it'll only cancel its subscription
  /// @param tokenId the token to burn
  function burn(uint256 tokenId) public {
    _burn(tokenId);
  }

  /*///////////////////////////////////////////////////////////////
                          OWNER FUNCTIONS
  ///////////////////////////////////////////////////////////////*/

  function withdraw() public onlyRole(OWNER) {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  /// @notice Sets the new subcription manager contract
  /// @dev There can only be only one manager contract to avoid obsolete permissions
  /// @param _manager The subscription manager contract address
  function _setManager(address _manager) internal {
    if (currentManager != address(0)) {
      _revokeRole(MANAGER, currentManager);
    }
    _grantRole(MANAGER, _manager);
    currentManager = _manager;
  }

  /// Public function to allow the OWNER role to change the manager contract
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

  /// @return the subscribers list
  function subscribers() external view returns (address[] memory) {
    return subscribersList;
  }

  /// @return the subscription state
  function isSubscribed(
    address target
  ) public view override(ISubscriptions) returns (bool) {
    return balanceOf(target) == 1;
  }

  /// @return the subscription timestamp (seconds)
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
    bytes memory subId = abi.encodePacked('SS', subscribersListIndex[target]);
    return subId;
  }

  function totalSupply() public view returns (uint) {
    return supply;
  }

  /*///////////////////////////////////////////////////////////////
                                MISC
  ///////////////////////////////////////////////////////////////*/

  /**
   * Delete all data related to the subscroption if the trasnfer is to burn address
   * Reverts any transaction to an already subscribed wallet
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Soulbound) {
    super._beforeTokenTransfer(from, to, tokenId);
    if (to == address(0)) {
      // Remove subscription status if token is burned
      // msg.sender will alwys be the original minter
      uint256 arrIndex = subscribersListIndex[from];
      delete subscribersList[arrIndex];
      delete timestamps[arrIndex];
      delete subscribersListIndex[from];
      supply--;
    } else {
      require(
        ISubscriptionsManager(currentManager).isSubscribed(to) == false,
        'WALLET_ALREADY_SUBSCRIBED'
      );
    }
  }

  // The following functions are overrides required by Solidity.

  function _burn(uint256 tokenId) internal override(ERC721) {
    super._burn(tokenId);
  }

  function supportsInterface(
    bytes4 interfaceId
  )
    public
    view
    override(ERC721, ERC721Soulbound, AccessControl)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}