// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./MegNFT.sol";

contract MegLand is MegNFT {
  /**
   * @dev Upgradable initializer
   * @param _standardUri URI string
   * @param _premiumUri URI string
   */
  function __MegLand_init(string memory _standardUri, string memory _premiumUri) external initializer {
    __MegNFT_init("Meg Land", "ML", _standardUri, _premiumUri);
  }
}