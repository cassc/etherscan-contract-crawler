// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;


library SafeMath {
  function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x + y) >= x, "ds-math-add-overflow");
  }

  function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x - y) <= x, "ds-math-sub-underflow");
  }

  function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
  }


  function add(uint256 x, uint256 y, string memory errorMessage) internal pure returns (uint256 z) {
    require((z = x + y) >= x, errorMessage);
  }

  function sub(uint256 x, uint256 y, string memory errorMessage) internal pure returns (uint256 z) {
    require((z = x - y) <= x, errorMessage);
  }

  function mul(uint256 x, uint256 y, string memory errorMessage) internal pure returns (uint256 z) {
    require(y == 0 || (z = x * y) / y == x, errorMessage);
  }
}