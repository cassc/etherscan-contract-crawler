/*

    Copyright 2022 31Third B.V.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ExchangeAdapterRegistry is Ownable {
  /*** ### Events ### ***/

  event AdapterAdded(address indexed adapter, string adapterName);
  event AdapterRemoved(address indexed adapter, string adapterName);
  event AdapterEdited(address indexed newAdapter, string adapterName);

  /*** ### Custom Errors ### ***/

  error RenounceOwnershipDisabled();
  error NameEmptyString();
  error NameAlreadyExists(string name);
  error InvalidAddress(string paramName, address passedAddress);
  error EmptyArray(string name);
  error ArrayLengthMismatch(string name1, string name2);
  error NoAdapterWithName(string name);

  /*** ### State Variables ### ***/

  // Mapping of exchange adapter identifier => adapter address
  mapping(bytes32 => address) private adapters;

  /*** ### External Functions ### ***/

  /**
   * ONLY OWNER: Override renounceOwnership to disable it
   */
  function renounceOwnership() public override view onlyOwner {
    revert RenounceOwnershipDisabled();
  }

  /**
   * ONLY OWNER: Add a new adapter to the registry
   *
   * @param  _name    Human readable string identifying the adapter
   * @param  _adapter Address of the adapter contract to add
   */
  function addAdapter(string memory _name, address _adapter) public onlyOwner {
    if (bytes(_name).length == 0) {
      revert NameEmptyString();
    }

    bytes32 hashedName = _getNameHash(_name);
    if (adapters[hashedName] != address(0)) {
      revert NameAlreadyExists(_name);
    }

    if (_adapter == address(0)) {
      revert InvalidAddress("_adapter", _adapter);
    }

    adapters[hashedName] = _adapter;

    emit AdapterAdded(_adapter, _name);
  }

  /**
   * ONLY OWNER: Batch add new adapters. Reverts if exists on any module and name
   *
   * @param  _names    Array of human readable strings identifying the adapter
   * @param  _adapters Array of addresses of the adapter contracts to add
   */
  function batchAddAdapter(
    string[] memory _names,
    address[] memory _adapters
  ) external onlyOwner {
    // Storing modules count to local variable to save on invocation
    uint256 namesCount = _names.length;

    if (namesCount == 0) {
      revert EmptyArray("_names");
    }
    if (namesCount != _adapters.length) {
      revert ArrayLengthMismatch("_names", "_adapters");
    }

    for (uint256 i = 0; i < namesCount; i++) {
      // Add adapters to the specified module. Will revert if module and name combination exists
      addAdapter(_names[i], _adapters[i]);
    }
  }

  /**
   * ONLY OWNER: Edit an existing adapter on the registry
   *
   * @param  _name    Human readable string identifying the adapter
   * @param  _adapter Address of the adapter contract to edit
   */
  function editAdapter(string memory _name, address _adapter) public onlyOwner {
    bytes32 hashedName = _getNameHash(_name);

    if (adapters[hashedName] == address(0)) {
      revert NoAdapterWithName(_name);
    }
    if (_adapter == address(0)) {
      revert InvalidAddress("_adapter", _adapter);
    }

    adapters[hashedName] = _adapter;

    emit AdapterEdited(_adapter, _name);
  }

  /**
   * ONLY OWNER: Batch edit adapters for modules. Reverts if module and
   * adapter name don't map to an adapter address
   *
   * @param  _names    Array of human readable strings identifying the adapter
   * @param  _adapters Array of addresses of the adapter contracts to add
   */
  function batchEditAdapter(
    string[] memory _names,
    address[] memory _adapters
  ) external onlyOwner {
    // Storing name count to local variable to save on invocation
    uint256 namesCount = _names.length;

    if (namesCount == 0) {
      revert EmptyArray("_names");
    }
    if (namesCount != _adapters.length) {
      revert ArrayLengthMismatch("_names", "_adapters");
    }

    for (uint256 i = 0; i < namesCount; i++) {
      // Edits adapters to the specified module. Will revert if module and name combination does not exist
      editAdapter(_names[i], _adapters[i]);
    }
  }

  /**
   * ONLY OWNER: Remove an existing adapter on the registry
   *
   * @param  _name Human readable string identifying the adapter
   */
  function removeAdapter(string memory _name) external onlyOwner {
    bytes32 hashedName = _getNameHash(_name);
    if (adapters[hashedName] == address(0)) {
      revert NoAdapterWithName(_name);
    }

    address oldAdapter = adapters[hashedName];
    delete adapters[hashedName];

    emit AdapterRemoved(oldAdapter, _name);
  }

  /*** ### External Getter Functions ### ***/

  /**
   * Get adapter adapter address associated with passed human readable name
   *
   * @param  _name Human readable adapter name
   *
   * @return       Address of adapter
   */
  function getAdapter(string memory _name) external view returns (address) {
    return adapters[_getNameHash(_name)];
  }

  /**
   * Get adapter adapter address associated with passed hashed name
   *
   * @param  _nameHash Hash of human readable adapter name
   *
   * @return           Address of adapter
   */
  function getAdapterWithHash(
    bytes32 _nameHash
  ) external view returns (address) {
    return adapters[_nameHash];
  }

  /**
   * Check if adapter name is valid
   *
   * @param  _name Human readable string identifying the adapter
   *
   * @return       Boolean indicating if valid
   */
  function isValidAdapter(string memory _name) external view returns (bool) {
    return adapters[_getNameHash(_name)] != address(0);
  }

  /*** ### Internal Functions ### ***/

  /**
   * Hashes the string and returns a bytes32 value
   */
  function _getNameHash(string memory _name) internal pure returns (bytes32) {
    return keccak256(bytes(_name));
  }
}