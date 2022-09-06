//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/governance/IGovernorUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @dev Extension of {Governor} that binds the execution process to an instance of {TimelockController}. This adds a
/// delay, enforced by the {TimelockController} to all successful proposal (in addition to the voting duration). The
/// {Governor} needs to be authorized within the Access Control Contract in order to execute transactions on the TimelockController.
/// Using this model means the proposal will be operated by the MVD.
abstract contract IGovTimelockUpgradeable is
    Initializable,
    IGovernorUpgradeable
{
    event ProposalQueued(uint256 proposalId, uint256 eta);
    /// @dev Public accessor to check the address of the timelock
    function timelock() public view virtual returns (address);

    /// @dev Public accessor to check the eta of a queued proposal
    /// @param proposalId keccak256 hash of proposal params
    function proposalEta(uint256 proposalId)
        public
        view
        virtual
        returns (uint256);

    /// @dev Function to queue a proposal to the timelock.
    /// @param targets Contract addresses the DAO will call
    /// @param values Ether values to be sent to the target address
    /// @param calldatas Function Sigs w/ Params 
    /// @param descriptionHash Description of proposal
    function queue(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public virtual returns (uint256 proposalId);

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}