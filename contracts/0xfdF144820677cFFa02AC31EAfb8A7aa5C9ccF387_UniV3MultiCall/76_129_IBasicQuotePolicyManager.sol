// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {DataTypesBasicPolicies} from "../../policyManagers/DataTypesBasicPolicies.sol";
import {IQuotePolicyManager} from "./IQuotePolicyManager.sol";

interface IBasicQuotePolicyManager is IQuotePolicyManager {
    /**
     * @notice Retrieve the global quoting policy for a specific lender's vault
     * @param lenderVault The address of the lender's vault
     * @return The global quoting policy for the specified lender's vault
     */
    function globalQuotingPolicy(
        address lenderVault
    ) external view returns (DataTypesBasicPolicies.GlobalPolicy memory);

    /**
     * @notice Retrieve the quoting policy for a specific lending pair involving collateral and loan tokens
     * @param lenderVault The address of the lender's vault
     * @param collToken The address of the collateral token
     * @param loanToken The address of the loan token
     * @return The quoting policy for the specified lender's vault, collateral, and loan tokens
     */
    function pairQuotingPolicy(
        address lenderVault,
        address collToken,
        address loanToken
    ) external view returns (DataTypesBasicPolicies.PairPolicy memory);

    /**
     * @notice Check if there is a global quoting policy for a specific lender's vault
     * @param lenderVault The address of the lender's vault
     * @return True if there is a global quoting policy, false otherwise
     */
    function hasGlobalQuotingPolicy(
        address lenderVault
    ) external view returns (bool);

    /**
     * @notice Check if there is a quoting policy for a specific lending pair involving collateral and loan tokens
     * @param lenderVault The address of the lender's vault
     * @param collToken The address of the collateral token
     * @param loanToken The address of the loan token
     * @return True if there is a quoting policy for the specified lender's vault, collateral, and loan tokens, false otherwise
     */
    function hasPairQuotingPolicy(
        address lenderVault,
        address collToken,
        address loanToken
    ) external view returns (bool);
}