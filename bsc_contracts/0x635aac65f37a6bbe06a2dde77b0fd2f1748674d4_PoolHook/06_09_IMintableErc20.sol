// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

interface IMintableErc20 is IERC20 {
    function mint(address to, uint256 amount) external;
}