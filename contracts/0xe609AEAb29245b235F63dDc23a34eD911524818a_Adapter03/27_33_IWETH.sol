// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract IWETH is IERC20 {
    function deposit() external payable virtual;

    function withdraw(uint256 amount) external virtual;
}