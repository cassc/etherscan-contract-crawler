// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IERC20} from "./Imports.sol";

/**
 * @notice Used for contracts that need an emergency escape hatch
 * @notice Should only be used in an emergency to keep funds safu
 */
interface IEmergencyExit {
    /**
     * @param emergencySafe The address the tokens were escaped to
     * @param token The token escaped
     * @param balance The amount of tokens escaped
     */
    event EmergencyExit(address emergencySafe, IERC20 token, uint256 balance);

    /**
     * @notice Transfer all tokens to the emergency Safe
     * @dev Should only be callable by the emergency Safe
     * @dev Should only transfer tokens to the emergency Safe
     * @param token The token to transfer
     */
    function emergencyExit(address token) external;
}