// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "../../interfaces/tokens/erc20permit-upgradeable/IERC20PermitUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IVBMI is IERC20Upgradeable, IERC20PermitUpgradeable {
    function slashUserTokens(address user, uint256 amount) external;
}