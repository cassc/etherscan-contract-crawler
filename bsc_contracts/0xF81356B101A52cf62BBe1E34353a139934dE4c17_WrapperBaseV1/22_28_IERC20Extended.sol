// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "IERC20.sol";

interface IERC20Extended is  IERC20 {
     function mint(address _to, uint256 _value) external;
}