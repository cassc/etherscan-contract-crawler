// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../defs/patterns/PatternsDefs7.sol";
import "../defs/patterns/PatternsDefs8.sol";
import "../defs/patterns/PatternsDefs9.sol";
import "../defs/patterns/PatternsDefs10.sol";
import "../defs/patterns/PatternsDefs11.sol";
import "../defs/patterns/PatternsDefs12.sol";

contract Deployment2 {

  function getPart() external pure returns (string memory) {

    return string.concat(
      PatternsDefs7.getPart(),
      PatternsDefs8.getPart(),
      PatternsDefs9.getPart(),
      PatternsDefs10.getPart(),
      PatternsDefs11.getPart(),
      PatternsDefs12.getPart()
    );
  }
}