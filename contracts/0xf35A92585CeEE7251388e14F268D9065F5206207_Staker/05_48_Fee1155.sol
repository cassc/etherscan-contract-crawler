// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./FeeOwner.sol";

/**
  @title An OpenSea delegate proxy contract which we include for whitelisting.
  @author OpenSea
*/
contract OwnableDelegateProxy { }

/**
  @title An OpenSea proxy registry contract which we include for whitelisting.
  @author OpenSea
*/
contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

/**
  @title An ERC-1155 item creation contract which specifies an associated
         FeeOwner who receives royalties from sales of created items.
  @author Tim Clancy

  The fee set by the FeeOwner on this Item is honored by Shop contracts.
  In addition to the inherited OpenZeppelin dependency, this uses ideas from
  the original ERC-1155 reference implementation.
*/
contract Fee1155 is ERC1155, Ownable {
  using SafeMath for uint256;

  /// A version number for this fee-bearing 1155 item contract's interface.
  uint256 public version = 1;

  /// The ERC-1155 URI for looking up item metadata using {id} substitution.
  string public metadataUri;

  /// A user-specified FeeOwner to receive a portion of item sale earnings.
  FeeOwner public feeOwner;

  /// Specifically whitelist an OpenSea proxy registry address.
  address public proxyRegistryAddress;

  /// @dev A mask for isolating an item's group ID.
  uint256 constant GROUP_MASK = uint256(uint128(~0)) << 128;

  /// A counter to enforce unique IDs for each item group minted.
  uint256 public nextItemGroupId;

  /// This mapping tracks the number of unique items within each item group.
  mapping (uint256 => uint256) public itemGroupSizes;

  /// A mapping of item IDs to their circulating supplies.
  mapping (uint256 => uint256) public currentSupply;

  /// A mapping of item IDs to their maximum supplies; true NFTs are unique.
  mapping (uint256 => uint256) public maximumSupply;

  /// A mapping of all addresses approved to mint items on behalf of the owner.
  mapping (address => bool) public approvedMinters;

  /// An event for tracking the creation of an item group.
  event ItemGroupCreated(uint256 itemGroupId, uint256 itemGroupSize,
    address indexed creator);

  /// A custom modifier which permits only approved minters to mint items.
  modifier onlyMinters {
    require(msg.sender == owner() || approvedMinters[msg.sender],
      "You are not an approved minter for this item.");
    _;
  }

  /**
    Construct a new ERC-1155 item with an associated FeeOwner fee.

    @param _uri The metadata URI to perform token ID substitution in.
    @param _feeOwner The address of a FeeOwner who receives earnings from this
                     item.
    @param _proxyRegistryAddress An OpenSea proxy registry address.
  */
  constructor(string memory _uri, FeeOwner _feeOwner, address _proxyRegistryAddress) public ERC1155(_uri) {
    metadataUri = _uri;
    feeOwner = _feeOwner;
    proxyRegistryAddress = _proxyRegistryAddress;
    nextItemGroupId = 0;
  }

  /**
    An override to whitelist the OpenSea proxy contract to enable gas-free
    listings. This function returns true if `_operator` is approved to transfer
    items owned by `_owner`.

    @param _owner The owner of items to check for transfer ability.
    @param _operator The potential transferrer of `_owner`'s items.
  */
  function isApprovedForAll(address _owner, address _operator) public view override returns (bool isOperator) {
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(_owner)) == _operator) {
      return true;
    }
    return ERC1155.isApprovedForAll(_owner, _operator);
  }

  /**
    Allow the item owner to update the metadata URI of this collection.

    @param _uri The new URI to update to.
  */
  function setURI(string calldata _uri) external onlyOwner {
    metadataUri = _uri;
  }

  /**
    Allows the owner of this contract to grant or remove approval to an external
    minter of items.

    @param _minter The external address allowed to mint items.
    @param _approval The updated `_minter` approval status.
  */
  function approveMinter(address _minter, bool _approval) external onlyOwner {
    approvedMinters[_minter] = _approval;
  }

  /**
    This function creates an "item group" which may contain one or more
    individual items. The items within a group may be any combination of
    fungible or nonfungible. The distinction between a fungible and a
    nonfungible item is made by checking the item's possible `_maximumSupply`;
    nonfungible items will naturally have a maximum supply of one because they
    are unqiue. Creating an item through this function defines its maximum
    supply. The size of the item group is inferred from the size of the input
    arrays.

    The primary purpose of an item group is to create a collection of
    nonfungible items where each item within the collection is unique but they
    all share some data as a group. The primary example of this is something
    like a series of 100 trading cards where each card is unique with its issue
    number from 1 to 100 but all otherwise reflect the same metadata. In such an
    example, the `_maximumSupply` of each item is one and the size of the group
    would be specified by passing an array with 100 elements in it to this
    function: [ 1, 1, 1, ... 1 ].

    Within an item group, items are 1-indexed with the 0-index of the item group
    supporting lookup of item group metadata. This 0-index metadata includes
    lookup via `maximumSupply` of the full count of items in the group should
    all of the items be minted, lookup via `currentSupply` of the number of
    items circulating from the group as a whole, and lookup via `groupSizes` of
    the number of unique items within the group.

    @param initialSupply An array of per-item initial supplies which should be
                         minted immediately.
    @param _maximumSupply An array of per-item maximum supplies.
    @param recipients An array of addresses which will receive the initial
                      supply minted for each corresponding item.
    @param data Any associated data to use if items are minted this transaction.
  */
  function create(uint256[] calldata initialSupply, uint256[] calldata _maximumSupply, address[] calldata recipients, bytes calldata data) external onlyOwner returns (uint256) {
    uint256 groupSize = initialSupply.length;
    require(groupSize > 0,
      "You cannot create an empty item group.");
    require(initialSupply.length == _maximumSupply.length,
      "Initial supply length cannot be mismatched with maximum supply length.");
    require(initialSupply.length == recipients.length,
      "Initial supply length cannot be mismatched with recipients length.");

    // Create an item group of requested size using the next available ID.
    uint256 shiftedGroupId = nextItemGroupId << 128;
    itemGroupSizes[shiftedGroupId] = groupSize;
    emit ItemGroupCreated(shiftedGroupId, groupSize, msg.sender);

    // Record the supply cap of each item being created in the group.
    uint256 fullCollectionSize = 0;
    for (uint256 i = 0; i < groupSize; i++) {
      uint256 itemInitialSupply = initialSupply[i];
      uint256 itemMaximumSupply = _maximumSupply[i];
      fullCollectionSize = fullCollectionSize.add(itemMaximumSupply);
      require(itemMaximumSupply > 0,
        "You cannot create an item which is never mintable.");
      require(itemInitialSupply <= itemMaximumSupply,
        "You cannot create an item which exceeds its own supply cap.");

      // The item ID is offset by one because the zero index of the group is used to store the group size.
      uint256 itemId = shiftedGroupId.add(i + 1);
      maximumSupply[itemId] = itemMaximumSupply;

      // If this item is being initialized with a supply, mint to the recipient.
      if (itemInitialSupply > 0) {
        address itemRecipient = recipients[i];
        _mint(itemRecipient, itemId, itemInitialSupply, data);
        currentSupply[itemId] = itemInitialSupply;
      }
    }

    // Also record the full size of the entire item group.
    maximumSupply[shiftedGroupId] = fullCollectionSize;

    // Increment our next item group ID and return our created item group ID.
    nextItemGroupId = nextItemGroupId.add(1);
    return shiftedGroupId;
  }

  /**
    Allow the item owner to mint a new item, so long as there is supply left to
    do so.

    @param to The address to send the newly-minted items to.
    @param id The ERC-1155 ID of the item being minted.
    @param amount The amount of the new item to mint.
    @param data Any associated data for this minting event that should be passed.
  */
  function mint(address to, uint256 id, uint256 amount, bytes calldata data) external onlyMinters {
    uint256 groupId = id & GROUP_MASK;
    require(groupId != id,
      "You cannot mint an item with an issuance index of 0.");
    currentSupply[groupId] = currentSupply[groupId].add(amount);
    uint256 newSupply = currentSupply[id].add(amount);
    currentSupply[id] = newSupply;
    require(newSupply <= maximumSupply[id],
      "You cannot mint an item beyond its permitted maximum supply.");
    _mint(to, id, amount, data);
  }

  /**
    Allow the item owner to mint a new batch of items, so long as there is
    supply left to do so for each item.

    @param to The address to send the newly-minted items to.
    @param ids The ERC-1155 IDs of the items being minted.
    @param amounts The amounts of the new items to mint.
    @param data Any associated data for this minting event that should be passed.
  */
  function mintBatch(address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external onlyMinters {
    require(ids.length > 0,
      "You cannot perform an empty mint.");
    require(ids.length == amounts.length,
      "Supplied IDs length cannot be mismatched with amounts length.");
    for (uint256 i = 0; i < ids.length; i++) {
      uint256 id = ids[i];
      uint256 amount = amounts[i];
      uint256 groupId = id & GROUP_MASK;
      require(groupId != id,
        "You cannot mint an item with an issuance index of 0.");
      currentSupply[groupId] = currentSupply[groupId].add(amount);
      uint256 newSupply = currentSupply[id].add(amount);
      currentSupply[id] = newSupply;
      require(newSupply <= maximumSupply[id],
        "You cannot mint an item beyond its permitted maximum supply.");
    }
    _mintBatch(to, ids, amounts, data);
  }
}