// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../../access/PermitControl.sol";
import "../../proxy/StubProxyRegistry.sol";
import "../../libraries/DFStorage.sol";
import "./interfaces/ISuper1155.sol";

/**
  @title An ERC-1155 item creation contract.
  @author Tim Clancy
  @author Qazawat Zirak
  @author Rostislav Khlebnikov
  @author Nikita Elunin

  This contract represents the NFTs within a single collection. It allows for a
  designated collection owner address to manage the creation of NFTs within this
  collection. The collection owner grants approval to or removes approval from
  other addresses governing their ability to mint NFTs from this collection.

  This contract is forked from the inherited OpenZeppelin dependency, and uses
  ideas from the original ERC-1155 reference implementation.

  July 19th, 2021.
*/
contract Super1155 is PermitControl, ERC165Storage, IERC1155, IERC1155MetadataURI {
  using Address for address;

  uint256 MAX_INT = type(uint256).max;

  /// The public identifier for the right to set this contract's metadata URI.
  bytes32 public constant SET_URI = keccak256("SET_URI");

  /// The public identifier for the right to set this contract's proxy registry.
  bytes32 public constant SET_PROXY_REGISTRY = keccak256("SET_PROXY_REGISTRY");

  /// The public identifier for the right to configure item groups.
  bytes32 public constant CONFIGURE_GROUP = keccak256("CONFIGURE_GROUP");

  /// The public identifier for the right to mint items.
  bytes32 public constant MINT  = keccak256("MINT");

  /// The public identifier for the right to burn items.
  bytes32 public constant BURN = keccak256("BURN");

  /// The public identifier for the right to set item metadata.
  bytes32 public constant SET_METADATA = keccak256("SET_METADATA");

  /// The public identifier for the right to lock the metadata URI.
  bytes32 public constant LOCK_URI = keccak256("LOCK_URI");

  /// The public identifier for the right to lock an item's metadata.
  bytes32 public constant LOCK_ITEM_URI = keccak256("LOCK_ITEM_URI");

  /// The public identifier for the right to disable item creation.
  bytes32 public constant LOCK_CREATION = keccak256("LOCK_CREATION");

  /// @dev Supply the magic number for the required ERC-1155 interface.
  bytes4 private constant INTERFACE_ERC1155 = 0xd9b67a26;

  /// @dev Supply the magic number for the required ERC-1155 metadata extension.
  bytes4 private constant INTERFACE_ERC1155_METADATA_URI = 0x0e89341c;

  /// @dev A mask for isolating an item's group ID.
  uint256 private constant GROUP_MASK = uint256(type(uint128).max) << 128;

  /// The public name of this contract.
  string public name;

  /**
    The ERC-1155 URI for tracking item metadata, supporting {id} substitution.
    For example: https://token-cdn-domain/{id}.json. See the ERC-1155 spec for
    more details: https://eips.ethereum.org/EIPS/eip-1155#metadata.
  */
  string public metadataUri;

  /// The URI for the storefront-level metadata of contract
  string public contractURI;

  /// A proxy registry address for supporting automatic delegated approval.
  address public proxyRegistryAddress;

  /// @dev A mapping from each token ID to per-address balances.
  mapping (uint256 => mapping(address => uint256)) private balances;

  /// A mapping from each group ID to per-address balances.
  mapping (uint256 => mapping(address => uint256)) public groupBalances;

  /// A mapping from each address to a collection-wide balance.
  mapping(address => uint256) public totalBalances;

  /**
    @dev This is a mapping from each address to per-address operator approvals.
    Operators are those addresses that have been approved to transfer tokens on
    behalf of the approver. Transferring tokens includes the right to burn
    tokens.
  */
  mapping (address => mapping(address => bool)) private operatorApprovals;

  /**
    This struct defines the settings for a particular item group and is tracked
    in storage.

    @param initialized Whether or not this `ItemGroup` has been initialized.
    @param name A name for the item group.
    @param supplyType The supply type for this group of items.
    @param supplyData An optional integer used by some `supplyType` values.
    @param itemType The type of item represented by this item group.
    @param itemData An optional integer used by some `itemType` values.
    @param burnType The type of burning permitted by this item group.
    @param burnData An optional integer used by some `burnType` values.
    @param circulatingSupply The number of individual items within this group in
      circulation.
    @param mintCount The number of times items in this group have been minted.
    @param burnCount The number of times items in this group have been burnt.
  */
  struct ItemGroup {
    uint256 burnData;
    uint256 circulatingSupply;
    uint256 mintCount;
    uint256 burnCount;
    uint256 supplyData;
    uint256 itemData;
    bool initialized;
    DFStorage.SupplyType supplyType;
    DFStorage.ItemType itemType;
    DFStorage.BurnType burnType;
    string name;
  }

  /// A mapping of data for each item group.
  mapping (uint256 => ItemGroup) public itemGroups;

  /// A mapping of circulating supplies for each individual token.
  mapping (uint256 => uint256) public circulatingSupply;

  /// A mapping of the number of times each individual token has been minted.
  mapping (uint256 => uint256) public mintCount;

  /// A mapping of the number of times each individual token has been burnt.
  mapping (uint256 => uint256) public burnCount;

  /**
    A mapping of token ID to a boolean representing whether the item's metadata
    has been explicitly frozen via a call to `lockURI(string calldata _uri,
    uint256 _id)`. Do note that it is possible for an item's mapping here to be
    false while still having frozen metadata if the item collection as a whole
    has had its `uriLocked` value set to true.
  */
  mapping (uint256 => bool) public metadataFrozen;

  /**
    A public mapping of optional on-chain metadata for each token ID. A token's
    on-chain metadata is unable to be changed if the item's metadata URI has
    been permanently fixed or if the collection's metadata URI as a whole has
    been frozen.
  */
  mapping (uint256 => string) public metadata;

  /// Whether or not the metadata URI has been locked to future changes.
  bool public uriLocked;

  /// Whether or not the contract URI has been locked to future changes.
  bool public contractUriLocked;

  /// Whether or not the item collection has been locked to all further minting.
  bool public locked;

  /**
    An event that gets emitted when the metadata collection URI is changed.

    @param oldURI The old metadata URI.
    @param newURI The new metadata URI.
  */
  event ChangeURI(string indexed oldURI, string indexed newURI);

  /**
    An event that gets emitted when the proxy registry address is changed.

    @param oldRegistry The old proxy registry address.
    @param newRegistry The new proxy registry address.
  */
  event ChangeProxyRegistry(address indexed oldRegistry,
    address indexed newRegistry);

  /**
    An event that gets emitted when an item group is configured.

    @param manager The caller who configured the item group `_groupId`.
    @param groupId The groupId being configured.
    @param newGroup The new group configuration.
  */
  event ItemGroupConfigured(address indexed manager, uint256 groupId,
    DFStorage.ItemGroupInput indexed newGroup);

  /**
    An event that gets emitted when the item collection is locked to further
    creation.

    @param locker The caller who locked the collection.
  */
  event CollectionLocked(address indexed locker);

  /**
    An event that gets emitted when a token ID has its on-chain metadata
    changed.

    @param changer The caller who triggered the metadata change.
    @param id The ID of the token which had its metadata changed.
    @param oldMetadata The old metadata of the token.
    @param newMetadata The new metadata of the token.
  */
  event MetadataChanged(address indexed changer, uint256 indexed id,
    string oldMetadata, string indexed newMetadata);

  /**
    An event that indicates we have set a permanent metadata URI for a token.

    @param _value The value of the permanent metadata URI.
    @param _id The token ID associated with the permanent metadata value.
  */
  event PermanentURI(string _value, uint256 indexed _id);

  /**
    An event that emmited when the contract URI is changed

    @param oldURI The old contract URI
    @param newURI The new contract URI
   */
  event ChangeContractURI(string indexed oldURI, string indexed newURI);

  /**
    An event that indicates we have set a permanent contract URI.

    @param _value The value of the permanent contract URI.
    @param _id The token ID associated with the permanent metadata value.
  */
  event PermanentContractURI(string _value, uint256 indexed _id);

  /**
    Construct a new ERC-1155 item collection.

    @param _name The name to assign to this item collection contract.
    @param _metadataURI The metadata URI to perform later token ID substitution with.
    @param _contractURI The contract URI.
    @param _proxyRegistryAddress The address of a proxy registry contract.
  */
  constructor(address _owner, string memory _name, string memory _metadataURI,
    string memory _contractURI, address _proxyRegistryAddress) {

    // Register the ERC-165 interfaces.
    _registerInterface(INTERFACE_ERC1155);
    _registerInterface(INTERFACE_ERC1155_METADATA_URI);

    setPermit(_msgSender(), UNIVERSAL, CONFIGURE_GROUP, MAX_INT);

     if (_owner != owner()) {
      transferOwnership(_owner);
    }
    // Continue initialization.
    name = _name;
    metadataUri = _metadataURI;
    contractURI = _contractURI;
    proxyRegistryAddress = _proxyRegistryAddress;
  }

  /**
    Return a version number for this contract's interface.
  */
  function version() external virtual override pure returns (uint256) {
    return 1;
  }

  /**
    Return the item collection's metadata URI. This implementation returns the
    same URI for all tokens within the collection and relies on client-side
    ID substitution per https://eips.ethereum.org/EIPS/eip-1155#metadata. Per
    said specification, clients calling this function must replace the {id}
    substring with the actual token ID in hex, not prefixed by 0x, and padded
    to 64 characters in length.

    @return The metadata URI string of the item with ID `_itemId`.
  */
  function uri(uint256) external view returns (string memory) {
    return metadataUri;
  }


  /**
    Allow the item collection owner or an approved manager to update the
    metadata URI of this collection. This implementation relies on a single URI
    for all items within the collection, and as such does not emit the standard
    URI event. Instead, we emit our own event to reflect changes in the URI.

    @param _uri The new URI to update to.
  */
  function setURI(string calldata _uri) external virtual
    hasValidPermit(UNIVERSAL, SET_URI) {
    require(!uriLocked,
      "Super1155: the collection URI has been permanently locked");
    string memory oldURI = metadataUri;
    metadataUri = _uri;
    emit ChangeURI(oldURI, _uri);
  }

  /**
    Allow approved manager to update the contract URI. At the end of update, we 
    emit our own event to reflect changes in the URI.

    @param _uri The new contract URI to update to.
  */
  function setContractUri(string calldata _uri) external virtual
    hasValidPermit(UNIVERSAL, SET_URI) {
      require(!contractUriLocked,
        "Super1155: the contract URI has been permanently locked");
      string memory oldContractUri = contractURI;
      contractURI = _uri;
      emit ChangeContractURI(oldContractUri, _uri);
  }

  /**
    Allow the item collection owner or an approved manager to update the proxy
    registry address handling delegated approval.

    @param _proxyRegistryAddress The address of the new proxy registry to
      update to.
  */
  function setProxyRegistry(address _proxyRegistryAddress) external virtual
    hasValidPermit(UNIVERSAL, SET_PROXY_REGISTRY) {
    address oldRegistry = proxyRegistryAddress;
    proxyRegistryAddress = _proxyRegistryAddress;
    emit ChangeProxyRegistry(oldRegistry, _proxyRegistryAddress);
  }

  /**
    Retrieve the balance of a particular token `_id` for a particular address
    `_owner`.

    @param _owner The owner to check for this token balance.
    @param _id The ID of the token to check for a balance.
    @return The amount of token `_id` owned by `_owner`.
  */
  function balanceOf(address _owner, uint256 _id) public view virtual
  returns (uint256) {
    require(_owner != address(0),
      "ERC1155: balance query for the zero address");
    return balances[_id][_owner];
  }

  /**
    Retrieve in a single call the balances of some mulitple particular token
    `_ids` held by corresponding `_owners`.

    @param _owners The owners to check for token balances.
    @param _ids The IDs of tokens to check for balances.
    @return the amount of each token owned by each owner.
  */
  function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
    external view virtual returns (uint256[] memory) {
    require(_owners.length == _ids.length,
      "ERC1155: accounts and ids length mismatch");

    // Populate and return an array of balances.
    uint256[] memory batchBalances = new uint256[](_owners.length);
    for (uint256 i = 0; i < _owners.length; ++i) {
      batchBalances[i] = balanceOf(_owners[i], _ids[i]);
    }
    return batchBalances;
  }

  /**
    This function returns true if `_operator` is approved to transfer items
    owned by `_owner`. This approval check features an override to explicitly
    whitelist any addresses delegated in the proxy registry.

    @param _owner The owner of items to check for transfer ability.
    @param _operator The potential transferrer of `_owner`'s items.
    @return Whether `_operator` may transfer items owned by `_owner`.
  */
  function isApprovedForAll(address _owner, address _operator) public
    view virtual returns (bool) {
    if (StubProxyRegistry(proxyRegistryAddress).proxies(_owner) == _operator) {
      return true;
    }

    // We did not find an explicit whitelist in the proxy registry.
    return operatorApprovals[_owner][_operator];
  }

  /**
    Enable or disable approval for a third party `_operator` address to manage
    (transfer or burn) all of the caller's tokens.

    @param _operator The address to grant management rights over all of the
      caller's tokens.
    @param _approved The status of the `_operator`'s approval for the caller.
  */
  function setApprovalForAll(address _operator, bool _approved) external
    virtual {
    require(_msgSender() != _operator,
      "ERC1155: setting approval status for self");
    operatorApprovals[_msgSender()][_operator] = _approved;
    emit ApprovalForAll(_msgSender(), _operator, _approved);
  }

  /**
    This private helper function converts a number into a single-element array.

    @param _element The element to convert to an array.
    @return The array containing the single `_element`.
  */
  function _asSingletonArray(uint256 _element) private pure
    returns (uint256[] memory) {
    uint256[] memory array = new uint256[](1);
    array[0] = _element;
    return array;
  }

  /**
    An inheritable and configurable pre-transfer hook that can be overridden.
    It fires before any token transfer, including mints and burns.

    @param _operator The caller who triggers the token transfer.
    @param _from The address to transfer tokens from.
    @param _to The address to transfer tokens to.
    @param _ids The specific token IDs to transfer.
    @param _amounts The amounts of the specific `_ids` to transfer.
    @param _data Additional call data to send with this transfer.
  */
  function _beforeTokenTransfer(address _operator, address _from, address _to,
    uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    internal virtual {
  }

  /**
    ERC-1155 dictates that any contract which wishes to receive ERC-1155 tokens
    must explicitly designate itself as such. This function checks for such
    designation to prevent undesirable token transfers.

    @param _operator The caller who triggers the token transfer.
    @param _from The address to transfer tokens from.
    @param _to The address to transfer tokens to.
    @param _id The specific token ID to transfer.
    @param _amount The amount of the specific `_id` to transfer.
    @param _data Additional call data to send with this transfer.
  */
  function _doSafeTransferAcceptanceCheck(address _operator, address _from,
    address _to, uint256 _id, uint256 _amount, bytes calldata _data) private {
    if (_to.isContract()) {
      try IERC1155Receiver(_to).onERC1155Received(_operator, _from, _id,
        _amount, _data) returns (bytes4 response) {
        if (response != IERC1155Receiver(_to).onERC1155Received.selector) {
          revert("ERC1155: ERC1155Receiver rejected tokens");
        }
      } catch Error(string memory reason) {
        revert(reason);
      } catch {
        revert("ERC1155: transfer to non ERC1155Receiver implementer");
      }
    }
  }

  /**
    The batch equivalent of `_doSafeTransferAcceptanceCheck()`.

    @param _operator The caller who triggers the token transfer.
    @param _from The address to transfer tokens from.
    @param _to The address to transfer tokens to.
    @param _ids The specific token IDs to transfer.
    @param _amounts The amounts of the specific `_ids` to transfer.
    @param _data Additional call data to send with this transfer.
  */
  function _doSafeBatchTransferAcceptanceCheck(address _operator, address _from,
    address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory
    _data) private {
    if (_to.isContract()) {
      try IERC1155Receiver(_to).onERC1155BatchReceived(_operator, _from, _ids,
        _amounts, _data) returns (bytes4 response) {
        if (response != IERC1155Receiver(_to).onERC1155BatchReceived.selector) {
          revert("ERC1155: ERC1155Receiver rejected tokens");
        }
      } catch Error(string memory reason) {
        revert(reason);
      } catch {
        revert("ERC1155: transfer to non ERC1155Receiver implementer");
      }
    }
  }

  /**
    Transfer on behalf of a caller or one of their authorized token managers
    items from one address to another.

    @param _from The address to transfer tokens from.
    @param _to The address to transfer tokens to.
    @param _ids The specific token IDs to transfer.
    @param _amounts The amounts of the specific `_ids` to transfer.
    @param _data Additional call data to send with this transfer.
  */
  function safeBatchTransferFrom(address _from, address _to,
    uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    public virtual {
    require(_ids.length == _amounts.length,
      "ERC1155: ids and amounts length mismatch");
    require(_to != address(0),
      "ERC1155: transfer to the zero address");
    require(_from == _msgSender() || isApprovedForAll(_from, _msgSender()),
      "ERC1155: caller is not owner nor approved");

    // Validate transfer and perform all batch token sends.
    _beforeTokenTransfer(_msgSender(), _from, _to, _ids, _amounts, _data);
    for (uint256 i = 0; i < _ids.length; ++i) {

      // Retrieve the item's group ID.
      uint256 groupId = (_ids[i] & GROUP_MASK) >> 128;

      // Update all specially-tracked group-specific balances.
      require(balances[_ids[i]][_from] >= _amounts[i], "ERC1155: insufficient balance for transfer");
      balances[_ids[i]][_from] = balances[_ids[i]][_from] - _amounts[i];
      balances[_ids[i]][_to] = balances[_ids[i]][_to] + _amounts[i];
      groupBalances[groupId][_from] = groupBalances[groupId][_from] - _amounts[i];
      groupBalances[groupId][_to] = groupBalances[groupId][_to] + _amounts[i];
      totalBalances[_from] = totalBalances[_from] - _amounts[i];
      totalBalances[_to] = totalBalances[_to] + _amounts[i];
    }

    // Emit the transfer event and perform the safety check.
    emit TransferBatch(_msgSender(), _from, _to, _ids, _amounts);
    _doSafeBatchTransferAcceptanceCheck(_msgSender(), _from, _to, _ids,
      _amounts, _data);
  }


  /**
    Transfer on behalf of a caller or one of their authorized token managers
    items from one address to another.

    @param _from The address to transfer tokens from.
    @param _to The address to transfer tokens to.
    @param _id The specific token ID to transfer.
    @param _amount The amount of the specific `_id` to transfer.
    @param _data Additional call data to send with this transfer.
  */
  function safeTransferFrom(address _from, address _to, uint256 _id,
    uint256 _amount, bytes calldata _data) external  virtual {
      safeBatchTransferFrom(_from, _to, _asSingletonArray(_id), _asSingletonArray(_amount), _data);
  }

  /**
    Create a new NFT item group or configure an existing one. NFTs within a
    group share a group ID in the upper 128-bits of their full item ID.
    Within a group NFTs can be distinguished for the purposes of serializing
    issue numbers.

    @param _groupId The ID of the item group to create or configure.
    @param _data The `ItemGroup` data input.
  */
  function configureGroup(uint256 _groupId, DFStorage.ItemGroupInput calldata _data) external  {
    require(_groupId != 0,
      "Super1155: group ID 0 is invalid");
    require(_hasItemRight(_groupId, CONFIGURE_GROUP), "Super1155: you don't have rights to configure group");

    // If the collection is not locked, we may add a new item group.
    if (!itemGroups[_groupId].initialized) {
      require(!locked,
        "Super1155: the collection is locked so groups cannot be created");
      itemGroups[_groupId] = ItemGroup({
        initialized: true,
        name: _data.name,
        supplyType: _data.supplyType,
        supplyData: _data.supplyData,
        itemType: _data.itemType,
        itemData: _data.itemData,
        burnType: _data.burnType,
        burnData: _data.burnData,
        circulatingSupply: 0,
        mintCount: 0,
        burnCount: 0
      });

    // Edit an existing item group. The name may always be updated.
    } else {
      itemGroups[_groupId].name = _data.name;

      // A capped supply type may not change.
      // It may also not have its cap increased.
      if (itemGroups[_groupId].supplyType == DFStorage.SupplyType.Capped) {
        require(_data.supplyType == DFStorage.SupplyType.Capped,
          "Super1155: you may not uncap a capped supply type");
        require(_data.supplyData <= itemGroups[_groupId].supplyData,
          "Super1155: you may not increase the supply of a capped type");

      // The flexible and uncapped types may freely change.
      } else {
        itemGroups[_groupId].supplyType = _data.supplyType;
      }

      // Item supply data may not be reduced below the circulating supply.
      require(_data.supplyData >= itemGroups[_groupId].circulatingSupply,
        "Super1155: you may not decrease supply below the circulating amount");
      itemGroups[_groupId].supplyData = _data.supplyData;

      // A nonfungible item may not change type.
      if (itemGroups[_groupId].itemType == DFStorage.ItemType.Nonfungible) {
        require(_data.itemType == DFStorage.ItemType.Nonfungible,
          "Super1155: you may not alter nonfungible items");

      // A semifungible item may not change type.
      } else if (itemGroups[_groupId].itemType == DFStorage.ItemType.Semifungible) {
        require(_data.itemType == DFStorage.ItemType.Semifungible,
          "Super1155: you may not alter nonfungible items");

      // A fungible item may change type if it is unique enough.
      } else if (itemGroups[_groupId].itemType == DFStorage.ItemType.Fungible) {
        if (_data.itemType == DFStorage.ItemType.Nonfungible) {
          require(itemGroups[_groupId].circulatingSupply <= 1,
            "Super1155: the fungible item is not unique enough to change");
          itemGroups[_groupId].itemType = DFStorage.ItemType.Nonfungible;

        // We may also try for semifungible items with a high-enough cap.
        } else if (_data.itemType == DFStorage.ItemType.Semifungible) {
          require(itemGroups[_groupId].circulatingSupply <= _data.itemData,
            "Super1155: the fungible item is not unique enough to change");
          itemGroups[_groupId].itemType = DFStorage.ItemType.Semifungible;
          itemGroups[_groupId].itemData = _data.itemData;
        }
      }
    }

    // Emit the configuration event.
    emit ItemGroupConfigured(_msgSender(), _groupId, _data);
  }

  /**
    This is a private helper function to replace the `hasItemRight` modifier
    that we use on some functions in order to inline this check during batch
    minting and burning.

    @param _id The ID of the item to check for the given `_right` on.
    @param _right The right that the caller is trying to exercise on `_id`.
    @return Whether or not the caller has a valid right on this item.
  */
  function _hasItemRight(uint256 _id, bytes32 _right) private view
    returns (bool) {
    uint256 groupId = _id  >> 128;
    if (_msgSender() == owner()) {
      return true;
    }
    if (hasRight(_msgSender(), UNIVERSAL, _right)) {
      return true;
    } 
    if (hasRight(_msgSender(), bytes32(groupId), _right)) {
      return true;
    }
    if (hasRight(_msgSender(), bytes32(_id), _right)) {
      return true;
    } 
    return false;
  }

  /**
    This is a private helper function to verify, according to all of our various
    minting and burning rules, whether it would be valid to mint some `_amount`
    of a particular item `_id`.

    @param _id The ID of the item to check for minting validity.
    @param _amount The amount of the item to try checking mintability for.
    @return The ID of the item that should have `_amount` minted for it.
  */
  function _mintChecker(uint256 _id, uint256 _amount) private view
    returns (uint256) {

    // Retrieve the item's group ID.
    uint256 shiftedGroupId = (_id & GROUP_MASK);
    uint256 groupId = shiftedGroupId >> 128;
    require(itemGroups[groupId].initialized,
      "Super1155: you cannot mint a non-existent item group");

    // If we can replenish burnt items, then only our currently-circulating
    // supply matters. Otherwise, historic mints are what determine the cap.
    uint256 currentGroupSupply = itemGroups[groupId].mintCount;
    uint256 currentItemSupply = mintCount[_id];
    if (itemGroups[groupId].burnType == DFStorage.BurnType.Replenishable) {
      currentGroupSupply = itemGroups[groupId].circulatingSupply;
      currentItemSupply = circulatingSupply[_id];
    }

    // If we are subject to a cap on group size, ensure we don't exceed it.
    if (itemGroups[groupId].supplyType != DFStorage.SupplyType.Uncapped) {
      require((currentGroupSupply + _amount) <= itemGroups[groupId].supplyData,
        "Super1155: you cannot mint a group beyond its cap");
    }

    // Do not violate nonfungibility rules.
    if (itemGroups[groupId].itemType == DFStorage.ItemType.Nonfungible) {
      require((currentItemSupply + _amount) <= 1,
        "Super1155: you cannot mint more than a single nonfungible item");

    // Do not violate semifungibility rules.
    } else if (itemGroups[groupId].itemType == DFStorage.ItemType.Semifungible) {
      require((currentItemSupply + _amount) <= itemGroups[groupId].itemData,
        "Super1155: you cannot mint more than the alloted semifungible items");
    }

    // Fungible items are coerced into the single group ID + index one slot.
    uint256 mintedItemId = _id;
    if (itemGroups[groupId].itemType == DFStorage.ItemType.Fungible) {
      mintedItemId = shiftedGroupId + 1;
    }
    return mintedItemId;
  }

  /**
    Mint a batch of tokens into existence and send them to the `_recipient`
    address. In order to mint an item, its item group must first have been
    created. Minting an item must obey both the fungibility and size cap of its
    group.

    @param _recipient The address to receive all NFTs within the newly-minted
      group.
    @param _ids The item IDs for the new items to create.
    @param _amounts The amount of each corresponding item ID to create.
    @param _data Any associated data to use on items minted in this transaction.
  */
  function mintBatch(address _recipient, uint256[] calldata _ids,
    uint256[] calldata _amounts, bytes calldata _data)
    external  {
    require(_recipient != address(0),
      "ERC1155: mint to the zero address");
    require(_ids.length == _amounts.length,
      "ERC1155: ids and amounts length mismatch");

    // Validate and perform the mint.
    address operator = _msgSender();
    _beforeTokenTransfer(operator, address(0), _recipient, _ids, _amounts,
      _data);

    // Loop through each of the batched IDs to update storage of special
    // balances and circulation balances.
    for (uint256 i = 0; i < _ids.length; i++) {
      require(_hasItemRight(_ids[i], MINT),
        "Super1155: you do not have the right to mint that item");

      // Retrieve the group ID from the given item `_id` and check mint.
      uint256 groupId = _ids[i] >> 128;
      uint256 mintedItemId = _mintChecker(_ids[i], _amounts[i]);

      // Update storage of special balances and circulating values.
      balances[mintedItemId][_recipient] = balances[mintedItemId][_recipient] + _amounts[i];
      groupBalances[groupId][_recipient] = groupBalances[groupId][_recipient] + _amounts[i];
      totalBalances[_recipient] = totalBalances[_recipient] + _amounts[i];
      mintCount[mintedItemId] = mintCount[mintedItemId] + _amounts[i];
      circulatingSupply[mintedItemId] = circulatingSupply[mintedItemId] + _amounts[i];
      itemGroups[groupId].mintCount = itemGroups[groupId].mintCount + _amounts[i];
      itemGroups[groupId].circulatingSupply =
        itemGroups[groupId].circulatingSupply + _amounts[i];
    }

    // Emit event and handle the safety check.
    emit TransferBatch(operator, address(0), _recipient, _ids, _amounts);
    _doSafeBatchTransferAcceptanceCheck(operator, address(0), _recipient, _ids,
      _amounts, _data);
  }

  /**
    This is a private helper function to verify, according to all of our various
    minting and burning rules, whether it would be valid to burn some `_amount`
    of a particular item `_id`.

    @param _id The ID of the item to check for burning validity.
    @param _amount The amount of the item to try checking burning for.
    @return The ID of the item that should have `_amount` burnt for it.
  */
  function _burnChecker(uint256 _id, uint256 _amount) private view
    returns (uint256) {

    // Retrieve the item's group ID.
    uint256 shiftedGroupId = (_id & GROUP_MASK);
    uint256 groupId = shiftedGroupId >> 128;
    require(itemGroups[groupId].initialized,
      "Super1155: you cannot burn a non-existent item group");

    // If the item group is non-burnable, then revert.
    if (itemGroups[groupId].burnType == DFStorage.BurnType.None) {
      revert("Super1155: you cannot burn a non-burnable item group");
    }

    // If we can burn items, then we must verify that we do not exceed the cap.
    if (itemGroups[groupId].burnType == DFStorage.BurnType.Burnable) {
      require((itemGroups[groupId].burnCount + _amount)
        <= itemGroups[groupId].burnData,
        "Super1155: you may not exceed the burn limit on this item group");
    }

    // Fungible items are coerced into the single group ID + index one slot.
    uint256 burntItemId = _id;
    if (itemGroups[groupId].itemType == DFStorage.ItemType.Fungible) {
      burntItemId = shiftedGroupId + 1;
    }
    return burntItemId;
  }

  /**
    This function allows an address to destroy multiple different items in a
    single call.

    @param _burner The address whose items are burning.
    @param _ids The item IDs to burn.
    @param _amounts The amounts of the corresponding item IDs to burn.
  */
  function burnBatch(address _burner, uint256[] memory _ids,
    uint256[] memory _amounts) public virtual {
    require(_burner != address(0),
      "ERC1155: burn from the zero address");
    require(_ids.length == _amounts.length,
      "ERC1155: ids and amounts length mismatch");

    // Validate and perform the burn.
    address operator = _msgSender();
    _beforeTokenTransfer(operator, _burner, address(0), _ids, _amounts, "");

    // Loop through each of the batched IDs to update storage of special
    // balances and circulation balances.
    for (uint i = 0; i < _ids.length; i++) {
      require(_hasItemRight(_ids[i], BURN),
        "Super1155: you do not have the right to burn that item");

      // Retrieve the group ID from the given item `_id` and check burn.
      uint256 groupId = _ids[i] >> 128;
      uint256 burntItemId = _burnChecker(_ids[i], _amounts[i]);

      // Update storage of special balances and circulating values.
      require(balances[burntItemId][_burner] >= _amounts[i], "ERC1155: burn amount exceeds balance");
      balances[burntItemId][_burner] = balances[burntItemId][_burner] - _amounts[i];
      groupBalances[groupId][_burner] = groupBalances[groupId][_burner] - _amounts[i];
      totalBalances[_burner] = totalBalances[_burner] - _amounts[i];
      burnCount[burntItemId] = burnCount[burntItemId] + _amounts[i];
      circulatingSupply[burntItemId] = circulatingSupply[burntItemId] - _amounts[i];
      itemGroups[groupId].burnCount = itemGroups[groupId].burnCount + _amounts[i];
      itemGroups[groupId].circulatingSupply =
        itemGroups[groupId].circulatingSupply - _amounts[i];
    }

    // Emit the burn event.
    emit TransferBatch(operator, _burner, address(0), _ids, _amounts);
  }

  /**
    This function allows an address to destroy some of its items.

    @param _burner The address whose item is burning.
    @param _id The item ID to burn.
    @param _amount The amount of the corresponding item ID to burn.
  */
  function burn(address _burner, uint256 _id, uint256 _amount) external virtual{
      require(_hasItemRight(_id, BURN), "Super1155: you don't have rights to burn");
      burnBatch(_burner, _asSingletonArray(_id), _asSingletonArray(_amount));
  }

  /**
    Set the on-chain metadata attached to a specific token ID so long as the
    collection as a whole or the token specifically has not had metadata
    editing frozen.

    @param _id The ID of the token to set the `_metadata` for.
    @param _metadata The metadata string to store on-chain.
  */
  function setMetadata(uint256 _id, string memory _metadata) external {
    require(_hasItemRight(_id, SET_METADATA), "Super1155: you don't have rights to setMetadata");
    uint groupId = _id >> 128;
    require(!uriLocked && !metadataFrozen[_id] &&  !metadataFrozen[groupId],
      "Super1155: you cannot edit this metadata because it is frozen");
    string memory oldMetadata = metadata[_id];
    metadata[_id] = _metadata;
    emit MetadataChanged(_msgSender(), _id, oldMetadata, _metadata);
  }

  /**
    Allow the item collection owner or an associated manager to forever lock the
    metadata URI on the entire collection to future changes.
  */
  function lockURI() external
    hasValidPermit(UNIVERSAL, LOCK_URI) {
    uriLocked = true;
    emit PermanentURI(metadataUri, 2 ** 256 - 1);
  }

  
  /** 
    Allow the associated manager to forever lock the contract URI to future 
    changes
  */
  function lockContractUri() external
    hasValidPermit(UNIVERSAL, LOCK_URI) {
    contractUriLocked = true;
    emit PermanentContractURI(contractURI, 2 ** 256 - 1);   
  }

  /**
    Allow the item collection owner or an associated manager to forever lock the
    metadata URI on an item to future changes.

    @param _uri The value of the URI to lock for `_id`.
    @param _id The token ID to lock a metadata URI value into.
  */
  function lockURI(string calldata _uri, uint256 _id) external {
    require(_hasItemRight(_id, LOCK_ITEM_URI), "Super1155: you don't have rights to lock URI");
    metadataFrozen[_id] = true;
    emit PermanentURI(_uri, _id);
  }

  /**
    Allow the item collection owner or an associated manager to forever lock the
    metadata URI on a group of items to future changes.

    @param _uri The value of the URI to lock for `groupId`.
    @param groupId The group ID to lock a metadata URI value into.
  */
  function lockGroupURI(string calldata _uri, uint256 groupId) external {
    require(_hasItemRight(groupId, LOCK_ITEM_URI), "Super1155: you don't have rights to lock group URI");
    metadataFrozen[groupId] = true;
    emit PermanentURI(_uri, groupId);
  }

  /**
    Allow the item collection owner or an associated manager to forever lock
    this contract to further item minting.
  */
  function lock() external virtual hasValidPermit(UNIVERSAL, LOCK_CREATION) {
    locked = true;
    emit CollectionLocked(_msgSender());
  }

}