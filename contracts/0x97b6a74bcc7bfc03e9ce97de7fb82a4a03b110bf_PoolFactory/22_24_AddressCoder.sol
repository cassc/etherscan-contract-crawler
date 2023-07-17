// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

library AddressCoder {
  function encodeAddress(address[] calldata addresses) internal pure returns (bytes memory data) {
    for (uint256 i = 0; i < addresses.length; i++) {
      data = abi.encodePacked(data, addresses[i]);
    }
  }

  function decodeAddress(bytes calldata data) internal pure returns (address[] memory addresses) {
    uint256 n = data.length / 20;
    addresses = new address[](n);

    for (uint256 i = 0; i < n; i++) {
      addresses[i] = bytesToAddress(data[i * 20:(i + 1) * 20]);
    }
  }

  function bytesToAddress(bytes calldata data) private pure returns (address addr) {
    bytes memory b = data;
    assembly {
      addr := mload(add(b, 20))
    }
  }
}