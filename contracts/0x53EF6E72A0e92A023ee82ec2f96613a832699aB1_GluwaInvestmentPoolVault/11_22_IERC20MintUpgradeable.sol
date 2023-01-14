// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';

interface IERC20MintUpgradeable is IERC20Upgradeable {
    function mint(address to, uint256 amount) external returns (bool);
}