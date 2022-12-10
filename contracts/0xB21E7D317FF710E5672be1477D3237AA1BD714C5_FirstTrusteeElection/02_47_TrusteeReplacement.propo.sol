// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../policy/Policy.sol";
import "../../../policy/Policed.sol";
import "./Proposal.sol";
import "../../monetary/TrustedNodes.sol";

/** @title TrusteeReplacement
 * A proposal to replace the current cohort of trustees
 */
contract TrusteeReplacement is Policy, Proposal {
    // the new trustees that will be trusted
    address[] public newTrustees;

    /** Instantiate a new proposal.
     *
     * @param _newTrustees The array of new addresses to become trusted
     */
    constructor(address[] memory _newTrustees) {
        newTrustees = _newTrustees;
    }

    /** The name of the proposal.
     */
    function name() public pure virtual override returns (string memory) {
        return "Trustee Election Proposal Template";
    }

    /** A description of what the proposal does.
     */
    function description()
        public
        pure
        virtual
        override
        returns (string memory)
    {
        return
            "Created with a list of trustees and replaces all current trustees with those trustees";
    }

    /** A URL where more details can be found.
     */
    function url() public pure virtual override returns (string memory) {
        return
            "https://description.of.proposal make this link to a discussion of the new trustee slate";
    }

    function returnNewTrustees() public view returns (address[] memory) {
        return newTrustees;
    }

    /** Enact the proposal.
     *
     * This is executed in the storage context of the root policy contract.
     *
     * @param _self The address of the proposal.
     */
    function enacted(address _self) public virtual override {
        bytes32 _trustedNodesId = keccak256("TrustedNodes");
        TrustedNodes _trustedNodes = TrustedNodes(policyFor(_trustedNodesId));

        address[] memory _newTrustees = TrusteeReplacement(_self)
            .returnNewTrustees();

        _trustedNodes.newCohort(_newTrustees);
    }
}