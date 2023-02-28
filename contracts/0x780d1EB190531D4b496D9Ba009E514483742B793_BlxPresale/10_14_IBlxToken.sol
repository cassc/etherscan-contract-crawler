// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBlxToken is IERC20 {
//    function update_blxusd(uint256 _blxusd) external returns (uint256);
//
//    function get_blxusd() external view returns (uint256);
    function burn(uint256 amount) external;
//    function burnFor(address holder, uint256 amount) external;
}