// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../sound/SoundImp7.sol";
import "../sound/SoundImp8.sol";
import "../sound/SoundImp9.sol";
import "../sound/SoundImp10.sol";
import "../sound/SoundImp11.sol";

contract Deployment8 {

  function getPart() external pure returns (string memory) {

    return string.concat(
      SoundImp7.getPart(),
      SoundImp8.getPart(),
      SoundImp9.getPart(),
      SoundImp10.getPart(),
      SoundImp11.getPart()
    );
  }
}