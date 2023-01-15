// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface iWTF is IERC20 {
    function burnFrom(address account, uint256 amount) external;
}