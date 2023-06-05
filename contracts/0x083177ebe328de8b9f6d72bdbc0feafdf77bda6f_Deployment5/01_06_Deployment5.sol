// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../defs/cells/CellsDefs1.sol";
import "../defs/cells/CellsDefs2.sol";

import "../defs/tubes/TubesDefs1.sol";

import "../defs/conveyorBelt/ConveyorBeltDefs1.sol";

import "../defs/assets/AssetsDefs1.sol";

contract Deployment5 {

  function getPart() external pure returns (string memory) {
    return string.concat(
      CellsDefs1.getPart(),
      CellsDefs2.getPart(),
      TubesDefs1.getPart(),
      ConveyorBeltDefs1.getPart(),
      AssetsDefs1.getPart()
    );
  }
}