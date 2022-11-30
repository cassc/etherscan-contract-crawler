// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGFI is IERC20 {
  function mint(address account, uint256 amount) external;

  function setCap(uint256 _cap) external;

  function cap() external returns (uint256);

  event CapUpdated(address indexed who, uint256 cap);
}