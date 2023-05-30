// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IForex is IERC20 {
    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}