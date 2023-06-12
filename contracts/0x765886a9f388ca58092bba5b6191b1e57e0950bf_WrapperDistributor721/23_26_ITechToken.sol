// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "IERC20.sol";

interface ITechToken is  IERC20 {
     function mint(address _to, uint256 _value) external;
}