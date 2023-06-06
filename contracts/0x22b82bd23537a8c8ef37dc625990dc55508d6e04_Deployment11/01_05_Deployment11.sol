// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../styles/cells/CellsCSS1.sol";
import "../styles/cells/CellsCSS2.sol";
import "../styles/cells/CellsCSS3.sol";

import "../styles/tubes/TubesCSS1.sol";

contract Deployment11 {

  function getPart() external pure returns (string memory) {

    return string.concat(
      CellsCSS1.getPart(),
      CellsCSS2.getPart(),
      CellsCSS3.getPart(),
      TubesCSS1.getPart()
    );
  }
}