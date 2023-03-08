// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAmmoToken is IERC20 {
    function mint(uint256 amount) external;

    function startDripping(address addr, uint128 multiplier) external;

    function stopDripping(address addr, uint128 multiplier) external;

    function burn(address from, uint256 value) external;
}