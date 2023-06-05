// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../sound/SoundImp1.sol";
import "../sound/SoundImp2.sol";
import "../sound/SoundImp3.sol";
import "../sound/SoundImp4.sol";
import "../sound/SoundImp5.sol";
import "../sound/SoundImp6.sol";

contract Deployment7 {

  function getPart() external pure returns (string memory) {
    return string.concat(
      SoundImp1.getPart(),
      SoundImp2.getPart(),
      SoundImp3.getPart(),
      SoundImp4.getPart(),
      SoundImp5.getPart(),
      SoundImp6.getPart()
    );
  }
}