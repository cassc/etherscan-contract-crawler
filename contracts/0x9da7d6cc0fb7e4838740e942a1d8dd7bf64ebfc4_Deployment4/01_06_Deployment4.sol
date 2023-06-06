// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../defs/apparatus/ApparatusDefs1.sol";
import "../defs/apparatus/ApparatusDefs2.sol";

import "../defs/altar/AltarDefs1.sol";
import "../defs/altar/AltarDefs2.sol";
import "../defs/altar/AltarDefs3.sol";

contract Deployment4 {

  function getPart() external pure returns (string memory) {

    return string.concat(
      ApparatusDefs1.getPart(),
      ApparatusDefs2.getPart(),
      AltarDefs1.getPart(),
      AltarDefs2.getPart(),
      AltarDefs3.getPart()
    );
  }
}