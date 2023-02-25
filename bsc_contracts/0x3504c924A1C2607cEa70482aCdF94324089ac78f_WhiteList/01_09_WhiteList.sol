// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./interfaces/IWhiteList.sol";

/// @title The contract keep addresses of all contracts which are using on MilestoneBased platform.
/// @dev It is used by sMILE token for transactions restriction.
contract WhiteList is IWhiteList, AccessControl {
  using EnumerableSet for EnumerableSet.AddressSet;
  /// @notice Stores the factory role key hash.
  /// @return Bytes representing fectory role key hash.
  bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");

  ///@dev Throws when sender hasn't role DEFAULT_ADMIN_ROLE or FACTORY_ROLE
  error NotAdminOrFactory(); 

  /// @notice Stores a set of all contracts which are using on MilestoneBased platform.
  EnumerableSet.AddressSet private _whiteList;

  modifier onlyAdminOrFactory() {
    if(!(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || hasRole(FACTORY_ROLE, _msgSender()))){
      revert NotAdminOrFactory();
    }
    _;
  }

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  /// @notice Add new addresses to the contract.
  /// @param newAddresses array of new addresses.
  function addNewAddressesBatch(address[] memory newAddresses)
    external
    onlyAdminOrFactory
  {
    for (uint256 i; i < newAddresses.length; i++) {
      _addNewAddress(newAddresses[i]);
    }
  }

  /// @notice Remove passed addresses from the contract.
  /// @param invalidAddresses array of addresses to remove.
  function removeAddressesBatch(address[] memory invalidAddresses)
    external
    onlyAdminOrFactory
  {
    for (uint256 i; i < invalidAddresses.length; i++) {
      _removeAddress(invalidAddresses[i]);
    }
  }

  /// @notice Add new address to the contract.
  /// @param newAddress address to add.
  function addNewAddress(address newAddress) external onlyAdminOrFactory {
    _addNewAddress(newAddress);
  }

  /// @notice Remove passed address from the contract.
  /// @param invalidAddress address for removing.
  function removeAddress(address invalidAddress) external onlyAdminOrFactory {
    _removeAddress(invalidAddress);
  }

  /// @notice Return limit of addresses with pagination of MB platform.
  /// @param offset index from which the function starts collecting addresses.
  /// @param limit amount of addresses to return.
  /// @return White list addresses array.
  function getWhitelistedAddresses(uint256 offset, uint256 limit)
    external
    view
    returns (address[] memory)
  {
    uint256 totalWhitelistedAddressesCount = _whiteList.length();
    if (totalWhitelistedAddressesCount <= offset) {
      return new address[](0);
    }

    if (limit > totalWhitelistedAddressesCount - offset) {
      limit = totalWhitelistedAddressesCount - offset;
    }

    address[] memory addresses = new address[](limit);
    for (uint256 i; i < limit; i++) {
      addresses[i] = _whiteList.at(offset + i);
    }

    return addresses;
  }

  /// @notice Return true if contract has such address, and false if doesn’t.
  /// @param accountAddress address to check.
  /// @return The presence of the address in the list.
  function isValidAddress(address accountAddress) external view returns (bool) {
    return _whiteList.contains(accountAddress);
  }


  function _addNewAddress(address newAddress) internal{
    if(_whiteList.add(newAddress)){
      emit AddedNewAddress(newAddress);
    }
  }

  function _removeAddress(address invalidAddress) internal{
    if(_whiteList.remove(invalidAddress)){
      emit RemovedAddress(invalidAddress);
    }
  }
}