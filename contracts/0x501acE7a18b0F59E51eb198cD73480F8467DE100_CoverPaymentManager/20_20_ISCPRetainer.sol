// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title Solace Cover Points Retainer
 * @author solace.fi
 * @notice An interface for contracts that require users to maintain a minimum balance of SCP.
 */
interface ISCPRetainer {

    /**
     * @notice Calculates the minimum amount of Solace Cover Points required by this contract for the account to hold.
     * @param account Account to query.
     * @return amount The amount of SCP the account must hold.
     */
    function minScpRequired(address account) external view returns (uint256 amount);
}