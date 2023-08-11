// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IBuyBacker {
    receive() payable external;
    function buyBack(IERC20[] calldata _tokens, bytes[] calldata _datas) external;
}