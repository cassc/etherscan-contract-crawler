// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Revocable {
  mapping(bytes32 => bool) private _isRevoked;

  function _revokeHash(bytes32 hash) internal {
    require(!_isRevoked[hash], "Revocable: hash verification failed");
    _isRevoked[hash] = true;
  }

  function _validateHash(bytes32 hash) internal view returns (bool, string memory) {
    if (_isRevoked[hash]) {
      return (false, "Revocable: hash verification failed");
    }
    return (true, "");
  }

  // solhint-disable-next-line ordering
  uint256[50] private __gap;
}