// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

library Revert {
  function revert_(bytes memory reason) internal pure {
    assembly ("memory-safe") {
      revert(add(reason, 0x20), mload(reason))
    }
  }
}