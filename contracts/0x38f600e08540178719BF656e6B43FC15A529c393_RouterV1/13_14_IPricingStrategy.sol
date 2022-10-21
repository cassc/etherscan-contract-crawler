// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { ITranche } from "../_interfaces/buttonwood/ITranche.sol";

interface IPricingStrategy {
    /// @notice Computes the price of a given tranche token.
    /// @param tranche The tranche to compute price of.
    /// @return The price as a fixed point number with `decimals()`.
    function computeTranchePrice(ITranche tranche) external view returns (uint256);

    /// @notice Computes the price of mature tranches extracted and held as naked collateral.
    /// @param collateralToken The collateral token.
    /// @param collateralBalance The collateral balance of all the mature tranches.
    /// @param debt The total count of mature tranches.
    /// @return The price as a fixed point number with `decimals()`.
    function computeMatureTranchePrice(
        IERC20Upgradeable collateralToken,
        uint256 collateralBalance,
        uint256 debt
    ) external view returns (uint256);

    /// @notice Number of price decimals.
    function decimals() external view returns (uint8);
}