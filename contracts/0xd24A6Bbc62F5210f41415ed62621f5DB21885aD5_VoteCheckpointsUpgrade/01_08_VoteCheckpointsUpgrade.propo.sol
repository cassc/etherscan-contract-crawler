// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../policy/Policy.sol";
import "../../policy/Policed.sol";
import "./Proposal.sol";

/** @title VoteCheckpointsUpgrade
 *
 * A proposal to upgrade the ECO and ECOxStaking contract.
 */
contract VoteCheckpointsUpgrade is Policy, Proposal {
    /** The address of the contract to denote as ECOxStaking.
     */
    address public immutable newStaking;

    /** The address of the updated ECO implementation contract
     */
    address public immutable newECOImpl;

    /** The address of the updating contract
     */
    address public immutable implementationUpdatingTarget;

    // The ID hash for the ECO contract
    bytes32 public constant ECOIdentifier = keccak256("ECO");

    // The ID hash for the ECOxStaking contract
    bytes32 public constant ECOxStakingIdentifier = keccak256("ECOxStaking");

    // The ID hash for the PolicyVotes contract
    // this is used for cluing in the use of setPolicy
    bytes32 public constant PolicyVotesIdentifier = keccak256("PolicyVotes");

    /** Instantiate a new proposal.
     *
     * @param _newStaking The address of the contract to mark as ECOxStaking.
     */
    constructor(
        address _newStaking,
        address _newECOImpl,
        address _implementationUpdatingTarget
    ) {
        newStaking = _newStaking;
        newECOImpl = _newECOImpl;
        implementationUpdatingTarget = _implementationUpdatingTarget;
    }

    /** The name of the proposal.
     */
    function name() public pure override returns (string memory) {
        return "Update to VoteCheckpoints";
    }

    /** A short description of the proposal.
     */
    function description() public pure override returns (string memory) {
        return
            "Updating ECOxStaking and ECO contracts to patch the voting snapshot and delegation during self-transfers";
    }

    /** A URL where further details can be found.
     */
    function url() public pure override returns (string memory) {
        return "none";
    }

    /** Enact the proposal.
     *
     * This is run in the storage context of the root policy contract.
     */
    function enacted(address) public override {
        // because ECOxStaking isn't proxied yet, we have to move over the identifier
        setPolicy(ECOxStakingIdentifier, newStaking, PolicyVotesIdentifier);

        address _ecoProxyAddr = policyFor(ECOIdentifier);

        Policed(_ecoProxyAddr).policyCommand(
            implementationUpdatingTarget,
            abi.encodeWithSignature("updateImplementation(address)", newECOImpl)
        );
    }
}