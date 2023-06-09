// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/token/ERC20/IERC20.sol";

interface IPerfToken is IERC20 {
    function enter(uint256 _amount) external;
    function leave(uint256 _share) external;
}