// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";

// Although decimals is not part of the ERC20 standard, but practically all
// tokens implement it. IERC20UpgradeableExt is only intended to be used to get
// the decimal count of the deposit token.
interface IERC20UpgradeableExt is IERC20Upgradeable {
    function decimals() external view returns (uint8);
}