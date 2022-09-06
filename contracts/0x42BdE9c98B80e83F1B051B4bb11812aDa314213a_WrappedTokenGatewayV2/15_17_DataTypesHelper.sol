// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IERC20} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";
import {DataTypesV2} from "./DataTypesV2.sol";

/**
 * @title Helpers library
 * @author Aave
 */
library DataTypesHelper {
    /**
     * @dev Fetches the user current stable and variable debt balances
     * @param user The user address
     * @param reserve The reserve data object
     * @return The stable and variable debt balance
     **/
    function getUserCurrentDebt(
        address user,
        DataTypesV2.ReserveData storage reserve
    ) internal view returns (uint256, uint256) {
        return (
            IERC20(reserve.stableDebtTokenAddress).balanceOf(user),
            IERC20(reserve.variableDebtTokenAddress).balanceOf(user)
        );
    }

    function getUserCurrentDebtMemory(
        address user,
        DataTypesV2.ReserveData memory reserve
    ) internal view returns (uint256, uint256) {
        return (
            IERC20(reserve.stableDebtTokenAddress).balanceOf(user),
            IERC20(reserve.variableDebtTokenAddress).balanceOf(user)
        );
    }
}