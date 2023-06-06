// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../defs/patterns/PatternsDefs13.sol";
import "../defs/patterns/PatternsDefs14.sol";
import "../defs/patterns/PatternsDefs15.sol";
import "../defs/patterns/PatternsDefs16.sol";
import "../defs/patterns/PatternsDefs17.sol";
import "../defs/patterns/PatternsDefs18.sol";

contract Deployment3 {

  function getPart() external pure returns (string memory) {
    return string.concat(
      PatternsDefs13.getPart(),
      PatternsDefs14.getPart(),
      PatternsDefs15.getPart(),
      PatternsDefs16.getPart(),
      PatternsDefs17.getPart(),
      PatternsDefs18.getPart()
    );
  }
}