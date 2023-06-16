// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.7.6;

import { IERC20 } from "../balancer-core-v2/lib/openzeppelin/IERC20.sol";

interface IERC20Decimals is IERC20 {
  // Non standard but almost all erc20 have this
  function decimals() external view returns (uint8);
}