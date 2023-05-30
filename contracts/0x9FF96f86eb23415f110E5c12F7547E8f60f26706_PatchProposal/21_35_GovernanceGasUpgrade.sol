// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import { GovernanceVaultUpgrade } from "./GovernanceVaultUpgrade.sol";
import { GasCompensator } from "./GasCompensator.sol";
import { Math } from "@openzeppelin/contracts/math/Math.sol";

/**
 * @notice This contract should upgrade governance to be able to compensate gas for certain actions.
 *         These actions are set to castVote, castDelegatedVote in this contract.
 *
 */
contract GovernanceGasUpgrade is GovernanceVaultUpgrade, GasCompensator {
    /**
     * @notice constructor
     * @param _gasCompLogic gas compensation vault address
     * @param _userVault tornado vault address
     *
     */
    constructor(address _gasCompLogic, address _userVault)
        public
        GovernanceVaultUpgrade(_userVault)
        GasCompensator(_gasCompLogic)
    { }

    /// @notice check that msg.sender is multisig
    modifier onlyMultisig() {
        require(msg.sender == returnMultisigAddress(), "only multisig");
        _;
    }

    /**
     * @notice receive ether function, does nothing but receive ether
     *
     */
    receive() external payable { }

    /**
     * @notice function to add a certain amount of ether for gas compensations
     * @dev send ether is used in the logic as we don't expect multisig to make a reentrancy attack on governance
     * @param gasCompensationsLimit the amount of gas to be compensated
     *
     */
    function setGasCompensations(uint256 gasCompensationsLimit) external virtual override onlyMultisig {
        require(
            payable(address(gasCompensationVault)).send(
                Math.min(gasCompensationsLimit, address(this).balance)
            )
        );
    }

    /**
     * @notice function to withdraw funds from the gas compensator
     * @dev send ether is used in the logic as we don't expect multisig to make a reentrancy attack on governance
     * @param amount the amount of ether to withdraw
     *
     */
    function withdrawFromHelper(uint256 amount) external virtual override onlyMultisig {
        gasCompensationVault.withdrawToGovernance(amount);
    }

    /**
     * @notice function to cast callers votes on a proposal
     * @dev IMPORTANT: This function uses the gasCompensation modifier.
     *                 as such this function can trigger a payable fallback.
     *                 It is not possible to vote without revert more than once,
     *   without hasAccountVoted being true, eliminating gas refunds in this case.
     *   Gas compensation is also using the low level send(), forwarding 23000 gas
     *   as to disallow further logic execution above that threshold.
     * @param proposalId id of proposal account is voting on
     * @param support true if yes false if no
     *
     */
    function castVote(uint256 proposalId, bool support)
        external
        virtual
        override
        gasCompensation(
            msg.sender,
            !hasAccountVoted(proposalId, msg.sender) && !checkIfQuorumReached(proposalId),
            (msg.sender == tx.origin ? 21e3 : 0)
        )
    {
        _castVote(msg.sender, proposalId, support);
    }

    /**
     * @notice function to cast callers votes and votes delegated to the caller
     * @param from array of addresses that should have delegated to voter
     * @param proposalId id of proposal account is voting on
     * @param support true if yes false if no
     *
     */
    function castDelegatedVote(address[] memory from, uint256 proposalId, bool support)
        external
        virtual
        override
    {
        require(from.length > 0, "Can not be empty");
        _castDelegatedVote(
            from,
            proposalId,
            support,
            !hasAccountVoted(proposalId, msg.sender) && !checkIfQuorumReached(proposalId)
        );
    }

    /// @notice checker for success on deployment
    /// @return returns precise version of governance
    function version() external pure virtual override returns (string memory) {
        return "2.lottery-and-gas-upgrade";
    }

    /**
     * @notice function to check if quorum has been reached on a given proposal
     * @param proposalId id of proposal
     * @return true if quorum has been reached
     *
     */
    function checkIfQuorumReached(uint256 proposalId) public view returns (bool) {
        return (proposals[proposalId].forVotes + proposals[proposalId].againstVotes >= QUORUM_VOTES);
    }

    /**
     * @notice function to check if account has voted on a proposal
     * @param proposalId id of proposal account should have voted on
     * @param account address of the account
     * @return true if acc has voted
     *
     */
    function hasAccountVoted(uint256 proposalId, address account) public view returns (bool) {
        return proposals[proposalId].receipts[account].hasVoted;
    }

    /**
     * @notice function to retrieve the multisig address
     * @dev reasoning: if multisig changes we need governance to approve the next multisig address,
     *                 so simply inherit in a governance upgrade from this function and set the new address
     * @return the multisig address
     *
     */
    function returnMultisigAddress() public pure virtual returns (address) {
        return 0xb04E030140b30C27bcdfaafFFA98C57d80eDa7B4;
    }

    /**
     * @notice This should handle the logic of the external function
     * @dev IMPORTANT: This function uses the gasCompensation modifier.
     *                 as such this function can trigger a payable fallback.
     *                 It is not possible to vote without revert more than once,
     *        	     without hasAccountVoted being true, eliminating gas refunds in this case.
     *      	     Gas compensation is also using the low level send(), forwarding 23000 gas
     *   		     as to disallow further logic execution above that threshold.
     * @param from array of addresses that should have delegated to voter
     * @param proposalId id of proposal account is voting on
     * @param support true if yes false if no
     * @param gasCompensated true if gas should be compensated (given all internal checks pass)
     *
     */
    function _castDelegatedVote(address[] memory from, uint256 proposalId, bool support, bool gasCompensated)
        internal
        gasCompensation(msg.sender, gasCompensated, (msg.sender == tx.origin ? 21e3 : 0))
    {
        for (uint256 i = 0; i < from.length; i++) {
            address delegator = from[i];
            require(
                delegatedTo[delegator] == msg.sender || delegator == msg.sender, "Governance: not authorized"
            );
            require(!gasCompensated || !hasAccountVoted(proposalId, delegator), "Governance: voted already");
            _castVote(delegator, proposalId, support);
        }
    }
}