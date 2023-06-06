// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICHI is IERC20 {
    function freeUpTo(uint256 value) external returns (uint256);

    function freeFromUpTo(
        address from,
        uint256 value
    ) external returns (uint256);

    function mint(uint256 value) external;
}