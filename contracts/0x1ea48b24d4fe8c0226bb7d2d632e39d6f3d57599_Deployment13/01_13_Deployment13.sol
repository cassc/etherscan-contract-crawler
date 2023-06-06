// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../styles/conveyorBelt/ConveyorBeltCSS3.sol";

import "../styles/assets/AssetsCSS1.sol";
import "../styles/assets/AssetsCSS2.sol";

import "../styles/character/CharacterCSS1.sol";
import "../styles/character/CharacterCSS2.sol";

contract Deployment13 {

  function getPart() external pure returns (string memory) {

    return string.concat(
      ConveyorBeltCSS3.getPart(),
      AssetsCSS1.getPart(),
      AssetsCSS2.getPart(),
      CharacterCSS1.getPart(),
      CharacterCSS2.getPart()
    );
  }
}