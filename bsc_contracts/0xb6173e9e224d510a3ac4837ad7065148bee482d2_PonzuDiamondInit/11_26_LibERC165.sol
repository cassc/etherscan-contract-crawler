// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC165Storage} from "./ERC165Storage.sol";

library LibERC165 {
  bytes32 internal constant ERC165_STORAGE_POSITION = keccak256("diamond.standard.erc165.storage");

  function DS() internal pure returns (ERC165Storage storage ds) {
    bytes32 position = ERC165_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  function addSupportedInterfaces(bytes4[] memory _interfaces) internal {
    ERC165Storage storage ds = DS();
    uint256 length = _interfaces.length;
    for (uint256 i; i < length; ) {
      ds.supportedInterfaces[_interfaces[i]] = true;
      unchecked {
        ++i;
      }
    }
  }

  function addSupportedInterface(bytes4 _interface) internal {
    ERC165Storage storage ds = DS();
    ds.supportedInterfaces[_interface] = true;
  }
}