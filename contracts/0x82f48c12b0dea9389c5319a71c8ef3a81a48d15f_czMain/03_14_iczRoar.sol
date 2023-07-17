// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface iczRoar is IERC20 {
    function MAX_TOKENS() external returns (uint256);
    function tokensMinted() external returns (uint256);
    function tokensBurned() external returns (uint256);
    function canBeSold() external returns (bool);

    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}