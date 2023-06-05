// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../styles/tubes/TubesCSS2.sol";

import "../styles/beast/BeastCSS1.sol";
import "../styles/beast/BeastCSS2.sol";
import "../styles/beast/BeastCSS3.sol";

import "../styles/conveyorBelt/ConveyorBeltCSS1.sol";
import "../styles/conveyorBelt/ConveyorBeltCSS2.sol";

contract Deployment12 {

  function getPart() external pure returns (string memory) {
    return string.concat(
      TubesCSS2.getPart(),
      BeastCSS1.getPart(),
      BeastCSS2.getPart(),
      BeastCSS3.getPart(),
      ConveyorBeltCSS1.getPart(),
      ConveyorBeltCSS2.getPart()
    );
  }
}