// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC677.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IERC677Metadata is IERC677, IERC20Metadata {}