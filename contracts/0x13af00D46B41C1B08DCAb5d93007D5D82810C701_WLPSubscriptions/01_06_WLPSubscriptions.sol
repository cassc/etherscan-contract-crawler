// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../Common/Delegated.sol";

interface IERC721WLP{
  function balanceOf(address) external returns(uint256);
}

interface IERC1155WLP{
  function balanceOf(address, uint256) external returns(uint256);
}

contract WLPSubscriptions is Delegated, ReentrancyGuard{
  event CollectionUpdate(address indexed collection, bool isActive, uint256 price);
  event SubscriptionUpdate(address indexed account, uint32 started, uint32 expires);

  using Address for address;

  uint256 constant public ERC721 = 1;
  uint256 constant public ERC1155 = 2;

  struct CollectionSettings{
    uint256 ethPrice;

    address payable royaltyReceiver;
    uint16 royaltyNum;
    uint16 royaltyDenom;

    uint32 duration;
    uint16 index;
    bool isActive;

    address collectionAddress;
    uint8 collectionType;
    uint8 collectionId;
  }

  struct Subscription{
    uint256 value;
    uint32 created;
    uint32 started;
    uint32 expires;
  }

  bytes22[] public collections;
  mapping( bytes22 => CollectionSettings ) public collectionSettings;
  mapping( address => Subscription ) public subscriptions;

  constructor()
    Delegated()
    ReentrancyGuard()
    //solhint-disable-next-line no-empty-blocks
  {
    collections.push();
  }


  //safety first
  receive() external payable {}

  function withdraw() external onlyOwner {
    require(address(this).balance >= 0, "No funds available");
    Address.sendValue(payable(owner()), address(this).balance);
  }


  //view
  function getCollectionKey(address collection, uint16 tokenId) public pure returns(bytes22){
    return bytes22((uint176(uint160(collection)) << 16) + tokenId);
  }

  function getSubscription(address account) external view returns( Subscription memory ){
    if( block.timestamp < subscriptions[ account ].expires  ){
      return subscriptions[ account ];
    }
    else{
      //expired
      return subscriptions[address(0)];
    }
  }

  function countCollections() external view returns(uint256){
    return collections.length - 1;
  }

  function listCollections(uint256 start, uint256 count) external view returns(CollectionSettings[] memory activeCollections){
    if( start == 0 )
      ++start;

    uint256 index = 0;
    uint256 end = start + count;
    if(collections.length < end){
      end = collections.length;
      count = end - start;
    }

    activeCollections = new CollectionSettings[](count);
    for(uint256 i = start; i < end; ++i){
      activeCollections[index++] = collectionSettings[collections[i]];
    }
  }


  //payable
  function subscribe( address collection, uint16 tokenId, uint16 periods ) external payable nonReentrant{
    CollectionSettings memory cfg = collectionSettings[getCollectionKey(collection, tokenId)];
    require( cfg.isActive,                        "Sales/Subscriptions are currently closed" );
    require( msg.value == periods * cfg.ethPrice, "Not enough ETH for selected duration" );

    if(cfg.collectionType == ERC721)
      require( IERC721WLP(collection).balanceOf(msg.sender) > 0, "Not a token holder" );
    else if(cfg.collectionType == ERC1155)
      require( IERC1155WLP(collection).balanceOf(msg.sender, cfg.collectionId) > 0, "Not a token holder" );
    else
      revert("Unsupported collection/token");

    uint32 seconds_ = uint32( periods * cfg.duration );
    _updateSubscription( seconds_, msg.sender );

    uint256 royaltyAmount = msg.value * cfg.royaltyNum / cfg.royaltyDenom;
    Address.sendValue(cfg.royaltyReceiver,royaltyAmount);
  }


  //payable onlyDelegates
  function gift(uint32[] calldata seconds_, address[] calldata accounts) external payable onlyDelegates {
    for(uint256 i = 0; i < seconds_.length; ++i){
      _updateSubscription(seconds_[i], accounts[i]);
    }
  }

  function refund(address payable account, uint256 value, bool setExpired) external payable nonReentrant onlyDelegates {
    require(value < address( this ).balance, "Not enough ETH on contract");
    require(value <= subscriptions[ account ].value, "Refund exceeds cost");

    if(setExpired){
      uint32 expires = uint32(block.timestamp);
      uint32 started = subscriptions[ account ].started;
      subscriptions[ account ].expires = expires;
      emit SubscriptionUpdate(account, started, expires);
    }

    Address.sendValue(account, value);
  }


  //writable onlyDelegates
  function setCollection( CollectionSettings memory newConfig ) external onlyDelegates{
    bytes22 collectionKey = getCollectionKey(newConfig.collectionAddress, newConfig.collectionId);
    CollectionSettings memory prevConfig = collectionSettings[ collectionKey ];
    if( prevConfig.index == 0 ){
      newConfig.index = uint16(collections.length);
      collections.push( collectionKey );
    }
    else{
      newConfig.index = prevConfig.index;
    }

    collectionSettings[ collectionKey ] = newConfig;
    emit CollectionUpdate(newConfig.collectionAddress, newConfig.isActive, newConfig.ethPrice);
  }


  //internal
  function _updateSubscription( uint32 seconds_, address account ) internal {
    uint32 ts = uint32( block.timestamp );
    Subscription memory sub = subscriptions[ account ];

    //new subscription
    if( sub.created == 0 ){
      subscriptions[ account ] = Subscription(
        msg.value,
        ts,
        ts,
        ts + seconds_
      );
      emit SubscriptionUpdate(account, ts, ts + seconds_);
    }
    //expired re-sub
    else if( sub.expires < ts ){
      subscriptions[ account ] = Subscription(
        msg.value,
        sub.created,
        ts,
        ts + seconds_
      );
      emit SubscriptionUpdate(account, ts, ts + seconds_);
    }
    //extension
    else{
      subscriptions[ account ] = Subscription(
        sub.value + msg.value,
        sub.created,
        sub.started,
        sub.expires + seconds_
      );
      emit SubscriptionUpdate(account, sub.started, sub.expires + seconds_);
    }
  }
}