// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IRNM is IERC20 {
    function SUPPLY_CAP() external view returns (uint256);

    function mint(address account, uint256 amount) external returns (bool);
    function burn(uint256 amount) external;
}