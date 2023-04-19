// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/// @title IRoyaltyGuard
/// @author highland, koloz, van arman
/// @notice Interface for the royalty guard with all the fields, errors, functions, etc.
interface IRoyaltyGuard {

  /*//////////////////////////////////////////////////////////////////////////
                              Enums
  //////////////////////////////////////////////////////////////////////////*/

    /// @notice An enum denoting 3 types for a list: OFF (0), ALLOW (1), DENY (2)
    enum ListType {
      OFF,
      ALLOW,
      DENY
    }

  /*//////////////////////////////////////////////////////////////////////////
                            Events
  //////////////////////////////////////////////////////////////////////////*/

  /// @notice Emitted when the list type is updated.
  event ListTypeUpdated(address indexed _updater, ListType indexed _oldListType, ListType indexed _newListType);

  /// @notice Emitted when an address is added to a list.
  event AddressAddedToList(address indexed _updater, address indexed _addedAddr, ListType indexed _ListType);

  /// @notice Emitted when an address is removed from a list.
  event AddressRemovedList(address indexed _updater, address indexed _removedAddr, ListType indexed _ListType);

  /// @notice Emitted when a list is cleared.
  event ListCleared(address indexed _updater, ListType _listType);

  /*//////////////////////////////////////////////////////////////////////////
                          Custom Errors
  //////////////////////////////////////////////////////////////////////////*/

  /// @notice Emitted when an unauthorized party tries to call a specific function.
  error Unauthorized();

  /// @notice Emitted when trying to add an address to a list with type OFF.
  error CantAddToOFFList();

  /// @notice Emitted when an admin only function tries to be called by a non-admin.
  error MustBeAdmin();

  /*//////////////////////////////////////////////////////////////////////////
                          External Write Functions
  //////////////////////////////////////////////////////////////////////////*/

  /// @notice Toggles the list type between ALLOW, DENY, or OFF
  /// @param _newListType to be applied to the list. Options are 0 (OFF), 1 (ALLOW), 2 (DENY)
  function toggleListType(IRoyaltyGuard.ListType _newListType) external;

  /// @notice Adds a list of addresses to the specified list.
  /// @param _listType that addresses are being added to
  /// @param _addrs being added to the designated list
  function batchAddAddressToRoyaltyList(IRoyaltyGuard.ListType _listType, address[] calldata _addrs) external;

  /// @notice Removes a list of addresses to the specified list.
  /// @param _listType that addresses are being removed from
  /// @param _addrs being removed from the designated list
  function batchRemoveAddressToRoyaltyList(IRoyaltyGuard.ListType _listType, address[] calldata _addrs) external;

  /// @notice Clears an entire list.
  /// @param _listType of list being cleared.
  function clearList(IRoyaltyGuard.ListType _listType) external;

  /*//////////////////////////////////////////////////////////////////////////
                          External Read Functions
  //////////////////////////////////////////////////////////////////////////*/

  /// @notice Returns the set of addresses on a list.
  /// @param _listType of list being retrieved.
  /// @return list of addresses on a given list.
  function getList(IRoyaltyGuard.ListType _listType) external view returns (address[] memory);

  /// @notice Returns the set of addresses on a list.
  /// @return list of addresses on a given list.
  function getInUseList() external view returns (address[] memory);

  /// @notice Returns if the supplied operator address in part of the current in use list.
  /// @param _operator address being checked.
  /// @return bool relating to if the operator is on the list.
  function isOperatorInList(address _operator) external view returns (bool);
  

  /// @notice States whether or not an address has admin permission.
  /// @return bool denoting if _addr has admin permission.
  function hasAdminPermission(address _addr) external view returns (bool);

  /// @notice Returns the ListType currently being used;
  /// @return ListType of the list. Values are: 0 (OFF), 1 (ALLOW), 2 (DENY)
  function getListType() external view returns (ListType);
}