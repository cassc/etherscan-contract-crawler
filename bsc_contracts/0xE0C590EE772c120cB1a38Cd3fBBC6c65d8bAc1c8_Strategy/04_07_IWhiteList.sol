// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

interface IWhiteList {
  /// @notice Emits when MilestoneBased contract or owner adds new address to the contract.
  /// @param newAddress address of new contract to add.
  event AddedNewAddress(address indexed newAddress);
  /// @notice Emits when owner remove address from the contract.
  /// @param invalidAddress address of contract for removing.
  event RemovedAddress(address indexed invalidAddress);

  /// @notice Add new address to the contract.
  /// @param newAddress address to add.
  function addNewAddress(address newAddress) external;

  /// @notice Add new addresses to the contract.
  /// @param newAddresses array of new addresses.
  function addNewAddressesBatch(address[] memory newAddresses) external;

  /// @notice Remove passed address from the contract.
  /// @param invalidAddress address for removing.
  function removeAddress(address invalidAddress) external;

  /// @notice Remove passed addresses from the contract.
  /// @param invalidAddresses array of addresses to remove.
  function removeAddressesBatch(address[] memory invalidAddresses) external;

  /// @notice Return limit of addresses with pagination of MB platform.
  /// @param offset index from which the function starts collecting addresses.
  /// @param limit amount of addresses to return.
  /// @return White list addresses array.
  function getWhitelistedAddresses(uint256 offset, uint256 limit)
    external
    view
    returns (address[] memory);

  /// @notice Return true if contract has such address, and false if doesn’t.
  /// @param accountAddress address to check.
  /// @return The presence of the address in the list.
  function isValidAddress(address accountAddress) external view returns (bool);
}