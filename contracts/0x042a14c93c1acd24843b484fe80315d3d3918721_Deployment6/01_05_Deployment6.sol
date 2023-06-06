// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../defs/assets/AssetsDefs2.sol";

import "../defs/props/PropsDefs1.sol";

import "../defs/beast/BeastDefs1.sol";
import "../defs/beast/BeastDefs2.sol";

contract Deployment6 {

  function getPart() external pure returns (string memory) {

    return string.concat(
      AssetsDefs2.getPart(),
      PropsDefs1.getPart(),
      BeastDefs1.getPart(),
      BeastDefs2.getPart()
    );
  }
}