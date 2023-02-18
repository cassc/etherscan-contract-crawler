// SPDX-License-Identifier: MIT

import "./IERC20.sol";


// File: contracts/interfaces/IWETH.sol
pragma solidity 0.6.12;

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}