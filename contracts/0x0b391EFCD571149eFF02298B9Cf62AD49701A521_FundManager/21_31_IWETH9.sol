// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH9 is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}