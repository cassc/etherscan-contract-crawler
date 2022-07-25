// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDetailedERC20 is IERC20 {
    function name() external returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external returns (uint8);
}