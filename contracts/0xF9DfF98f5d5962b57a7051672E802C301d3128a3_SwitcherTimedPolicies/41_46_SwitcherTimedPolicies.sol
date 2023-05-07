// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../policy/Policy.sol";
import "../governance/community/PolicyProposals.sol";
import "../governance/TimedPolicies.sol";

/** @title SwitcherTimedPolicies
 * Delegate call function data contract for setter functions
 */
contract SwitcherTimedPolicies is TimedPolicies {
    address public constant TEST_FILL_ADDRESS =
        0xDEADBEeFbAdf00dC0fFee1Ceb00dAFACEB00cEc0;

    bytes32 public constant TEST_FILL_BYTES =
        0x9f24c52e0fcd1ac696d00405c3bd5adc558c48936919ac5ab3718fcb7d70f93f;

    bytes32[] private fill;

    // this is for setting up the storage context
    // the values are unused but must validate the super constructor
    constructor()
        TimedPolicies(
            Policy(TEST_FILL_ADDRESS),
            PolicyProposals(TEST_FILL_ADDRESS),
            getFill()
        )
    {}

    function getFill() private returns (bytes32[] memory) {
        fill.push(TEST_FILL_BYTES);
        return fill;
    }

    /** Function for adding a notifier hash
     *
     * This is executed in the storage context of the TimedPolicies contract by the proposal.
     *
     * @param _newNotificationHash The identifier of the new contract to notify on generation increase
     */
    function addNotificationHash(bytes32 _newNotificationHash) public {
        notificationHashes.push(_newNotificationHash);
    }

    /** Function for switching out the PolicyProposals implementation that is cloned every generation
        
        This is executed in the storage context of the TimedPolicies contract by the proposal. 

        @param _newPolicyProposalsImpl The new PolicyProposals implementation

      */
    function setPolicyProposalsImpl(address _newPolicyProposalsImpl) public {
        policyProposalImpl = PolicyProposals(_newPolicyProposalsImpl);
    }
}