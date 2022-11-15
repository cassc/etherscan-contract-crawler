//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "IERC20.sol";

pragma experimental ABIEncoderV2;

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
}