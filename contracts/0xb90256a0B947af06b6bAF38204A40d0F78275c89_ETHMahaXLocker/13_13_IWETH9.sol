// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from '@openzeppelin/contracts/interfaces/IERC20.sol';

interface IWETH9 is IERC20 {
    function deposit() external payable;

    function withdraw(uint wad) external;
}