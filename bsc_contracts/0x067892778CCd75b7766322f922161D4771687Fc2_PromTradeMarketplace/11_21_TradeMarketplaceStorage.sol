// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity >=0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPromAddressRegistry {
  function bundleMarketplace() external view returns (address);

  function isTokenEligible(address) external view returns (bool);

  function isTradeCollectionEnabled(address) external view returns (uint16);

  function tradeMarketplaceFeeReceiver() external view returns (address);
}

interface IPromOracle {
  function convertTokenValue(
    address,
    uint256,
    address
  ) external returns (uint256);
}

contract TradeMarketplaceStorage {
  bytes32 internal constant ADMIN_SETTER = keccak256("ADMIN_SETTER");
  bytes32 internal constant PAUSER = keccak256("PAUSER");

  /// @notice Structure for listed items
  struct Listing {
    uint256 quantity;
    address payToken;
    uint256 pricePerItem;
    uint256 startingTime;
    uint256 endTime;
    uint256 nonce;
  }

  /// @notice Structure for offer
  struct Offer {
    IERC20 payToken;
    uint256 quantity;
    uint256 pricePerItem;
    uint256 deadline;
    uint256 offerNonce;
  }

  struct CollectionRoyalty {
    uint16 royalty;
    address feeRecipient;
  }

  uint16 public promFeeDiscount; // % of discount from 0 to 10000

  /// @notice NftAddress -> Token ID -> Owner -> Listing item
  mapping(address => mapping(uint256 => mapping(address => Listing)))
    public listings;

  /// @notice NftAddress -> Token ID -> Offerer -> Offer
  mapping(address => mapping(uint256 => mapping(address => Offer)))
    public offers;

  /// @notice NftAddress -> Royalty
  mapping(address => CollectionRoyalty) public collectionRoyalties;

  address public promToken;
  IPromOracle public oracle;

  /// @notice Address registry
  IPromAddressRegistry public addressRegistry;

  bytes4 internal constant INTERFACE_ID_ERC721 = 0x80ac58cd;
  bytes4 internal constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

  /// @notice Events for the contract
  event ItemListed(
    address indexed owner,
    address indexed nft,
    uint256 tokenId,
    uint256 quantity,
    address payToken,
    uint256 pricePerItem,
    uint256 startingTime,
    uint256 endTime
  );
  event ItemSold(
    address indexed seller,
    address indexed buyer,
    address indexed nft,
    uint256 tokenId,
    uint256 quantity,
    address payToken,
    uint256 pricePerItem
  );
  event ItemSoldInBundle(
    address indexed seller,
    address indexed nft,
    uint256 tokenId
  );
  event ItemUpdated(
    address indexed owner,
    address indexed nft,
    uint256 tokenId,
    address payToken,
    uint256 newPrice
  );
  event ItemCanceled(
    address indexed owner,
    address indexed nft,
    uint256 tokenId
  );
  event OfferCreated(
    address indexed creator,
    address indexed nft,
    uint256 tokenId,
    uint256 quantity,
    address payToken,
    uint256 pricePerItem,
    uint256 deadline
  );
  event OfferCanceled(
    address indexed creator,
    address indexed nft,
    uint256 tokenId
  );
  event UpdatePlatformFee(uint16 platformFee);
  event RoyaltyPayed(address collection, uint256 amount);
}