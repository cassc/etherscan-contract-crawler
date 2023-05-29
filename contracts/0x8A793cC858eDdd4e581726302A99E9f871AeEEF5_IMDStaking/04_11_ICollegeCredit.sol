pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICollegeCredit is IERC20 {
    function mint(address recipient, uint256 amount) external;
}