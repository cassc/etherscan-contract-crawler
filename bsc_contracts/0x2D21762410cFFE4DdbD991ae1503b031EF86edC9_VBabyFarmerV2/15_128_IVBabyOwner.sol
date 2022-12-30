// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './IBabyToken.sol';

interface IVBabyOwner {

    function babyToken() external returns (IBabyToken);

    function repay(uint amount) external returns (uint, uint);

    function borrow() external returns (uint);

}