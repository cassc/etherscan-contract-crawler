// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../policy/Policy.sol";
import "../../../policy/Policed.sol";
import "./Proposal.sol";

contract FixGenerationDrift is Policy, Proposal {
    // The ID hash for TimedPolicies
    bytes32 public constant TIMED_POLICIES_ID = keccak256("TimedPolicies");

    // The ID hash for CurrencyTimer
    bytes32 public constant CURRENCY_TIMER_ID = keccak256("CurrencyTimer");

    /** The address of the contract that will update the TimedPolicies implementation
     */
    address public immutable implementationUpdatingTarget;

    /** The address of the switcher contract for CurrencyTimer
     * This contract has setter functions and the right storage layout
     */
    address public immutable switcherCurrencyTimer;

    /** The address of the switcher contract for TimedPolicies
     * This contract has setter functions and the right storage layout
     */
    address public immutable switcherTimedPolicies;

    /** The new TimedPolicies implementation
     */
    address public immutable newTimedPolicies;

    /** The new PolicyProposals implementation
     */
    address public immutable newPolicyProposals;

    /** The new CurrencyGovernance implementation
     */
    address public immutable newCurrencyGovernance;

    /** Instantiate a new proposal.
     *
     * @param _implementationUpdatingTarget The address of the contract that will update the TimedPolicies implementation
     * @param _switcherCurrencyTimer The address of the switcher contract for CurrencyTimer
     * @param _switcherTimedPolicies The address of the switcher contract for TimedPolicies
     * @param _newTimedPolicies The address of the updated TimedPolicies contract
     * @param _newCurrencyGovernance The address of the CurrencyGovernance contract
     * @param _newPolicyProposals The address of the CurrencyGovernance contract
     */
    constructor(
        address _implementationUpdatingTarget,
        address _switcherCurrencyTimer,
        address _switcherTimedPolicies,
        address _newTimedPolicies,
        address _newCurrencyGovernance,
        address _newPolicyProposals
    ) {
        implementationUpdatingTarget = _implementationUpdatingTarget;
        switcherCurrencyTimer = _switcherCurrencyTimer;
        switcherTimedPolicies = _switcherTimedPolicies;
        newTimedPolicies = _newTimedPolicies;
        newCurrencyGovernance = _newCurrencyGovernance;
        newPolicyProposals = _newPolicyProposals;
    }

    /** The name of the proposal.
     */
    function name() public pure override returns (string memory) {
        return "Prevent Generation Drift";
    }

    /** A description of what the proposal does
     */
    function description() public pure override returns (string memory) {
        return
            "Pegging the start and end times of generations to those of the previous generation. This change also affects the start and end times of the first phase of both monetary and community governance.";
    }

    /** The URL where more details can be found.
     */
    function url() public pure override returns (string memory) {
        return
            "https://forums.eco.org/t/egp-009-eliminate-generation-drift/258";
    }

    /** Sets the value of the CurrencyGovernance implementation (bordaImpl) on the
     * CurrencyTimer contract and the values of the PolicyProposal implementation on the
     * TimedPolicies contract to match those on this contract.
     *
     * This is executed in the storage context of the root policy contract.
     */
    function enacted(address) public override {
        Policed _timedPolicies = Policed(policyFor(TIMED_POLICIES_ID));
        Policed _currencyTimer = Policed(policyFor(CURRENCY_TIMER_ID));

        _timedPolicies.policyCommand(
            implementationUpdatingTarget,
            abi.encodeWithSignature(
                "updateImplementation(address)",
                newTimedPolicies
            )
        );

        _timedPolicies.policyCommand(
            switcherTimedPolicies,
            abi.encodeWithSignature(
                "setPolicyProposalsImpl(address)",
                newPolicyProposals
            )
        );

        _currencyTimer.policyCommand(
            switcherCurrencyTimer,
            abi.encodeWithSignature(
                "setBordaImpl(address)",
                newCurrencyGovernance
            )
        );
    }
}