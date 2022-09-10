// SPDX-License-Identifier: MIT

pragma solidity =0.8.16;

library SafeMath {
  
  function sub(uint256 a, uint256 b) internal pure returns (uint256)
  {
  unchecked
  {
    require(b <= a, 'SafeMath.sub(): negative result.');
    return a - b;
  }
  }
  
  
  function mul(uint256 a, uint256 b) internal pure returns (uint256)
  {
    return a * b;
  }
  
  
  function div(uint256 a, uint256 b) internal pure returns (uint256)
  {
  unchecked
  {
    require(b > 0, 'SafeMath.div(): division by zero.');
    return a / b;
  }
  }
}