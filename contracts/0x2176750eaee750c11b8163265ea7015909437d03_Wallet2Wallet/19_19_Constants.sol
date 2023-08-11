// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';


contract Constants {
    IERC20 constant ETH = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    bytes32 constant W2W = 'W2W';
    bytes32 constant OWNER = 'OWNER';
    bytes32 constant REFERRER = 'REFERRER';
}