//SPDX-License-Identifier: BUSL-1.1

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity 0.8.9;

/// @title Interface for swETH
interface ISWETH is IERC20 {
    function mint(uint256 amount) external;

    function burn(uint256 amount) external;
}