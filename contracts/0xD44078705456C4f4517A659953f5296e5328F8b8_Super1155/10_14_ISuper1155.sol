// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.8;

import "../../../libraries/DFStorage.sol";

/**
  @title An interface for the `Super1155` ERC-1155 item collection contract.
  @author 0xthrpw
  @author Tim Clancy

  August 12th, 2021.
*/
interface ISuper1155 {

  /// The public identifier for the right to set this contract's metadata URI.
  function SET_URI () external view returns (bytes32);

  /// The public identifier for the right to set this contract's proxy registry.
  function SET_PROXY_REGISTRY () external view returns (bytes32);

  /// The public identifier for the right to configure item groups.
  function CONFIGURE_GROUP () external view returns (bytes32);

  /// The public identifier for the right to mint items.
  function MINT () external view returns (bytes32);

  /// The public identifier for the right to burn items.
  function BURN () external view returns (bytes32);

  /// The public identifier for the right to set item metadata.
  function SET_METADATA () external view returns (bytes32);

  /// The public identifier for the right to lock the metadata URI.
  function LOCK_URI () external view returns (bytes32);

  /// The public identifier for the right to lock an item's metadata.
  function LOCK_ITEM_URI () external view returns (bytes32);

  /// The public identifier for the right to disable item creation.
  function LOCK_CREATION () external view returns (bytes32);

  /// The public name of this contract.
  function name () external view returns (string memory);

  /**
    The ERC-1155 URI for tracking item metadata, supporting {id} substitution.
    For example: https://token-cdn-domain/{id}.json. See the ERC-1155 spec for
    more details: https://eips.ethereum.org/EIPS/eip-1155#metadata.
  */
  function metadataUri () external view returns (string memory);

  /// A proxy registry address for supporting automatic delegated approval.
  function proxyRegistryAddress () external view returns (address);

  /// A mapping from each group ID to per-address balances.
  function groupBalances (uint256, address) external view returns (uint256);

  /// A mapping from each address to a collection-wide balance.
  function totalBalances (address) external view returns (uint256);

  /// A mapping of data for each item group.
  // function itemGroups (uint256) external view returns (ItemGroup memory);
  /* function itemGroups (uint256) external view returns (bool initialized, string memory _name, uint8 supplyType, uint256 supplyData, uint8 itemType, uint256 itemData, uint8 burnType, uint256 burnData, uint256 _circulatingSupply, uint256 _mintCount, uint256 _burnCount); */

  /// A mapping of circulating supplies for each individual token.
  function circulatingSupply (uint256) external view returns (uint256);

  /// A mapping of the number of times each individual token has been minted.
  function mintCount (uint256) external view returns (uint256);

  /// A mapping of the number of times each individual token has been burnt.
  function burnCount (uint256) external view returns (uint256);

  /**
    A mapping of token ID to a boolean representing whether the item's metadata
    has been explicitly frozen via a call to `lockURI(string calldata _uri,
    uint256 _id)`. Do note that it is possible for an item's mapping here to be
    false while still having frozen metadata if the item collection as a whole
    has had its `uriLocked` value set to true.
  */
  function metadataFrozen (uint256) external view returns (bool);

  /**
    A public mapping of optional on-chain metadata for each token ID. A token's
    on-chain metadata is unable to be changed if the item's metadata URI has
    been permanently fixed or if the collection's metadata URI as a whole has
    been frozen.
  */
  function metadata (uint256) external view returns (string memory);

  /// Whether or not the metadata URI has been locked to future changes.
  function uriLocked () external view returns (bool);

  /// Whether or not the item collection has been locked to all further minting.
  function locked () external view returns (bool);

  /**
    Return a version number for this contract's interface.
  */
  function version () external view returns (uint256);

  /**
    Return the item collection's metadata URI. This implementation returns the
    same URI for all tokens within the collection and relies on client-side
    ID substitution per https://eips.ethereum.org/EIPS/eip-1155#metadata. Per
    said specification, clients calling this function must replace the {id}
    substring with the actual token ID in hex, not prefixed by 0x, and padded
    to 64 characters in length.

    @return The metadata URI string of the item with ID `_itemId`.
  */
  function uri (uint256) external view returns (string memory);

  /**
    Allow the item collection owner or an approved manager to update the
    metadata URI of this collection. This implementation relies on a single URI
    for all items within the collection, and as such does not emit the standard
    URI event. Instead, we emit our own event to reflect changes in the URI.

    @param _uri The new URI to update to.
  */
  function setURI (string memory _uri) external;

  /**
    Allow the item collection owner or an approved manager to update the proxy
    registry address handling delegated approval.

    @param _proxyRegistryAddress The address of the new proxy registry to
      update to.
  */
  function setProxyRegistry (address _proxyRegistryAddress) external;

  /**
    Retrieve the balance of a particular token `_id` for a particular address
    `_owner`.

    @param _owner The owner to check for this token balance.
    @param _id The ID of the token to check for a balance.
    @return The amount of token `_id` owned by `_owner`.
  */
  function balanceOf (address _owner, uint256 _id) external view returns (uint256);

  /**
    Retrieve in a single call the balances of some mulitple particular token
    `_ids` held by corresponding `_owners`.

    @param _owners The owners to check for token balances.
    @param _ids The IDs of tokens to check for balances.
    @return the amount of each token owned by each owner.
  */
  function balanceOfBatch (address[] memory _owners, uint256[] memory _ids) external view returns (uint256[] memory);

  /**
    This function returns true if `_operator` is approved to transfer items
    owned by `_owner`. This approval check features an override to explicitly
    whitelist any addresses delegated in the proxy registry.

    @param _owner The owner of items to check for transfer ability.
    @param _operator The potential transferrer of `_owner`'s items.
    @return Whether `_operator` may transfer items owned by `_owner`.
  */
  function isApprovedForAll (address _owner, address _operator) external view returns (bool);

  /**
    Enable or disable approval for a third party `_operator` address to manage
    (transfer or burn) all of the caller's tokens.

    @param _operator The address to grant management rights over all of the
      caller's tokens.
    @param _approved The status of the `_operator`'s approval for the caller.
  */
  function setApprovalForAll (address _operator, bool _approved) external;

  /**
    Transfer on behalf of a caller or one of their authorized token managers
    items from one address to another.

    @param _from The address to transfer tokens from.
    @param _to The address to transfer tokens to.
    @param _id The specific token ID to transfer.
    @param _amount The amount of the specific `_id` to transfer.
    @param _data Additional call data to send with this transfer.
  */
  function safeTransferFrom (address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data) external;

  /**
    Transfer on behalf of a caller or one of their authorized token managers
    items from one address to another.

    @param _from The address to transfer tokens from.
    @param _to The address to transfer tokens to.
    @param _ids The specific token IDs to transfer.
    @param _amounts The amounts of the specific `_ids` to transfer.
    @param _data Additional call data to send with this transfer.
  */
  function safeBatchTransferFrom (address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data) external;

  /**
    Create a new NFT item group or configure an existing one. NFTs within a
    group share a group ID in the upper 128-bits of their full item ID.
    Within a group NFTs can be distinguished for the purposes of serializing
    issue numbers.

    @param _groupId The ID of the item group to create or configure.
    @param _data The `ItemGroup` data input.
  */
  function configureGroup (uint256 _groupId, DFStorage.ItemGroupInput calldata _data) external;

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
  function mintBatch (address _recipient, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data) external;

  /**
    This function allows an address to destroy some of its items.

    @param _burner The address whose item is burning.
    @param _id The item ID to burn.
    @param _amount The amount of the corresponding item ID to burn.
  */
  function burn (address _burner, uint256 _id, uint256 _amount) external;

  /**
    This function allows an address to destroy multiple different items in a
    single call.

    @param _burner The address whose items are burning.
    @param _ids The item IDs to burn.
    @param _amounts The amounts of the corresponding item IDs to burn.
  */
  function burnBatch (address _burner, uint256[] memory _ids, uint256[] memory _amounts) external;

  /**
    Set the on-chain metadata attached to a specific token ID so long as the
    collection as a whole or the token specifically has not had metadata
    editing frozen.

    @param _id The ID of the token to set the `_metadata` for.
    @param _metadata The metadata string to store on-chain.
  */
  function setMetadata (uint256 _id, string memory _metadata) external;

  /**
    Allow the item collection owner or an associated manager to forever lock the
    metadata URI on the entire collection to future changes.

    @param _uri The value of the URI to lock for `_id`.
  */
  function lockURI(string calldata _uri) external;

  /**
    Allow the item collection owner or an associated manager to forever lock the
    metadata URI on an item to future changes.

    @param _uri The value of the URI to lock for `_id`.
    @param _id The token ID to lock a metadata URI value into.
  */
  function lockURI(string calldata _uri, uint256 _id) external;


  /**
    Allow the item collection owner or an associated manager to forever lock the
    metadata URI on a group of items to future changes.

    @param _uri The value of the URI to lock for `groupId`.
    @param groupId The group ID to lock a metadata URI value into.
  */
  function lockGroupURI(string calldata _uri, uint256 groupId) external;

  /**
    Allow the item collection owner or an associated manager to forever lock
    this contract to further item minting.
  */
  function lock() external;
}