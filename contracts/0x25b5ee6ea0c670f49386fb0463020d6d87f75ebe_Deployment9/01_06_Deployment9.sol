// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../sound/SoundImp12.sol";
import "../sound/SoundImp13.sol";
import "../sound/SoundImp14.sol";
import "../sound/SoundImp15.sol";
import "../sound/SoundImp16.sol";

contract Deployment9 {

  function getPart() external pure returns (string memory) {

    return string.concat(
      SoundImp12.getPart(),
      SoundImp13.getPart(),
      SoundImp14.getPart(),
      SoundImp15.getPart(),
      SoundImp16.getPart()
    );
  }
}