// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Storage is Ownable {
  /// @dev Bytes storage.
  mapping(bytes32 => bytes) private _bytes;

  /// @dev Bool storage.
  mapping(bytes32 => bool) private _bool;

  /// @dev Uint storage.
  mapping(bytes32 => uint256) private _uint;

  /// @dev Int storage.
  mapping(bytes32 => int256) private _int;

  /// @dev Address storage.
  mapping(bytes32 => address) private _address;

  /// @dev String storage.
  mapping(bytes32 => string) private _string;

  event Updated(bytes32 indexed key);

  /**
   * @param key The key for the record
   */
  function getBytes(bytes32 key) external view returns (bytes memory) {
    return _bytes[key];
  }

  /**
   * @param key The key for the record
   */
  function getBool(bytes32 key) external view returns (bool) {
    return _bool[key];
  }

  /**
   * @param key The key for the record
   */
  function getUint(bytes32 key) external view returns (uint256) {
    return _uint[key];
  }

  /**
   * @param key The key for the record
   */
  function getInt(bytes32 key) external view returns (int256) {
    return _int[key];
  }

  /**
   * @param key The key for the record
   */
  function getAddress(bytes32 key) external view returns (address) {
    return _address[key];
  }

  /**
   * @param key The key for the record
   */
  function getString(bytes32 key) external view returns (string memory) {
    return _string[key];
  }

  /**
   * @param key The key for the record
   * @param value The value to set.
   */
  function setBytes(bytes32 key, bytes calldata value) external onlyOwner {
    _bytes[key] = value;
    emit Updated(key);
  }

  /**
   * @param key The key for the record
   * @param value The value to set.
   */
  function setBool(bytes32 key, bool value) external onlyOwner {
    _bool[key] = value;
    emit Updated(key);
  }

  /**
   * @param key The key for the record
   * @param value The value to set.
   */
  function setUint(bytes32 key, uint256 value) external onlyOwner {
    _uint[key] = value;
    emit Updated(key);
  }

  /**
   * @param key The key for the record
   * @param value The value to set.
   */
  function setInt(bytes32 key, int256 value) external onlyOwner {
    _int[key] = value;
    emit Updated(key);
  }

  /**
   * @param key The key for the record
   * @param value The value to set.
   */
  function setAddress(bytes32 key, address value) external onlyOwner {
    _address[key] = value;
    emit Updated(key);
  }

  /**
   * @param key The key for the record
   * @param value The value to set.
   */
  function setString(bytes32 key, string calldata value) external onlyOwner {
    _string[key] = value;
    emit Updated(key);
  }

  /**
   * @param key The key for the record
   */
  function deleteBytes(bytes32 key) external onlyOwner {
    delete _bytes[key];
    emit Updated(key);
  }

  /**
   * @param key The key for the record
   */
  function deleteBool(bytes32 key) external onlyOwner {
    delete _bool[key];
    emit Updated(key);
  }

  /**
   * @param key The key for the record
   */
  function deleteUint(bytes32 key) external onlyOwner {
    delete _uint[key];
    emit Updated(key);
  }

  /**
   * @param key The key for the record
   */
  function deleteInt(bytes32 key) external onlyOwner {
    delete _int[key];
    emit Updated(key);
  }

  /**
   * @param key The key for the record
   */
  function deleteAddress(bytes32 key) external onlyOwner {
    delete _address[key];
    emit Updated(key);
  }

  /**
   * @param key The key for the record
   */
  function deleteString(bytes32 key) external onlyOwner {
    delete _string[key];
    emit Updated(key);
  }
}