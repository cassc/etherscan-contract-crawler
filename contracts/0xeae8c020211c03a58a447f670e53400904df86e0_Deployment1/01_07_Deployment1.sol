// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../defs/patterns/PatternsDefs1.sol";
import "../defs/patterns/PatternsDefs2.sol";
import "../defs/patterns/PatternsDefs3.sol";
import "../defs/patterns/PatternsDefs4.sol";
import "../defs/patterns/PatternsDefs5.sol";
import "../defs/patterns/PatternsDefs6.sol";

contract Deployment1 {

  function getPart() external pure returns (string memory) {
    return string.concat(
      PatternsDefs1.getPart(),
      PatternsDefs2.getPart(),
      PatternsDefs3.getPart(),
      PatternsDefs4.getPart(),
      PatternsDefs5.getPart(),
      PatternsDefs6.getPart()
    );
  }
}