// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IDiscountStrategy {
    /// @notice Computes the discount to be applied to a given tranche token.
    /// @param tranche The tranche token to compute discount for.
    /// @return The discount as a fixed point number with `decimals()`.
    function computeTrancheDiscount(IERC20Upgradeable tranche) external view returns (uint256);

    /// @notice Number of discount decimals.
    function decimals() external view returns (uint8);
}