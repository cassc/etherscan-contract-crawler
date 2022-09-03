// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IBooty is IERC20Upgradeable {
    function burnFrom(address account, uint256 amount) external;

    function mint(address to, uint256 amount) external;
}