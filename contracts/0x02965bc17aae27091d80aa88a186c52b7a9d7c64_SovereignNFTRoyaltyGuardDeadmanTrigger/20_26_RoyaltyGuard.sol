// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IRoyaltyGuard} from "./IRoyaltyGuard.sol";

import {EnumerableSet} from "openzeppelin-contracts/utils/structs/EnumerableSet.sol";
import {ERC165} from "openzeppelin-contracts/utils/introspection/ERC165.sol";

/// @title RoyaltyGuard
/// @author highland, koloz, van arman
/// @notice An abstract contract with the necessary functions, structures, modifiers to ensure royalties are paid.
/// @dev Inherriting this contract requires implementing {hasAdminPermission} and connecting the desired functions to the {checkList} modifier.
abstract contract RoyaltyGuard is IRoyaltyGuard, ERC165 {
  using EnumerableSet for EnumerableSet.AddressSet;

  /*//////////////////////////////////////////////////////////////////////////
                          Private Contract Storage
  //////////////////////////////////////////////////////////////////////////*/

  mapping(IRoyaltyGuard.ListType => EnumerableSet.AddressSet) private list;
  IRoyaltyGuard.ListType private listType;

  /*//////////////////////////////////////////////////////////////////////////
                                Modifiers
  //////////////////////////////////////////////////////////////////////////*/

  /// @notice Checks if an address is part the current, in-use list
  /// @dev depending on list type and if the address is on the list will throw {IRoyaltyGuard.Unauthorized}
  modifier checkList(address _addr) {
    if (listType == IRoyaltyGuard.ListType.ALLOW) {
      if (!list[IRoyaltyGuard.ListType.ALLOW].contains(_addr)) revert IRoyaltyGuard.Unauthorized();
    } else if (listType == IRoyaltyGuard.ListType.DENY) {
      if (list[IRoyaltyGuard.ListType.DENY].contains(_addr)) revert IRoyaltyGuard.Unauthorized();
    }
    _;
  }

  /// @notice Checks to see if the msg.sender has admin permissions.
  /// @dev {hasAdminPermissions} is an abstract function that the implementing contract will define.
  /// @dev if msg.sender doesnt have permission will throw {IRoyaltyGuard.MustBeAdmin}
  modifier onlyAdmin() {
    if (!hasAdminPermission(msg.sender)) revert IRoyaltyGuard.MustBeAdmin();
    _;
  }

  /*//////////////////////////////////////////////////////////////////////////
                            Admin Functions
  //////////////////////////////////////////////////////////////////////////*/

  /// @dev Only the contract owner can call this function.
  /// @inheritdoc IRoyaltyGuard
  function toggleListType(IRoyaltyGuard.ListType _newListType) external virtual onlyAdmin {
    _setListType(_newListType);
  }

  /// @dev Only the contract owner can call this function.
  /// @dev Cannot add to the OFF list
  /// @inheritdoc IRoyaltyGuard
  function batchAddAddressToRoyaltyList(IRoyaltyGuard.ListType _listType, address[] calldata _addrs) external virtual onlyAdmin {
    if (_listType == IRoyaltyGuard.ListType.OFF) revert IRoyaltyGuard.CantAddToOFFList();
    _batchUpdateList(_listType, _addrs, true);
  }

  /// @dev Only the contract owner can call this function.
  /// @inheritdoc IRoyaltyGuard
  function batchRemoveAddressToRoyaltyList(IRoyaltyGuard.ListType _listType, address[] calldata _addrs) external virtual onlyAdmin {
    _batchUpdateList(_listType, _addrs, false);
  }

  /// @dev Only the contract owner can call this function.
  /// @inheritdoc IRoyaltyGuard
  function clearList(IRoyaltyGuard.ListType _listType) external virtual onlyAdmin {
    delete list[_listType];
    emit ListCleared(msg.sender, _listType);
  }

  /*//////////////////////////////////////////////////////////////////////////
                          Public Read Functions
  //////////////////////////////////////////////////////////////////////////*/

  /// @inheritdoc IRoyaltyGuard
  function getList(IRoyaltyGuard.ListType _listType) external virtual view returns (address[] memory) {
    return list[_listType].values();
  }

  /// @inheritdoc IRoyaltyGuard
  function getInUseList() external virtual view returns (address[] memory) {
    return list[listType].values();
  }

  /// @inheritdoc IRoyaltyGuard
  function isOperatorInList(address _operator) external virtual view returns (bool) {
    return list[listType].contains(_operator);
  }

  /// @inheritdoc IRoyaltyGuard
  function getListType() external virtual view returns (IRoyaltyGuard.ListType) {
    return listType;
  }

  /// @dev used in the {onlyAdmin} modifier
  /// @inheritdoc IRoyaltyGuard
  function hasAdminPermission(address _addr) public virtual view returns (bool);

  /*//////////////////////////////////////////////////////////////////////////
                          ERC165 Overrides
  //////////////////////////////////////////////////////////////////////////*/

  /// @inheritdoc ERC165
  function supportsInterface(bytes4 _interfaceId) public virtual view override returns (bool) {
        return _interfaceId == type(IRoyaltyGuard).interfaceId || super.supportsInterface(_interfaceId);
    }

  /*//////////////////////////////////////////////////////////////////////////
                            Internal Functions
  //////////////////////////////////////////////////////////////////////////*/
  
  /// @dev Internal method to set list type. Main usage is constructor.
  function _setListType(IRoyaltyGuard.ListType _newListType) internal {
    emit ListTypeUpdated(msg.sender, listType, _newListType);
    listType = _newListType;
  }

  /// @dev Internal method to update a certain list. Main usage is constructor.
  function _batchUpdateList(IRoyaltyGuard.ListType _listType, address[] memory _addrs, bool _onList) internal {
    if (_listType != IRoyaltyGuard.ListType.OFF) {
      for (uint256 i = 0; i < _addrs.length; i++) {
        if (_onList) {
          list[_listType].add(_addrs[i]);
          emit AddressAddedToList(msg.sender, _addrs[i], _listType);
        } else {
          list[_listType].remove(_addrs[i]);
          emit AddressRemovedList(msg.sender, _addrs[i], _listType);
        }
      }
    }
  }
}