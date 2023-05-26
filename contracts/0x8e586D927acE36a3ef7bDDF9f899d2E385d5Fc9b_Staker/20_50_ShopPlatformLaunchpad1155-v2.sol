// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./FeeOwner.sol";
import "./Fee1155NFTLockable.sol";
import "./Staker.sol";

/**
  @title A Shop contract for selling NFTs via direct minting through particular
         pools with specific participation requirements.
  @author Tim Clancy

  This launchpad contract is specifically optimized for SuperFarm direct use.
*/
contract ShopPlatformLaunchpad1155 is ERC1155Holder, Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /// A version number for this Shop contract's interface.
  uint256 public version = 2;

  /// @dev A mask for isolating an item's group ID.
  uint256 constant GROUP_MASK = uint256(uint128(~0)) << 128;

  /// A user-specified Fee1155 contract to support selling items from.
  Fee1155NFTLockable public item;

  /// A user-specified FeeOwner to receive a portion of Shop earnings.
  FeeOwner public feeOwner;

  /// A user-specified Staker contract to spend user points on.
  Staker[] public stakers;

  /**
    A limit on the number of items that a particular address may purchase across
    any number of pools in the launchpad.
  */
  uint256 public globalPurchaseLimit;

  /// A mapping of addresses to the number of items each has purchased globally.
  mapping (address => uint256) public globalPurchaseCounts;

  /// The address of the orignal owner of the item contract.
  address public originalOwner;

  /// Whether ownership is locked to disable clawback.
  bool public ownershipLocked;

  /// A mapping of item group IDs to their next available issue number minus one.
  mapping (uint256 => uint256) public nextItemIssues;

  /// The next available ID to be assumed by the next whitelist added.
  uint256 public nextWhitelistId;

  /**
    A mapping of whitelist IDs to specific Whitelist elements. Whitelists may be
    shared between pools via specifying their ID in a pool requirement.
  */
  mapping (uint256 => Whitelist) public whitelists;

  /// The next available ID to be assumed by the next pool added.
  uint256 public nextPoolId;

  /// A mapping of pool IDs to pools.
  mapping (uint256 => Pool) public pools;

  /**
    This struct is a source of mapping-free input to the `addPool` function.

    @param name A name for the pool.
    @param startBlock The first block where this pool begins allowing purchases.
    @param endBlock The final block where this pool allows purchases.
    @param purchaseLimit The maximum number of items a single address may purchase from this pool.
    @param requirement A PoolRequirement requisite for users who want to participate in this pool.
  */
  struct PoolInput {
    string name;
    uint256 startBlock;
    uint256 endBlock;
    uint256 purchaseLimit;
    PoolRequirement requirement;
  }

  /**
    This struct tracks information about a single item pool in the Shop.

    @param name A name for the pool.
    @param startBlock The first block where this pool begins allowing purchases.
    @param endBlock The final block where this pool allows purchases.
    @param purchaseLimit The maximum number of items a single address may purchase from this pool.
    @param purchaseCounts A mapping of addresses to the number of items each has purchased from this pool.
    @param requirement A PoolRequirement requisite for users who want to participate in this pool.
    @param itemGroups An array of all item groups currently present in this pool.
    @param currentPoolVersion A version number hashed with item group IDs before
           being used as keys to other mappings. This supports efficient
           invalidation of stale mappings.
    @param itemCaps A mapping of item group IDs to the maximum number this pool is allowed to mint.
    @param itemMinted A mapping of item group IDs to the number this pool has currently minted.
    @param itemPricesLength A mapping of item group IDs to the number of price assets available to purchase with.
    @param itemPrices A mapping of item group IDs to a mapping of available PricePair assets available to purchase with.
  */
  struct Pool {
    string name;
    uint256 startBlock;
    uint256 endBlock;
    uint256 purchaseLimit;
    mapping (address => uint256) purchaseCounts;
    PoolRequirement requirement;
    uint256[] itemGroups;
    uint256 currentPoolVersion;
    mapping (bytes32 => uint256) itemCaps;
    mapping (bytes32 => uint256) itemMinted;
    mapping (bytes32 => uint256) itemPricesLength;
    mapping (bytes32 => mapping (uint256 => PricePair)) itemPrices;
  }

  /**
    This struct tracks information about a prerequisite for a user to
    participate in a pool.

    @param requiredType
      A sentinel value for the specific type of asset being required.
        0 = a pool which requires no specific assets to participate.
        1 = an ERC-20 token, see `requiredAsset`.
        2 = an NFT item, see `requiredAsset`.
    @param requiredAsset
      Some more specific information about the asset to require.
        If the `requiredType` is 1, we use this address to find the ERC-20
        token that we should be specifically requiring holdings of.
        If the `requiredType` is 2, we use this address to find the item
        contract that we should be specifically requiring holdings of.
    @param requiredAmount The amount of the specified `requiredAsset` required.
    @param whitelistId
      The ID of an address whitelist to restrict participants in this pool. To
      participate, a purchaser must have their address present in the
      corresponding whitelist. Other requirements from `requiredType` apply.
      An ID of 0 is a sentinel value for no whitelist: a public pool.
  */
  struct PoolRequirement {
    uint256 requiredType;
    address requiredAsset;
    uint256 requiredAmount;
    uint256 whitelistId;
  }

  /**
    This struct tracks information about a single asset with associated price
    that an item is being sold in the shop for.

    @param assetType A sentinel value for the specific type of asset being used.
                     0 = non-transferrable points from a Staker; see `asset`.
                     1 = Ether.
                     2 = an ERC-20 token, see `asset`.
    @param asset Some more specific information about the asset to charge in.
                 If the `assetType` is 0, we convert the given address to an
                 integer index for finding a specific Staker from `stakers`.
                 If the `assetType` is 1, we ignore this field.
                 If the `assetType` is 2, we use this address to find the ERC-20
                 token that we should be specifically charging with.
    @param price The amount of the specified `assetType` and `asset` to charge.
  */
  struct PricePair {
    uint256 assetType;
    address asset;
    uint256 price;
  }

  /**
    This struct is a source of mapping-free input to the `addWhitelist` function.

    @param expiryBlock A block number after which this whitelist is automatically considered inactive, no matter the value of `isActive`.
    @param isActive Whether or not this whitelist is actively restricting purchases in blocks before `expiryBlock`.
    @param addresses An array of addresses to whitelist for participation in a purchase.
  */
  struct WhitelistInput {
    uint256 expiryBlock;
    bool isActive;
    address[] addresses;
  }

  /**
    This struct tracks information about a single whitelist known to this
    launchpad. Whitelists may be shared across potentially-multiple item pools.

    @param expiryBlock A block number after which this whitelist is automatically considered inactive, no matter the value of `isActive`.
    @param isActive Whether or not this whitelist is actively restricting purchases in blocks before `expiryBlock`.
    @param currentWhitelistVersion A version number hashed with item group IDs before being used as keys to other mappings. This supports efficient invalidation of stale mappings.
    @param addresses A mapping of hashed addresses to a flag indicating whether this whitelist allows the address to participate in a purchase.
  */
  struct Whitelist {
    uint256 expiryBlock;
    bool isActive;
    uint256 currentWhitelistVersion;
    mapping (bytes32 => bool) addresses;
  }

  /**
    This struct tracks information about a single item being sold in a pool.

    @param groupId The group ID of the specific NFT in the collection being sold by a pool.
    @param cap The maximum number of items that a pool may mint of the specified `groupId`.
    @param minted The number of items that a pool has currently minted of the specified `groupId`.
    @param prices The PricePair options that may be used to purchase this item from its pool.
  */
  struct PoolItem {
    uint256 groupId;
    uint256 cap;
    uint256 minted;
    PricePair[] prices;
  }

  /**
    This struct contains the information gleaned from the `getPool` and
    `getPools` functions; it represents a single pool's data.

    @param name A name for the pool.
    @param startBlock The first block where this pool begins allowing purchases.
    @param endBlock The final block where this pool allows purchases.
    @param purchaseLimit The maximum number of items a single address may purchase from this pool.
    @param requirement A PoolRequirement requisite for users who want to participate in this pool.
    @param itemMetadataUri The metadata URI of the item collection being sold by this launchpad.
    @param items An array of PoolItems representing each item for sale in the pool.
  */
  struct PoolOutput {
    string name;
    uint256 startBlock;
    uint256 endBlock;
    uint256 purchaseLimit;
    PoolRequirement requirement;
    string itemMetadataUri;
    PoolItem[] items;
  }

  /**
    This struct contains the information gleaned from the `getPool` and
    `getPools` functions; it represents a single pool's data. It also includes
    additional information relevant to a user's address lookup.

    @param name A name for the pool.
    @param startBlock The first block where this pool begins allowing purchases.
    @param endBlock The final block where this pool allows purchases.
    @param purchaseLimit The maximum number of items a single address may purchase from this pool.
    @param requirement A PoolRequirement requisite for users who want to participate in this pool.
    @param itemMetadataUri The metadata URI of the item collection being sold by this launchpad.
    @param items An array of PoolItems representing each item for sale in the pool.
    @param purchaseCount The amount of items purchased from this pool by the specified address.
    @param whitelistStatus Whether or not the specified address is whitelisted for this pool.
  */
  struct PoolAddressOutput {
    string name;
    uint256 startBlock;
    uint256 endBlock;
    uint256 purchaseLimit;
    PoolRequirement requirement;
    string itemMetadataUri;
    PoolItem[] items;
    uint256 purchaseCount;
    bool whitelistStatus;
  }

  /// An event to track the original item contract owner clawing back ownership.
  event OwnershipClawback();

  /// An event to track the original item contract owner locking future clawbacks.
  event OwnershipLocked();

  /// An event to track the complete replacement of a pool's data.
  event PoolUpdated(uint256 poolId, PoolInput pool, uint256[] groupIds, uint256[] amounts, PricePair[][] pricePairs);

  /// An event to track the complete replacement of addresses in a whitelist.
  event WhitelistUpdated(uint256 whitelistId, address[] addresses);

  /// An event to track the addition of addresses to a whitelist.
  event WhitelistAddition(uint256 whitelistId, address[] addresses);

  /// An event to track the removal of addresses from a whitelist.
  event WhitelistRemoval(uint256 whitelistId, address[] addresses);

  // An event to track activating or deactivating a whitelist.
  event WhitelistActiveUpdate(uint256 whitelistId, bool isActive);

  // An event to track the purchase of items from a pool.
  event ItemPurchased(uint256 poolId, uint256[] itemIds, uint256 assetId, uint256[] amounts, address user);

  /// @dev a modifier which allows only `originalOwner` to call a function.
  modifier onlyOriginalOwner() {
    require(originalOwner == _msgSender(),
      "You are not the original owner of this contract.");
    _;
  }

  /**
    Construct a new Shop by providing it a FeeOwner.

    @param _item The address of the Fee1155NFTLockable item that will be minting sales.
    @param _feeOwner The address of the FeeOwner due a portion of Shop earnings.
    @param _stakers The addresses of any Stakers to permit spending points from.
    @param _globalPurchaseLimit A global limit on the number of items that a
      single address may purchase across all pools in the launchpad.
  */
  constructor(Fee1155NFTLockable _item, FeeOwner _feeOwner, Staker[] memory _stakers, uint256 _globalPurchaseLimit) public {
    item = _item;
    feeOwner = _feeOwner;
    stakers = _stakers;
    globalPurchaseLimit = _globalPurchaseLimit;

    nextWhitelistId = 1;
    originalOwner = item.owner();
    ownershipLocked = false;
  }

  /**
    A function which allows the caller to retrieve information about specific
    pools, the items for sale within, and the collection this launchpad uses.

    @param poolIds An array of pool IDs to retrieve information about.
  */
  function getPools(uint256[] calldata poolIds) external view returns (PoolOutput[] memory) {
    PoolOutput[] memory poolOutputs = new PoolOutput[](poolIds.length);
    for (uint256 i = 0; i < poolIds.length; i++) {
      uint256 poolId = poolIds[i];

      // Process output for each pool.
      PoolItem[] memory poolItems = new PoolItem[](pools[poolId].itemGroups.length);
      for (uint256 j = 0; j < pools[poolId].itemGroups.length; j++) {
        uint256 itemGroupId = pools[poolId].itemGroups[j];
        bytes32 itemKey = keccak256(abi.encodePacked(pools[poolId].currentPoolVersion, itemGroupId));

        // Parse each price the item is sold at.
        PricePair[] memory itemPrices = new PricePair[](pools[poolId].itemPricesLength[itemKey]);
        for (uint256 k = 0; k < pools[poolId].itemPricesLength[itemKey]; k++) {
          itemPrices[k] = pools[poolId].itemPrices[itemKey][k]; // TODO: add staker addresses to getter.
        }

        // Track the item.
        poolItems[j] = PoolItem({
          groupId: itemGroupId,
          cap: pools[poolId].itemCaps[itemKey],
          minted: pools[poolId].itemMinted[itemKey],
          prices: itemPrices
        });
      }

      // Track the pool.
      poolOutputs[i] = PoolOutput({
        name: pools[poolId].name,
        startBlock: pools[poolId].startBlock,
        endBlock: pools[poolId].endBlock,
        purchaseLimit: pools[poolId].purchaseLimit,
        requirement: pools[poolId].requirement,
        itemMetadataUri: item.metadataUri(),
        items: poolItems
      });
    }

    // Return the pools.
    return poolOutputs;
  }

  /**
    A function which allows the caller to retrieve the number of items specific
    addresses have purchased from specific pools.

    @param poolIds The IDs of the pools to check for addresses in `purchasers`.
    @param purchasers The addresses to check the purchase counts for.
  */
  function getPurchaseCounts(uint256[] calldata poolIds, address[] calldata purchasers) external view returns (uint256[][] memory) {
    uint256[][] memory purchaseCounts;
    for (uint256 i = 0; i < poolIds.length; i++) {
      uint256 poolId = poolIds[i];
      for (uint256 j = 0; j < purchasers.length; j++) {
        address purchaser = purchasers[j];
        purchaseCounts[j][i] = pools[poolId].purchaseCounts[purchaser];
      }
    }
    return purchaseCounts;
  }

  /**
    A function which allows the caller to retrieve information about specific
    pools, the items for sale within, and the collection this launchpad uses.
    A provided address differentiates this function from `getPools`; the added
    address enables this function to retrieve pool data as well as whitelisting
    and purchase count details for the provided address.

    @param poolIds An array of pool IDs to retrieve information about.
    @param userAddress An address which enables this function to support additional relevant data lookups.
  */
  function getPoolsWithAddress(uint256[] calldata poolIds, address userAddress) external view returns (PoolAddressOutput[] memory) {
    PoolAddressOutput[] memory poolOutputs = new PoolAddressOutput[](poolIds.length);
    for (uint256 i = 0; i < poolIds.length; i++) {
      uint256 poolId = poolIds[i];

      // Process output for each pool.
      PoolItem[] memory poolItems = new PoolItem[](pools[poolId].itemGroups.length);
      for (uint256 j = 0; j < pools[poolId].itemGroups.length; j++) {
        uint256 itemGroupId = pools[poolId].itemGroups[j];
        bytes32 itemKey = keccak256(abi.encodePacked(pools[poolId].currentPoolVersion, itemGroupId));

        // Parse each price the item is sold at.
        PricePair[] memory itemPrices = new PricePair[](pools[poolId].itemPricesLength[itemKey]);
        for (uint256 k = 0; k < pools[poolId].itemPricesLength[itemKey]; k++) {
          itemPrices[k] = pools[poolId].itemPrices[itemKey][k];
        }

        // Track the item.
        poolItems[j] = PoolItem({
          groupId: itemGroupId,
          cap: pools[poolId].itemCaps[itemKey],
          minted: pools[poolId].itemMinted[itemKey],
          prices: itemPrices
        });
      }

      // Track the pool.
      uint256 whitelistId = pools[poolId].requirement.whitelistId;
      bytes32 addressKey = keccak256(abi.encode(whitelists[whitelistId].currentWhitelistVersion, userAddress));
      poolOutputs[i] = PoolAddressOutput({
        name: pools[poolId].name,
        startBlock: pools[poolId].startBlock,
        endBlock: pools[poolId].endBlock,
        purchaseLimit: pools[poolId].purchaseLimit,
        requirement: pools[poolId].requirement,
        itemMetadataUri: item.metadataUri(),
        items: poolItems,
        purchaseCount: pools[poolId].purchaseCounts[userAddress],
        whitelistStatus: whitelists[whitelistId].addresses[addressKey]
      });
    }

    // Return the pools.
    return poolOutputs;
  }

  /**
    A function which allows the original owner of the item contract to revoke
    ownership from the launchpad.
  */
  function ownershipClawback() external onlyOriginalOwner {
    require(!ownershipLocked,
      "Ownership transfers have been locked.");
    item.transferOwnership(originalOwner);

    // Emit an event that the original owner of the item contract has clawed the contract back.
    emit OwnershipClawback();
  }

  /**
    A function which allows the original owner of this contract to lock all
    future ownership clawbacks.
  */
  function lockOwnership() external onlyOriginalOwner {
    ownershipLocked = true;

    // Emit an event that the contract's ownership transferrance is locked.
    emit OwnershipLocked();
  }

  /**
    Allow the owner of the Shop to add a new pool of items to purchase.

    @param pool The PoolInput full of data defining the pool's operation.
    @param _groupIds The specific Fee1155 item group IDs to sell in this pool, keyed to `_amounts`.
    @param _amounts The maximum amount of each particular groupId that can be sold by this pool.
    @param _pricePairs The asset address to price pairings to use for selling
                       each item.
  */
  function addPool(PoolInput calldata pool, uint256[] calldata _groupIds, uint256[] calldata _amounts, PricePair[][] memory _pricePairs) external onlyOwner {
    updatePool(nextPoolId, pool, _groupIds, _amounts, _pricePairs);

    // Increment the ID which will be used by the next pool added.
    nextPoolId = nextPoolId.add(1);
  }

  /**
    Allow the owner of the Shop to update an existing pool of items.

    @param poolId The ID of the pool to update.
    @param pool The PoolInput full of data defining the pool's operation.
    @param _groupIds The specific Fee1155 item group IDs to sell in this pool, keyed to `_amounts`.
    @param _amounts The maximum amount of each particular groupId that can be sold by this pool.
    @param _pricePairs The asset address to price pairings to use for selling
                       each item.
  */
  function updatePool(uint256 poolId, PoolInput calldata pool, uint256[] calldata _groupIds, uint256[] calldata _amounts, PricePair[][] memory _pricePairs) public onlyOwner {
    require(poolId <= nextPoolId,
      "You cannot update a non-existent pool.");
    require(pool.endBlock >= pool.startBlock,
      "You cannot create a pool which ends before it starts.");
    require(_groupIds.length > 0,
      "You must list at least one item group.");
    require(_groupIds.length == _amounts.length,
      "Item groups length cannot be mismatched with mintable amounts length.");
    require(_groupIds.length == _pricePairs.length,
      "Item groups length cannot be mismatched with price pair inputlength.");

    // Immediately store some given information about this pool.
    uint256 newPoolVersion = pools[poolId].currentPoolVersion.add(1);
    pools[poolId] = Pool({
      name: pool.name,
      startBlock: pool.startBlock,
      endBlock: pool.endBlock,
      purchaseLimit: pool.purchaseLimit,
      itemGroups: _groupIds,
      currentPoolVersion: newPoolVersion,
      requirement: pool.requirement
    });

    // Store the amount of each item group that this pool may mint.
    for (uint256 i = 0; i < _groupIds.length; i++) {
      require(_amounts[i] > 0,
        "You cannot add an item with no mintable amount.");
      bytes32 itemKey = keccak256(abi.encode(newPoolVersion, _groupIds[i]));
      pools[poolId].itemCaps[itemKey] = _amounts[i];

      // Store future purchase information for the item group.
      for (uint256 j = 0; j < _pricePairs[i].length; j++) {
        pools[poolId].itemPrices[itemKey][j] = _pricePairs[i][j];
      }
      pools[poolId].itemPricesLength[itemKey] = _pricePairs[i].length;
    }

    // Emit an event indicating that a pool has been updated.
    emit PoolUpdated(poolId, pool, _groupIds, _amounts, _pricePairs);
  }

  /**
    Allow the owner to add a new whitelist.

    @param whitelist The WhitelistInput full of data defining the new whitelist.
  */
  function addWhitelist(WhitelistInput memory whitelist) external onlyOwner {
    updateWhitelist(nextWhitelistId, whitelist);

    // Increment the ID which will be used by the next whitelist added.
    nextWhitelistId = nextWhitelistId.add(1);
  }

  /**
    Allow the owner to update a whitelist.

    @param whitelistId The whitelist ID to replace with the new whitelist.
    @param whitelist The WhitelistInput full of data defining the new whitelist.
  */
  function updateWhitelist(uint256 whitelistId, WhitelistInput memory whitelist) public onlyOwner {
    uint256 newWhitelistVersion = whitelists[whitelistId].currentWhitelistVersion.add(1);

    // Immediately store some given information about this whitelist.
    whitelists[whitelistId] = Whitelist({
      expiryBlock: whitelist.expiryBlock,
      isActive: whitelist.isActive,
      currentWhitelistVersion: newWhitelistVersion
    });

    // Invalidate the old mapping and store the new participation flags.
    for (uint256 i = 0; i < whitelist.addresses.length; i++) {
      bytes32 addressKey = keccak256(abi.encode(newWhitelistVersion, whitelist.addresses[i]));
      whitelists[whitelistId].addresses[addressKey] = true;
    }

    // Emit an event to track the new, replaced state of the whitelist.
    emit WhitelistUpdated(whitelistId, whitelist.addresses);
  }

  /**
    Allow the owner to add specified addresses to a whitelist.

    @param whitelistId The ID of the whitelist to add users to.
    @param addresses The array of addresses to add.
  */
  function addToWhitelist(uint256 whitelistId, address[] calldata addresses) public onlyOwner {
    uint256 whitelistVersion = whitelists[whitelistId].currentWhitelistVersion;
    for (uint256 i = 0; i < addresses.length; i++) {
      bytes32 addressKey = keccak256(abi.encode(whitelistVersion, addresses[i]));
      whitelists[whitelistId].addresses[addressKey] = true;
    }

    // Emit an event to track the addition of new addresses to the whitelist.
    emit WhitelistAddition(whitelistId, addresses);
  }

  /**
    Allow the owner to remove specified addresses from a whitelist.

    @param whitelistId The ID of the whitelist to remove users from.
    @param addresses The array of addresses to remove.
  */
  function removeFromWhitelist(uint256 whitelistId, address[] calldata addresses) public onlyOwner {
    uint256 whitelistVersion = whitelists[whitelistId].currentWhitelistVersion;
    for (uint256 i = 0; i < addresses.length; i++) {
      bytes32 addressKey = keccak256(abi.encode(whitelistVersion, addresses[i]));
      whitelists[whitelistId].addresses[addressKey] = false;
    }

    // Emit an event to track the removal of addresses from the whitelist.
    emit WhitelistRemoval(whitelistId, addresses);
  }

  /**
    Allow the owner to manually set the active status of a specific whitelist.

    @param whitelistId The ID of the whitelist to update the active flag for.
    @param isActive The boolean flag to enable or disable the whitelist.
  */
  function setWhitelistActive(uint256 whitelistId, bool isActive) public onlyOwner {
    whitelists[whitelistId].isActive = isActive;

    // Emit an event to track whitelist activation status changes.
    emit WhitelistActiveUpdate(whitelistId, isActive);
  }

  /**
    A function which allows the caller to retrieve whether or not addresses can
    participate in some given whitelists.

    @param whitelistIds The IDs of the whitelists to check for addresses.
    @param addresses The addresses to check whitelist eligibility for.
  */
  function getWhitelistStatus(uint256[] calldata whitelistIds, address[] calldata addresses) external view returns (bool[][] memory) {
    bool[][] memory whitelistStatus;
    for (uint256 i = 0; i < whitelistIds.length; i++) {
      uint256 whitelistId = whitelistIds[i];
      uint256 whitelistVersion = whitelists[whitelistId].currentWhitelistVersion;
      for (uint256 j = 0; j < addresses.length; j++) {
        bytes32 addressKey = keccak256(abi.encode(whitelistVersion, addresses[j]));
        whitelistStatus[j][i] = whitelists[whitelistId].addresses[addressKey];
      }
    }
    return whitelistStatus;
  }

  /**
    Allow a user to purchase an item from a pool.

    @param poolId The ID of the particular pool that the user would like to purchase from.
    @param groupId The item group ID that the user would like to purchase.
    @param assetId The type of payment asset that the user would like to purchase with.
    @param amount The amount of item that the user would like to purchase.
  */
  function mintFromPool(uint256 poolId, uint256 groupId, uint256 assetId, uint256 amount) external nonReentrant payable {
    require(amount > 0,
      "You must purchase at least one item.");
    require(poolId < nextPoolId,
      "You can only purchase items from an active pool.");

    // Verify that the asset being used in the purchase is valid.
    bytes32 itemKey = keccak256(abi.encode(pools[poolId].currentPoolVersion, groupId));
    require(assetId < pools[poolId].itemPricesLength[itemKey],
      "Your specified asset ID is not valid.");

    // Verify that the pool is still running its sale.
    require(block.number >= pools[poolId].startBlock && block.number <= pools[poolId].endBlock,
      "This pool is not currently running its sale.");

    // Verify that the pool is respecting per-address global purchase limits.
    uint256 userGlobalPurchaseAmount = amount.add(globalPurchaseCounts[msg.sender]);
    require(userGlobalPurchaseAmount <= globalPurchaseLimit,
      "You may not purchase any more items from this sale.");

    // Verify that the pool is respecting per-address pool purchase limits.
    uint256 userPoolPurchaseAmount = amount.add(pools[poolId].purchaseCounts[msg.sender]);
    require(userPoolPurchaseAmount <= pools[poolId].purchaseLimit,
      "You may not purchase any more items from this pool.");

    // Verify that the pool is either public, whitelist-expired, or an address is whitelisted.
    {
      uint256 whitelistId = pools[poolId].requirement.whitelistId;
      uint256 whitelistVersion = whitelists[whitelistId].currentWhitelistVersion;
      bytes32 addressKey = keccak256(abi.encode(whitelistVersion, msg.sender));
      bool addressWhitelisted = whitelists[whitelistId].addresses[addressKey];
      require(whitelistId == 0 || block.number > whitelists[whitelistId].expiryBlock || addressWhitelisted || !whitelists[whitelistId].isActive,
        "You are not whitelisted on this pool.");
    }

    // Verify that the pool is not depleted by the user's purchase.
    uint256 newCirculatingTotal = pools[poolId].itemMinted[itemKey].add(amount);
    require(newCirculatingTotal <= pools[poolId].itemCaps[itemKey],
      "There are not enough items available for you to purchase.");

    // Verify that the user meets any requirements gating participation in this pool.
    PoolRequirement memory poolRequirement = pools[poolId].requirement;
    if (poolRequirement.requiredType == 1) {
      IERC20 requiredToken = IERC20(poolRequirement.requiredAsset);
      require(requiredToken.balanceOf(msg.sender) >= poolRequirement.requiredAmount,
        "You do not have enough required token to participate in this pool.");
    }

    // TODO: supporting item gate requirement requires upgrading the Fee1155 contract.
    // else if (poolRequirement.requiredType == 2) {
    //   Fee1155 requiredItem = Fee1155(poolRequirement.requiredAsset);
    //   require(requiredItem.balanceOf(msg.sender) >= poolRequirement.requiredAmount,
    //     "You do not have enough required item to participate in this pool.");
    // }

    // Process payment for the user.
    // If the sentinel value for the point asset type is found, sell for points.
    // This involves converting the asset from an address to a Staker index.
    PricePair memory sellingPair = pools[poolId].itemPrices[itemKey][assetId];
    if (sellingPair.assetType == 0) {
      uint256 stakerIndex = uint256(sellingPair.asset);
      stakers[stakerIndex].spendPoints(msg.sender, sellingPair.price.mul(amount));

    // If the sentinel value for the Ether asset type is found, sell for Ether.
    } else if (sellingPair.assetType == 1) {
      uint256 etherPrice = sellingPair.price.mul(amount);
      require(msg.value >= etherPrice,
        "You did not send enough Ether to complete this purchase.");
      (bool success, ) = payable(owner()).call{ value: msg.value }("");
      require(success, "Shop owner transfer failed.");

    // Otherwise, attempt to sell for an ERC20 token.
    } else {
      IERC20 sellingAsset = IERC20(sellingPair.asset);
      uint256 tokenPrice = sellingPair.price.mul(amount);
      require(sellingAsset.balanceOf(msg.sender) >= tokenPrice,
        "You do not have enough token to complete this purchase.");
      sellingAsset.safeTransferFrom(msg.sender, owner(), tokenPrice);
    }

    // If payment is successful, mint each of the user's purchased items.
    uint256[] memory itemIds = new uint256[](amount);
    uint256[] memory amounts = new uint256[](amount);
    uint256 nextIssueNumber = nextItemIssues[groupId];
    {
      uint256 shiftedGroupId = groupId << 128;
      for (uint256 i = 1; i <= amount; i++) {
        uint256 itemId = shiftedGroupId.add(nextIssueNumber).add(i);
        itemIds[i - 1] = itemId;
        amounts[i - 1] = 1;
      }
    }

    // Mint the items.
    item.createNFT(msg.sender, itemIds, amounts, "");

    // Update the tracker for available item issue numbers.
    nextItemIssues[groupId] = nextIssueNumber.add(amount);

    // Update the count of circulating items from this pool.
    pools[poolId].itemMinted[itemKey] = newCirculatingTotal;

    // Update the pool's count of items that a user has purchased.
    pools[poolId].purchaseCounts[msg.sender] = userPoolPurchaseAmount;

    // Update the global count of items that a user has purchased.
    globalPurchaseCounts[msg.sender] = userGlobalPurchaseAmount;

    // Emit an event indicating a successful purchase.
    emit ItemPurchased(poolId, itemIds, assetId, amounts, msg.sender);
  }

  /**
    Sweep all of a particular ERC-20 token from the contract.

    @param _token The token to sweep the balance from.
  */
  function sweep(IERC20 _token) external onlyOwner {
    uint256 balance = _token.balanceOf(address(this));
    _token.safeTransferFrom(address(this), msg.sender, balance);
  }
}