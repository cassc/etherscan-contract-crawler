// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBananaToken is IERC20 {
    function mint(uint256 amount) external;

    function startHarvest(address addr, uint256 multiplier) external;

    function stopHarvest(address addr, uint256 multiplier) external;

    function burn(address from, uint256 value) external;
}