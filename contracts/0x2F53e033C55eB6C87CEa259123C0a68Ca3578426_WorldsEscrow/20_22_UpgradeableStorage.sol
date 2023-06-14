// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

library UpgradeableStorage {
  bytes32 private constant STORAGE_SLOT = keccak256("gg.topia.worlds.Upgradeable");

  struct Layout {
    mapping(bytes4 => address) upgrades;
  }

  function layout() internal pure returns (Layout storage _layout) {
    bytes32 slot = STORAGE_SLOT;

    assembly {
      _layout.slot := slot
    }
  }
}