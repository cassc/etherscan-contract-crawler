// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./interfaces/IGovernanceRegistry.sol";
import "./interfaces/IGovernance.sol";

/**
 * @title Kapital DAO Governance Registry
 * @author Playground Labs
 * @custom:security-contact [email protected]
 * @notice Holds the latest address of the Kapital DAO governance contract.
 * Changing {governance} is a method of updating the Kapital DAO governance
 * structure if needed.
 */
contract GovernanceRegistry is IGovernanceRegistry {
    address public governance; // address of latest governance contract
    address public appointedGovernance; // address of newly appointed governance contract

    /// @param initialGovernance Address of governance contract at deployment
    constructor(address initialGovernance) {
        require(initialGovernance != address(0), "Registry: Zero address");
        governance = initialGovernance;
    }

    /**
     * @dev Called by the latest governance contract to update to a new address
     * if needed.
     * @dev This will only take effect after {newGovernance} executes {confirmChanged}
     * to verify that the valid address was appointed as a {newGovernance}.
     * @dev New governance contract should implement {votingPeriod}, being used by {Vesting} and {Staking}.
     * @param newGovernance Address of the new governance contract
     */
    function changeGovernance(address newGovernance) external {
        require(msg.sender == governance, "Registry: Only governance");
        require(
            newGovernance != address(0) && newGovernance != governance,
            "Registry: Invalid new governance"
        );

        IGovernance _newGovernance = IGovernance(newGovernance);
        require(_newGovernance.votingPeriod() > 0, "Registry: Invalid voting period");

        appointedGovernance = newGovernance;
    }

    /**
     * @dev Called by the new governance contract to verify the account ownership.
     * This will finally update the governance contract address.
     */
    function confirmChanged() external {
        require(appointedGovernance != address(0), "Registry: Invalid appointed");
        require(appointedGovernance == msg.sender, "Registry: Only appointed");

        governance = appointedGovernance;
        appointedGovernance = address(0);
    }
}