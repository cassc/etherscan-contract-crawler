// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
import "../common/Storage.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IBetting {
    function transferCommissionToVault(uint256 amount_) external;
    function transferPayoutToVault(uint256 amount_) external;
}