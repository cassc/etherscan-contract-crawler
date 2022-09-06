// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IROOLAH is IERC20Upgradeable {
    function mint(address recipient, uint256 amount) external;
    function burn(uint256 amount) external;
}