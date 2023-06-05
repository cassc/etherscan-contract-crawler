// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../styles/apparatus/ApparatusCSS1.sol";
import "../styles/apparatus/ApparatusCSS2.sol";
import "../styles/apparatus/ApparatusCSS3.sol";

import "../styles/altar/AltarCSS1.sol";

contract Deployment10 {

  function getPart() external pure returns (string memory) {
    return string.concat(
      ApparatusCSS1.getPart(), // MUST: be apparatucss1 after getAnimationSpeed
      ApparatusCSS2.getPart(),
      ApparatusCSS3.getPart(),
      AltarCSS1.getPart()
    );
  }
}