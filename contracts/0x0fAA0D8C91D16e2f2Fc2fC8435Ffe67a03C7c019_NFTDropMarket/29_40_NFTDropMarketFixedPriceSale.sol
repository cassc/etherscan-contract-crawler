// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "../../interfaces/internal/INFTLazyMintedCollectionMintCountTo.sol";
import "../../interfaces/internal/routes/INFTDropMarketFixedPriceSale.sol";

import "../../libraries/MerkleAddressLibrary.sol";
import "../../libraries/TimeLibrary.sol";
import "../shared/Constants.sol";
import "../shared/MarketFees.sol";
import "../shared/TxDeadline.sol";

import "./NFTDropMarketExhibition.sol";

/// @param limitPerAccount The limit of tokens an account can purchase.
error NFTDropMarketFixedPriceSale_Cannot_Buy_More_Than_Limit(uint256 limitPerAccount);
/// @param earlyAccessStartTime The time when early access starts, in seconds since the Unix epoch.
error NFTDropMarketFixedPriceSale_Early_Access_Not_Open(uint256 earlyAccessStartTime);
error NFTDropMarketFixedPriceSale_Early_Access_Start_Time_Has_Expired();
error NFTDropMarketFixedPriceSale_General_Access_Is_Open();
/// @param generalAvailabilityStartTime The start time of the general availability period, in seconds since the Unix
/// epoch.
error NFTDropMarketFixedPriceSale_General_Access_Not_Open(uint256 generalAvailabilityStartTime);
error NFTDropMarketFixedPriceSale_General_Availability_Start_Time_Has_Expired();
error NFTDropMarketFixedPriceSale_Invalid_Merkle_Proof();
error NFTDropMarketFixedPriceSale_Invalid_Merkle_Root();
error NFTDropMarketFixedPriceSale_Invalid_Merkle_Tree_URI();
error NFTDropMarketFixedPriceSale_Limit_Per_Account_Must_Be_Set();
error NFTDropMarketFixedPriceSale_Mint_Permission_Required();
error NFTDropMarketFixedPriceSale_Must_Be_Listed_For_Sale();
error NFTDropMarketFixedPriceSale_Must_Buy_At_Least_One_Token();
error NFTDropMarketFixedPriceSale_Must_Have_Non_Zero_Early_Access_Duration();
error NFTDropMarketFixedPriceSale_Must_Not_Be_Sold_Out();
error NFTDropMarketFixedPriceSale_Must_Not_Have_Pending_Sale();
error NFTDropMarketFixedPriceSale_Must_Support_Collection_Mint_Interface();
error NFTDropMarketFixedPriceSale_Must_Support_ERC721();
error NFTDropMarketFixedPriceSale_Only_Callable_By_Collection_Owner();
error NFTDropMarketFixedPriceSale_Start_Time_Too_Far_In_The_Future();
/// @param mintCost The total cost for this purchase.
error NFTDropMarketFixedPriceSale_Too_Much_Value_Provided(uint256 mintCost);

/**
 * @title Allows creators to list a drop collection for sale at a fixed price point.
 * @dev Listing a collection for sale in this market requires the collection to implement
 * the functions in `INFTLazyMintedCollectionMintCountTo` and to register that interface with ERC165.
 * Additionally the collection must implement access control, or more specifically:
 * `hasRole(bytes32(0), msg.sender)` must return true when called from the creator or admin's account
 * and `hasRole(keccak256("MINTER_ROLE", address(this)))` must return true for this market's address.
 * @author batu-inal & HardlyDifficult & philbirt & reggieag
 */
abstract contract NFTDropMarketFixedPriceSale is
  INFTDropMarketFixedPriceSale,
  TxDeadline,
  MarketFees,
  NFTDropMarketExhibition
{
  using AddressUpgradeable for address;
  using AddressUpgradeable for address payable;
  using ERC165Checker for address;
  using MerkleAddressLibrary for address;
  using SafeCast for uint256;
  using TimeLibrary for uint32;
  using TimeLibrary for uint256;

  /**
   * @notice Configuration for the terms of the sale.
   */
  struct FixedPriceSaleConfig {
    /****** Slot 0 (of this struct) ******/

    /// @notice The seller for the drop.
    address payable seller;
    /// @notice The fixed price per NFT in the collection.
    /// @dev The maximum price that can be set on an NFT is ~1.2M (2^80/10^18) ETH.
    uint80 price;
    /// @notice The max number of NFTs an account may mint in this sale.
    uint16 limitPerAccount;
    /****** Slot 1 ******/

    /// @notice Tracks how many NFTs a given user has already minted.
    mapping(address => uint256) userToMintedCount;
    /****** Slot 2 ******/

    /// @notice The start time of the general availability period, in seconds since the Unix epoch.
    /// @dev This must be >= `earlyAccessStartTime`.
    /// When set to 0, general availability was not scheduled and started as soon as the price was set.
    uint32 generalAvailabilityStartTime;
    /// @notice The time when early access purchasing may begin, in seconds since the Unix epoch.
    /// @dev This must be <= `generalAvailabilityStartTime`.
    /// When set to 0, early access was not scheduled and started as soon as the price was set.
    uint32 earlyAccessStartTime;
    // 192-bits available in this slot

    /****** Slot 3 ******/

    /// @notice Merkle roots representing which users have access to purchase during the early access period.
    /// @dev There may be many roots supported per sale where each is considered additive as any root may be used to
    /// purchase.
    mapping(bytes32 => bool) earlyAccessMerkleRoots;
  }

  /// @notice Stores the current sale information for all drop contracts.
  mapping(address => FixedPriceSaleConfig) private nftContractToFixedPriceSaleConfig;

  /**
   * @dev Protocol fee for edition mints in basis points.
   */
  uint256 private constant EDITION_PROTOCOL_FEE_IN_BASIS_POINTS = 500;

  /**
   * @notice Hash of the edition type name.
   * @dev This is precalculated in order to save gas on use.
   * `keccak256(abi.encodePacked(NFT_TIMED_EDITION_COLLECTION_TYPE))`
   */
  bytes32 private constant editionTypeHash = 0xee2afa3f960e108aca17013728aafa363a0f4485661d9b6f41c6b4ddb55008ee;

  /**
   * @notice The `role` type used to validate drop collections have granted this market access to mint.
   * @return `keccak256("MINTER_ROLE")`
   */
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  /**
   * @notice Emitted when an early access merkle root is added to a fixed price sale early access period.
   * @param nftContract The address of the NFT drop collection.
   * @param merkleRoot The merkleRoot used to authorize early access purchases.
   * @param merkleTreeUri The URI for the merkle tree represented by the merkleRoot.
   */
  event AddMerkleRootToFixedPriceSale(address indexed nftContract, bytes32 merkleRoot, string merkleTreeUri);

  /**
   * @notice Emitted when a collection is listed for sale.
   * @param nftContract The address of the NFT drop collection.
   * @param seller The address for the seller which listed this for sale.
   * @param price The price per NFT minted.
   * @param limitPerAccount The max number of NFTs an account may mint in this sale.
   * @param generalAvailabilityStartTime The time at which general purchases are available, in seconds since Unix epoch.
   * Can not be more than two years from the creation block timestamp.
   * @param earlyAccessStartTime The time at which early access purchases are available, in seconds since Unix epoch.
   * Can not be more than two years from the creation block timestamp.
   * @param merkleRoot The merkleRoot used to authorize early access purchases, or 0 if n/a.
   * @param merkleTreeUri The URI for the merkle tree represented by the merkleRoot, or empty if n/a.
   */
  event CreateFixedPriceSale(
    address indexed nftContract,
    address indexed seller,
    uint256 price,
    uint256 limitPerAccount,
    uint256 generalAvailabilityStartTime,
    uint256 earlyAccessStartTime,
    bytes32 merkleRoot,
    string merkleTreeUri
  );

  /**
   * @notice Emitted when NFTs are minted from the drop.
   * @dev The total price paid by the buyer is `totalFees + creatorRev`.
   * @param nftContract The address of the NFT drop collection.
   * @param buyer The address of the buyer.
   * @param firstTokenId The tokenId for the first NFT minted.
   * The other minted tokens are assigned sequentially, so `firstTokenId` - `firstTokenId + count - 1` were minted.
   * @param count The number of NFTs minted.
   * @param totalFees The amount of ETH that was sent to Foundation & referrals for this sale.
   * @param creatorRev The amount of ETH that was sent to the creator for this sale.
   */
  event MintFromFixedPriceDrop(
    address indexed nftContract,
    address indexed buyer,
    uint256 indexed firstTokenId,
    uint256 count,
    uint256 totalFees,
    uint256 creatorRev
  );

  /// @notice Requires the given NFT contract can mint at least 1 more NFT.
  modifier notSoldOut(address nftContract) {
    if (INFTLazyMintedCollectionMintCountTo(nftContract).numberOfTokensAvailableToMint() == 0) {
      revert NFTDropMarketFixedPriceSale_Must_Not_Be_Sold_Out();
    }
    _;
  }

  /// @notice Requires the msg.sender has the admin role on the given NFT contract.
  modifier onlyCollectionAdmin(address nftContract) {
    if (!IAccessControl(nftContract).hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
      revert NFTDropMarketFixedPriceSale_Only_Callable_By_Collection_Owner();
    }
    _;
  }

  /// @notice Requires the given NFT contract supports the interfaces currently required by this market for minting,
  /// and that it has granted this market the MINTER_ROLE.
  modifier onlySupportedCollectionType(address nftContract) {
    if (!nftContract.supportsInterface(type(INFTLazyMintedCollectionMintCountTo).interfaceId)) {
      // Must support the mint interface this market depends on.
      revert NFTDropMarketFixedPriceSale_Must_Support_Collection_Mint_Interface();
    }
    if (!nftContract.supportsERC165InterfaceUnchecked(type(IERC721).interfaceId)) {
      // Must be an ERC-721 NFT collection.
      revert NFTDropMarketFixedPriceSale_Must_Support_ERC721();
    }
    if (!IAccessControl(nftContract).hasRole(MINTER_ROLE, address(this))) {
      revert NFTDropMarketFixedPriceSale_Mint_Permission_Required();
    }
    _;
  }

  /// @notice Requires the merkle params have been assigned non-zero values.
  modifier onlyValidMerkle(bytes32 merkleRoot, string calldata merkleTreeUri) {
    if (merkleRoot == bytes32(0)) {
      revert NFTDropMarketFixedPriceSale_Invalid_Merkle_Root();
    }
    if (bytes(merkleTreeUri).length == 0) {
      revert NFTDropMarketFixedPriceSale_Invalid_Merkle_Tree_URI();
    }
    _;
  }

  /// @notice Requires that the time provided is not more than 2 years in the future.
  modifier onlyValidStartTime(uint256 startTime) {
    if (startTime > block.timestamp + MAX_SCHEDULED_TIME_IN_THE_FUTURE) {
      // Prevent arbitrarily large values from accidentally being set.
      revert NFTDropMarketFixedPriceSale_Start_Time_Too_Far_In_The_Future();
    }
    _;
  }

  /**
   * @notice Add a merkle root to an existing fixed price sale early access period.
   * @param nftContract The address of the NFT drop collection.
   * @param merkleRoot The merkleRoot used to authorize early access purchases.
   * @param merkleTreeUri The URI for the merkle tree represented by the merkleRoot.
   * @dev If you accidentally pass in the wrong merkleTreeUri for a merkleRoot,
   * you can call this function again to emit a new event with a new merkleTreeUri.
   */
  function addMerkleRootToFixedPriceSale(
    address nftContract,
    bytes32 merkleRoot,
    string calldata merkleTreeUri
  ) external notSoldOut(nftContract) onlyCollectionAdmin(nftContract) onlyValidMerkle(merkleRoot, merkleTreeUri) {
    FixedPriceSaleConfig storage saleConfig = nftContractToFixedPriceSaleConfig[nftContract];
    if (saleConfig.generalAvailabilityStartTime.hasBeenReached()) {
      // Start time may be 0, check if this collection has been listed to provide a better error message.
      if (saleConfig.seller == payable(0)) {
        revert NFTDropMarketFixedPriceSale_Must_Be_Listed_For_Sale();
      }
      // Adding users to the allow list is unnecessary when general access is open.
      revert NFTDropMarketFixedPriceSale_General_Access_Is_Open();
    }
    if (saleConfig.generalAvailabilityStartTime == saleConfig.earlyAccessStartTime) {
      // Must have non-zero early access duration, otherwise merkle roots are unnecessary.
      revert NFTDropMarketFixedPriceSale_Must_Have_Non_Zero_Early_Access_Duration();
    }

    saleConfig.earlyAccessMerkleRoots[merkleRoot] = true;

    emit AddMerkleRootToFixedPriceSale(nftContract, merkleRoot, merkleTreeUri);
  }

  /**
   * @notice [DEPRECATED] use `createFixedPriceSaleV3` instead.
   * Create a fixed price sale drop without an early access period.
   * @param nftContract The address of the NFT drop collection.
   * @param price The price per NFT minted.
   * Set price to 0 for a first come first serve airdrop-like drop.
   * @param limitPerAccount The max number of NFTs an account may mint in this sale.
   * @dev Notes:
   *   a) The sale is final and can not be updated or canceled.
   *   b) The sale is immediately kicked off.
   *   c) Any collection that abides by `INFTLazyMintedCollectionMintCountTo` and `IAccessControl` is supported.
   */
  function createFixedPriceSale(address nftContract, uint80 price, uint16 limitPerAccount) external {
    _createFixedPriceSale({
      nftContract: nftContract,
      exhibitionId: 0,
      price: price,
      limitPerAccount: limitPerAccount,
      generalAvailabilityStartTime: block.timestamp,
      earlyAccessStartTime: block.timestamp,
      merkleRoot: bytes32(0),
      merkleTreeUri: ""
    });
  }

  /**
   * @notice [DEPRECATED] use `createFixedPriceSaleV3` instead.
   * Create a fixed price sale drop without an early access period,
   * optionally scheduling the sale to start sometime in the future.
   * @param nftContract The address of the NFT drop collection.
   * @param price The price per NFT minted.
   * Set price to 0 for a first come first serve airdrop-like drop.
   * @param limitPerAccount The max number of NFTs an account may mint in this sale.
   * @param generalAvailabilityStartTime The time at which general purchases are available, in seconds since Unix epoch.
   * Set this to 0 in order to have general availability begin as soon as the transaction is mined.
   * Can not be more than two years from the creation block timestamp.
   * @param txDeadlineTime The deadline timestamp for the transaction to be mined, in seconds since Unix epoch.
   * Set this to 0 to send the transaction without a deadline.
   * @dev Notes:
   *   a) The sale is final and can not be updated or canceled.
   *   b) Any collection that abides by `INFTLazyMintedCollectionMintCountTo` and `IAccessControl` is supported.
   */
  function createFixedPriceSaleV2(
    address nftContract,
    uint256 price,
    uint256 limitPerAccount,
    uint256 generalAvailabilityStartTime,
    uint256 txDeadlineTime
  ) external {
    createFixedPriceSaleV3({
      nftContract: nftContract,
      exhibitionId: 0,
      price: price,
      limitPerAccount: limitPerAccount,
      generalAvailabilityStartTime: generalAvailabilityStartTime,
      txDeadlineTime: txDeadlineTime
    });
  }

  /**
   * @notice Create a fixed price sale drop without an early access period,
   * optionally scheduling the sale to start sometime in the future.
   * @param nftContract The address of the NFT drop collection.
   * @param exhibitionId The exhibition to associate this fix priced sale to.
   * Set this to 0 to exist outside of an exhibition.
   * @param price The price per NFT minted.
   * Set price to 0 for a first come first serve airdrop-like drop.
   * @param limitPerAccount The max number of NFTs an account may mint in this sale.
   * @param generalAvailabilityStartTime The time at which general purchases are available, in seconds since Unix epoch.
   * Set this to 0 in order to have general availability begin as soon as the transaction is mined.
   * Can not be more than two years from the creation block timestamp.
   * @param txDeadlineTime The deadline timestamp for the transaction to be mined, in seconds since Unix epoch.
   * Set this to 0 to send the transaction without a deadline.
   * @dev Notes:
   *   a) The sale is final and can not be updated or canceled.
   *   b) Any collection that abides by `INFTLazyMintedCollectionMintCountTo` and `IAccessControl` is supported.
   */
  function createFixedPriceSaleV3(
    address nftContract,
    uint256 exhibitionId,
    uint256 price,
    uint256 limitPerAccount,
    uint256 generalAvailabilityStartTime,
    uint256 txDeadlineTime
  ) public txDeadlineNotExpired(txDeadlineTime) {
    // When generalAvailabilityStartTime is not specified, default to now.
    if (generalAvailabilityStartTime == 0) {
      generalAvailabilityStartTime = block.timestamp;
    } else if (generalAvailabilityStartTime.hasExpired()) {
      // The start time must be now or in the future.
      revert NFTDropMarketFixedPriceSale_General_Availability_Start_Time_Has_Expired();
    }

    _createFixedPriceSale({
      nftContract: nftContract,
      exhibitionId: exhibitionId,
      price: price,
      limitPerAccount: limitPerAccount,
      generalAvailabilityStartTime: generalAvailabilityStartTime,
      earlyAccessStartTime: generalAvailabilityStartTime,
      merkleRoot: bytes32(0),
      merkleTreeUri: ""
    });
  }

  /**
   * @notice [DEPRECATED] use `createFixedPriceSaleWithEarlyAccessAllowlistV2` instead.
   * Create a fixed price sale drop with an early access period.
   * @param nftContract The address of the NFT drop collection.
   * @param price The price per NFT minted.
   * Set price to 0 for a first come first serve airdrop-like drop.
   * @param limitPerAccount The max number of NFTs an account may mint in this sale.
   * @param generalAvailabilityStartTime The time at which general purchases are available, in seconds since Unix epoch.
   * This value must be > `earlyAccessStartTime`.
   * @param earlyAccessStartTime The time at which early access purchases are available, in seconds since Unix epoch.
   * Set this to 0 in order to have early access begin as soon as the transaction is mined.
   * @param merkleRoot The merkleRoot used to authorize early access purchases.
   * @param merkleTreeUri The URI for the merkle tree represented by the merkleRoot.
   * @param txDeadlineTime The deadline timestamp for the transaction to be mined, in seconds since Unix epoch.
   * Set this to 0 to send the transaction without a deadline.
   * @dev Notes:
   *   a) The sale is final and can not be updated or canceled.
   *   b) Any collection that abides by `INFTLazyMintedCollectionMintCountTo` and `IAccessControl` is supported.
   */
  function createFixedPriceSaleWithEarlyAccessAllowlist(
    address nftContract,
    uint256 price,
    uint256 limitPerAccount,
    uint256 generalAvailabilityStartTime,
    uint256 earlyAccessStartTime,
    bytes32 merkleRoot,
    string calldata merkleTreeUri,
    uint256 txDeadlineTime
  ) external {
    createFixedPriceSaleWithEarlyAccessAllowlistV2({
      nftContract: nftContract,
      exhibitionId: 0,
      price: price,
      limitPerAccount: limitPerAccount,
      generalAvailabilityStartTime: generalAvailabilityStartTime,
      earlyAccessStartTime: earlyAccessStartTime,
      merkleRoot: merkleRoot,
      merkleTreeUri: merkleTreeUri,
      txDeadlineTime: txDeadlineTime
    });
  }

  /**
   * @notice Create a fixed price sale drop with an early access period.
   * @param nftContract The address of the NFT drop collection.
   * @param exhibitionId The exhibition to associate this fix priced sale to.
   * Set this to 0 to exist outside of an exhibition.
   * @param price The price per NFT minted.
   * Set price to 0 for a first come first serve airdrop-like drop.
   * @param limitPerAccount The max number of NFTs an account may mint in this sale.
   * @param generalAvailabilityStartTime The time at which general purchases are available, in seconds since Unix epoch.
   * This value must be > `earlyAccessStartTime`.
   * @param earlyAccessStartTime The time at which early access purchases are available, in seconds since Unix epoch.
   * Set this to 0 in order to have early access begin as soon as the transaction is mined.
   * @param merkleRoot The merkleRoot used to authorize early access purchases.
   * @param merkleTreeUri The URI for the merkle tree represented by the merkleRoot.
   * @param txDeadlineTime The deadline timestamp for the transaction to be mined, in seconds since Unix epoch.
   * Set this to 0 to send the transaction without a deadline.
   * @dev Notes:
   *   a) The sale is final and can not be updated or canceled.
   *   b) Any collection that abides by `INFTLazyMintedCollectionMintCountTo` and `IAccessControl` is supported.
   */
  function createFixedPriceSaleWithEarlyAccessAllowlistV2(
    address nftContract,
    uint256 exhibitionId,
    uint256 price,
    uint256 limitPerAccount,
    uint256 generalAvailabilityStartTime,
    uint256 earlyAccessStartTime,
    bytes32 merkleRoot,
    string calldata merkleTreeUri,
    uint256 txDeadlineTime
  ) public txDeadlineNotExpired(txDeadlineTime) onlyValidMerkle(merkleRoot, merkleTreeUri) {
    // When earlyAccessStartTime is not specified, default to now.
    if (earlyAccessStartTime == 0) {
      earlyAccessStartTime = block.timestamp;
    } else if (earlyAccessStartTime.hasExpired()) {
      // The start time must be now or in the future.
      revert NFTDropMarketFixedPriceSale_Early_Access_Start_Time_Has_Expired();
    }
    if (earlyAccessStartTime >= generalAvailabilityStartTime) {
      // Early access period must start before GA period.
      revert NFTDropMarketFixedPriceSale_Must_Have_Non_Zero_Early_Access_Duration();
    }

    _createFixedPriceSale(
      nftContract,
      exhibitionId,
      price,
      limitPerAccount,
      generalAvailabilityStartTime,
      earlyAccessStartTime,
      merkleRoot,
      merkleTreeUri
    );
  }

  /**
   * @notice Used to mint `count` number of NFTs from the collection during general availability.
   * @param nftContract The address of the NFT drop collection.
   * @param count The number of NFTs to mint.
   * @param buyReferrer The address which referred this purchase, or address(0) if n/a.
   * @return firstTokenId The tokenId for the first NFT minted.
   * The other minted tokens are assigned sequentially, so `firstTokenId` - `firstTokenId + count - 1` were minted.
   * @dev This call may revert if the collection has sold out, has an insufficient number of tokens available,
   * or if the market's minter permissions were removed.
   * If insufficient msg.value is included, the msg.sender's available FETH token balance will be used.
   */
  function mintFromFixedPriceSale(
    address nftContract,
    uint16 count,
    address payable buyReferrer
  ) external payable returns (uint256 firstTokenId) {
    FixedPriceSaleConfig storage saleConfig = nftContractToFixedPriceSaleConfig[nftContract];

    // Must be in general access period.
    if (!saleConfig.generalAvailabilityStartTime.hasBeenReached()) {
      revert NFTDropMarketFixedPriceSale_General_Access_Not_Open(saleConfig.generalAvailabilityStartTime);
    }

    firstTokenId = _mintFromFixedPriceSale(saleConfig, nftContract, count, buyReferrer);
  }

  /**
   * @notice Used to mint `count` number of NFTs from the collection during early access.
   * @param nftContract The address of the NFT drop collection.
   * @param count The number of NFTs to mint.
   * @param buyReferrer The address which referred this purchase, or address(0) if n/a.
   * @param proof The merkle proof used to authorize this purchase.
   * @return firstTokenId The tokenId for the first NFT minted.
   * The other minted tokens are assigned sequentially, so `firstTokenId` - `firstTokenId + count - 1` were minted.
   * @dev This call may revert if the collection has sold out, has an insufficient number of tokens available,
   * or if the market's minter permissions were removed.
   * If insufficient msg.value is included, the msg.sender's available FETH token balance will be used.
   */
  function mintFromFixedPriceSaleWithEarlyAccessAllowlist(
    address nftContract,
    uint256 count,
    address payable buyReferrer,
    bytes32[] calldata proof
  ) external payable returns (uint256 firstTokenId) {
    FixedPriceSaleConfig storage saleConfig = nftContractToFixedPriceSaleConfig[nftContract];

    // Skip proof check if in general access period.
    if (!saleConfig.generalAvailabilityStartTime.hasBeenReached()) {
      // Must be in early access period or beyond.
      if (!saleConfig.earlyAccessStartTime.hasBeenReached()) {
        if (saleConfig.earlyAccessStartTime == saleConfig.generalAvailabilityStartTime) {
          // This just provides a more targeted error message for the case where early access is not enabled.
          revert NFTDropMarketFixedPriceSale_Must_Have_Non_Zero_Early_Access_Duration();
        }
        revert NFTDropMarketFixedPriceSale_Early_Access_Not_Open(saleConfig.earlyAccessStartTime);
      }

      bytes32 root = _msgSender().getMerkleRootForAddress(proof);
      if (!saleConfig.earlyAccessMerkleRoots[root]) {
        revert NFTDropMarketFixedPriceSale_Invalid_Merkle_Proof();
      }
    }

    firstTokenId = _mintFromFixedPriceSale(saleConfig, nftContract, count, buyReferrer);
  }

  function _createFixedPriceSale(
    address nftContract,
    uint256 exhibitionId,
    uint256 price,
    uint256 limitPerAccount,
    uint256 generalAvailabilityStartTime,
    uint256 earlyAccessStartTime,
    bytes32 merkleRoot,
    string memory merkleTreeUri
  )
    private
    onlySupportedCollectionType(nftContract)
    notSoldOut(nftContract)
    onlyCollectionAdmin(nftContract)
    onlyValidStartTime(generalAvailabilityStartTime)
  {
    // Validate input params.
    if (limitPerAccount == 0) {
      // A non-zero limit is required.
      revert NFTDropMarketFixedPriceSale_Limit_Per_Account_Must_Be_Set();
    }

    // Confirm this collection has not already been listed.
    FixedPriceSaleConfig storage saleConfig = nftContractToFixedPriceSaleConfig[nftContract];
    if (saleConfig.seller != payable(0)) {
      revert NFTDropMarketFixedPriceSale_Must_Not_Have_Pending_Sale();
    }

    // Save the sale details.
    address payable sender = payable(_msgSender());
    saleConfig.seller = sender;
    // Any price is supported, including 0.
    saleConfig.price = price.toUint80();
    saleConfig.limitPerAccount = limitPerAccount.toUint16();

    if (generalAvailabilityStartTime != block.timestamp) {
      // If starting now we don't need to write to storage
      // Safe cast is not required since onlyValidStartTime confirms the max is within range.
      saleConfig.generalAvailabilityStartTime = uint32(generalAvailabilityStartTime);
    }

    if (earlyAccessStartTime != block.timestamp) {
      // If starting now we don't need to write to storage
      // Safe cast is not required since callers require earlyAccessStartTime <= generalAvailabilityStartTime.
      saleConfig.earlyAccessStartTime = uint32(earlyAccessStartTime);
    }

    // Store the merkle root if there's an early access period
    if (merkleRoot != 0) {
      saleConfig.earlyAccessMerkleRoots[merkleRoot] = true;
    }

    _addCollectionToExhibition(nftContract, exhibitionId);

    emit CreateFixedPriceSale({
      nftContract: nftContract,
      seller: sender,
      price: price,
      limitPerAccount: limitPerAccount,
      generalAvailabilityStartTime: generalAvailabilityStartTime,
      earlyAccessStartTime: earlyAccessStartTime,
      merkleRoot: merkleRoot,
      merkleTreeUri: merkleTreeUri
    });
  }

  function _mintFromFixedPriceSale(
    FixedPriceSaleConfig storage saleConfig,
    address nftContract,
    uint256 count,
    address payable buyReferrer
  ) private returns (uint256 firstTokenId) {
    // Validate input params.
    if (count == 0) {
      revert NFTDropMarketFixedPriceSale_Must_Buy_At_Least_One_Token();
    }

    // Confirm that the buyer will not exceed the limit specified after minting.
    address sender = _msgSender();
    uint256 minted = saleConfig.userToMintedCount[sender] + count;
    if (minted > saleConfig.limitPerAccount) {
      if (saleConfig.limitPerAccount == 0) {
        // Provide a more targeted error if the collection has not been listed.
        revert NFTDropMarketFixedPriceSale_Must_Be_Listed_For_Sale();
      }
      revert NFTDropMarketFixedPriceSale_Cannot_Buy_More_Than_Limit(saleConfig.limitPerAccount);
    }
    saleConfig.userToMintedCount[sender] = minted;

    // Calculate the total cost, considering the `count` requested.
    uint256 mintCost;
    unchecked {
      // Can not overflow as 2^80 * 2^16 == 2^96 max which fits in 256 bits.
      mintCost = uint256(saleConfig.price) * count;
    }

    // The sale price is immutable so the buyer is aware of how much they will be paying when their tx is broadcasted.
    if (msg.value > mintCost) {
      // Since price is known ahead of time, if too much ETH is sent then something went wrong.
      revert NFTDropMarketFixedPriceSale_Too_Much_Value_Provided(mintCost);
    }
    // Withdraw from the user's available FETH balance if insufficient msg.value was included.
    _tryUseFETHBalance({ totalAmount: mintCost, shouldRefundSurplus: false });

    // Mint the NFTs.
    // Safe cast is not required, above confirms count <= limitPerAccount which is uint16.
    firstTokenId = INFTLazyMintedCollectionMintCountTo(nftContract).mintCountTo(uint16(count), sender);

    (address payable curator, uint16 takeRateInBasisPoints) = _getExhibitionByCollection(nftContract);

    // Distribute revenue from this sale.
    (uint256 totalFees, uint256 creatorRev, ) = _distributeFunds({
      nftContract: nftContract,
      tokenId: firstTokenId,
      seller: saleConfig.seller,
      price: mintCost,
      buyReferrer: buyReferrer,
      sellerReferrerPaymentAddress: curator,
      sellerReferrerTakeRateInBasisPoints: takeRateInBasisPoints
    });

    emit MintFromFixedPriceDrop({
      nftContract: nftContract,
      buyer: sender,
      firstTokenId: firstTokenId,
      count: count,
      totalFees: totalFees,
      creatorRev: creatorRev
    });
  }

  /**
   * @notice Returns the max number of NFTs a given account may mint.
   * @param nftContract The address of the NFT drop collection.
   * @param user The address of the user which will be minting.
   * @return numberThatCanBeMinted How many NFTs the user can mint.
   */
  function getAvailableCountFromFixedPriceSale(
    address nftContract,
    address user
  ) external view returns (uint256 numberThatCanBeMinted) {
    (, , uint256 limitPerAccount, uint256 numberOfTokensAvailableToMint, bool marketCanMint, , ) = getFixedPriceSale(
      nftContract
    );
    if (!marketCanMint) {
      // No one can mint in the current state.
      return 0;
    }
    uint256 mintedCount = nftContractToFixedPriceSaleConfig[nftContract].userToMintedCount[user];
    if (mintedCount >= limitPerAccount) {
      // User has exhausted their limit.
      return 0;
    }

    unchecked {
      // Safe math is not required due to the if statement directly above.
      numberThatCanBeMinted = limitPerAccount - mintedCount;
    }
    if (numberThatCanBeMinted > numberOfTokensAvailableToMint) {
      // User has more tokens available than the collection has available.
      numberThatCanBeMinted = numberOfTokensAvailableToMint;
    }
  }

  /**
   * @notice Returns details for a drop collection's fixed price sale.
   * @param nftContract The address of the NFT drop collection.
   * @return seller The address of the seller which listed this drop for sale.
   * This value will be address(0) if the collection is not listed or has sold out.
   * @return price The price per NFT minted.
   * @return limitPerAccount The max number of NFTs an account may mint in this sale.
   * @return numberOfTokensAvailableToMint The number of NFTs available to mint.
   * @return marketCanMint True if this contract has permissions to mint from the given collection.
   * @return generalAvailabilityStartTime The time at which general availability starts.
   * When set to 0, general availability was not scheduled and started as soon as the price was set.
   * @return earlyAccessStartTime The timestamp at which the allowlist period starts.
   * When set to 0, early access was not scheduled and started as soon as the price was set.
   */
  function getFixedPriceSale(
    address nftContract
  )
    public
    view
    returns (
      address payable seller,
      uint256 price,
      uint256 limitPerAccount,
      uint256 numberOfTokensAvailableToMint,
      bool marketCanMint,
      uint256 generalAvailabilityStartTime,
      uint256 earlyAccessStartTime
    )
  {
    try INFTLazyMintedCollectionMintCountTo(nftContract).numberOfTokensAvailableToMint() returns (uint256 count) {
      if (count != 0) {
        try IAccessControl(nftContract).hasRole(MINTER_ROLE, address(this)) returns (bool hasRole) {
          FixedPriceSaleConfig storage saleConfig = nftContractToFixedPriceSaleConfig[nftContract];
          seller = saleConfig.seller;
          price = saleConfig.price;
          limitPerAccount = saleConfig.limitPerAccount;
          numberOfTokensAvailableToMint = count;
          marketCanMint = hasRole;
          earlyAccessStartTime = saleConfig.earlyAccessStartTime;
          generalAvailabilityStartTime = saleConfig.generalAvailabilityStartTime;
        } catch {
          // The contract is not supported - return default values.
        }
      }
      // Else minted completed -- return default values.
    } catch {
      // Contract not supported or self destructed - return default values
    }
  }

  /**
   * @notice Checks if a given merkle root has been authorized to purchase from a given drop collection.
   * @param nftContract The address of the NFT drop collection.
   * @param merkleRoot The merkle root to check.
   * @return supported True if the merkle root has been authorized.
   */
  function getFixedPriceSaleEarlyAccessAllowlistSupported(
    address nftContract,
    bytes32 merkleRoot
  ) external view returns (bool supported) {
    supported = nftContractToFixedPriceSaleConfig[nftContract].earlyAccessMerkleRoots[merkleRoot];
  }

  /**
   * @inheritdoc MarketFees
   * @dev Offers a reduced protocol fee for NFT edition collection sales.
   */
  function _getProtocolFee(
    address nftContract
  ) internal view virtual override returns (uint256 protocolFeeInBasisPoints) {
    try INFTCollectionType(nftContract).getNFTCollectionType() returns (string memory nftCollectionType) {
      if (keccak256(abi.encodePacked(nftCollectionType)) == editionTypeHash) {
        return EDITION_PROTOCOL_FEE_IN_BASIS_POINTS;
      }
    } catch {
      // Fall through to use the default fee of 15% instead.
      // If the collection implements a fallback function, decoding will revert and cause the sale to fail.
    }
    return super._getProtocolFee(nftContract);
  }

  /**
   * @inheritdoc MarketSharedCore
   * @dev Returns the seller for a collection if listed and not already sold out.
   */
  function _getSellerOf(
    address nftContract,
    uint256 /* tokenId */
  ) internal view virtual override returns (address payable seller) {
    (seller, , , , , , ) = getFixedPriceSale(nftContract);
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[1_000] private __gap;
}