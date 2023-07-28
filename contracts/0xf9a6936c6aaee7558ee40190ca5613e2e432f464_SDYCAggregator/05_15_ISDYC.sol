// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

interface ISDYC is IERC20 {
    function processFees(uint256 _interest, uint256 _price) external;
}