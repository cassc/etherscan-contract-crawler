// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract IGatewayToken is IERC20 {
  function fromUnderlying(uint256) external view virtual returns (uint256);
}