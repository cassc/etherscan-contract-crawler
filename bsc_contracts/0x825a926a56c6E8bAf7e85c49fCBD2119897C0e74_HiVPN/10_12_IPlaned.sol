// SPDX-License-Identifier: PROTECTED
// [email protected]
pragma solidity ^0.8.0;

import "./Secured.sol";
import "./Math.sol";

interface IPlaned {
  function allOptions()
    external
    view
    returns (
      uint256 fee,
      uint256 more,
      uint256 less,
      uint256[8] memory planIds,
      uint256[8] memory planPrices
    );
}