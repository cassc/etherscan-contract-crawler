// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;


bytes4 constant INTERFACE_ID_ERC2981 = 0x2a55205a;
bytes4 constant INTERFACE_ID_ERC1155 = 0xd9b67a26;
bytes4 constant INTERFACE_ID_ERC721 = 0x80ac58cd;


uint256 constant INVERSE_BASIS = 10000;
address constant NATIVE_ETH = address(1);


bytes32 constant PAYMENT_TYPEHASH = keccak256("Payment(address token,uint256 amount)");
bytes32 constant FEES_TYPEHASH = keccak256("Fees(uint256 royaltyPoints,uint256 marketPoints,uint256 slippageTolerance)");
bytes32 constant ORDER_TYPEHASH = keccak256("Order(address maker,address collection,uint256 tokenId,uint256 amount,uint256 expiry,Fees fees,Payment[] paymentMethods,bool paymentsCombined,uint8 order_type,uint256 salt)Fees(uint256 royaltyPoints,uint256 marketPoints,uint256 slippageTolerance)Payment(address token,uint256 amount)");



enum AssetType { UNCHECKED, ERC20, ERC721, ERC1155 }
enum OrderType { LISTING, ITEM_OFFER, COLLECTION_OFFER }



struct Collection {
  AssetType asset_type;
  bool supports2981;
  address approvedCollectionOwner;
  uint256 royalty_points;
  address royalty_receiver;
}

struct Payment {
  address token;
  uint256 amount;
}

struct Fees {
  uint256 royaltyPoints;
  uint256 marketPoints;
  uint256 slippageTolerance;
}

struct Order {
  address maker;
  address collection;
  uint256 tokenId;
  uint256 amount;
  uint256 expiry;
  Fees fees;
  Payment[] paymentMethods;
  bool paymentsCombined;
  OrderType order_type;
  uint256 salt;
}


struct Permit_ERC20 {
  address token;
  address owner;
  uint256 value;
  uint256 deadline;
  bytes signature;
}


struct Executable {
  Order order;
  uint256 paymentIndex;
  uint256 collectionOfferTokenId;
  bytes signature;
}