// contracts/ICheeth.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface ICheeth is IERC20 {
    function burnFrom(address account, uint256 amount) external;
}