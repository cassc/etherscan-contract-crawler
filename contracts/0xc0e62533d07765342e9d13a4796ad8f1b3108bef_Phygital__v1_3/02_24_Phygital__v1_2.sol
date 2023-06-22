// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./Phygital__v1_1.sol";

contract Phygital__v1_2 is Phygital__v1_1 {
  using ECDSA for bytes32;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    initialize("", "");
  }

  modifier upgradeVersion(uint16 upgradeToVersion) {
    require(
      upgradeToVersion - minorVersion == 1 || (minorVersion == 0 && upgradeToVersion == 2),
      "Must be at the minor version prior to what is being upgraded to"
    );
    _;
    minorVersion = upgradeToVersion;
  }

  // Overidden to guard against which users can access
  function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}

  // Phygital__v1_1 => Phygital__v1_2 upgrade initializer
  function upgradeTo__v1_2() public onlyOwner upgradeVersion(2) {}

  // Deploying Phygital__v1_2 initializer
  function initialize__v1_2(string memory _name, string memory _symbol) public initializer {
    Phygital__v1_1.initialize__v1_1(_name, _symbol);
    upgradeTo__v1_2();
  }

  function mintBatch(address to, uint256[] calldata tokenIds) external virtual onlyOwner {
    for (uint256 i = 0; i < tokenIds.length; ++i) {
      _mint(to, tokenIds[i]);
    }
  }
}