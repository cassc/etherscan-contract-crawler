// SPDX-License-Identifier: PROTECTED
// [email protected]
pragma solidity ^0.8.0;

import "./IPlaned.sol";
import "./Secured.sol";
import "./Math.sol";

abstract contract Planed is IPlaned, Secured {
  uint256 internal _fee = 5;
  uint256 internal _more = 5;
  uint256 internal _less = 1;

  uint256[8] internal _planPrices = [
    0,
    6_00000000,
    11_00000000,
    21_00000000,
    34_00000000,
    55_00000000
  ];

  uint256[8] internal _planIds = [0, 51, 5, 31, 32, 47];

  // View functions --------------------------------------------------------
  function allOptions()
    external
    view
    override
    returns (
      uint256 fee,
      uint256 more,
      uint256 less,
      uint256[8] memory planIds,
      uint256[8] memory planPrices
    )
  {
    return (_fee, _more, _less, _planIds, _planPrices);
  }

  // Modify functions ----------------------------------------------------------
  function changePrice(uint8 index, uint40 price) external onlyAdmin {
    _planPrices[index] = price;
  }

  function changePlanId(uint8 index, uint40 id) external onlyAdmin {
    _planIds[index] = id;
  }

  function changePercentMore(uint8 value) external onlyAdmin {
    _more = value;
  }

  function changePercentLess(uint8 value) external onlyAdmin {
    _less = value;
  }

  function changeFee(uint256 value) public onlyOwner {
    _fee = value;
  }
}