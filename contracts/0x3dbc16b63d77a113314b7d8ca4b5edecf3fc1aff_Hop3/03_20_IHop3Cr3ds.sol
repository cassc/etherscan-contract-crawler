// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IHop3Cr3ds is IERC20 {
    function startDripping(address addr, uint128 multiplier) external;

    function stopDripping(address addr, uint128 multiplier) external;

    function burn(address from, uint256 value) external;
}