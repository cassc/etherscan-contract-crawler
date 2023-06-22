// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ERC165 {
  mapping(bytes4 => bool) private _supportedInterfaces;

  bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

  constructor() {
    _registerInterface(_INTERFACE_ID_ERC165);
  }

  function supportsInterface(bytes4 interfaceId) external view returns (bool) {
    return _supportedInterfaces[interfaceId];
  }

  function _registerInterface(bytes4 interfaceId) internal {
    require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
    _supportedInterfaces[interfaceId] = true;
  }
}