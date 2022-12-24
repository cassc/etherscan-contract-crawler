// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../policy/Policy.sol";
import "../../../policy/Policed.sol";
import "./Proposal.sol";
import "../../CurrencyTimer.sol";
import "../../Notifier.sol";

/** @title LockupUpgradeAndNotifier
 * A proposal to update the Lockup implementation
 * Also
 */
contract IRHPUpgradeAndNotifierData is Policy, Proposal {
    /** The address of the updated InflationRootHashProposals contract
     */
    address public immutable newIRHP;

    /** The address of the switcher contract for RandomInflation
     * This contract has setter functions and the right storage layout
     */
    address public immutable switcherRandomInflation;

    // The ID hash for CurrencyTimer
    bytes32 public constant CURRENCY_TIMER_ID = keccak256("CurrencyTimer");

    // The new ID hash for the Notifier
    bytes32 public constant NOTIFIER_ID = keccak256("Notifier");

    // The data to be added to the new notifier tx
    bytes public notifierData;

    // The address to be targeted by the new notifier tx data
    address public immutable notifierTarget;

    /** Instantiate a new proposal.
     *
     * @param _newIRHP The address of the updated Lockup contract
     * @param _notifierData The address of the notifier contract
     * @param _switcherRandomInflation The address of the switcher contract for TimedPolicies
     */
    constructor(
        address _newIRHP,
        address _switcherRandomInflation,
        address _notifierTarget,
        bytes memory _notifierData
    ) {
        newIRHP = _newIRHP;
        switcherRandomInflation = _switcherRandomInflation;
        notifierTarget = _notifierTarget;
        notifierData = _notifierData;
    }

    /** The name of the proposal.
     */
    function name() public pure override returns (string memory) {
        return "InflationRootHashProposal Upgrade, Blacklist, and AMM Syncing";
    }

    /** A description of what the proposal does.
     */
    function description() public pure override returns (string memory) {
        return
            "This proposal patches two issues with the InflationRootHashProposal contract, connects the notifier to our live Uni v2 pool, and prevents the pool, Eco inc. and Eco Association from being eligible for rewards.";
    }

    /** A URL where more details can be found.
     */
    function url() public pure override returns (string memory) {
        return "https://forums.eco.org/t/egp-004-inflationroothashproposal-upgrade-blacklist-and-amm-syncing";
    }

    /** Sets the value of the Lockup implementation on the
     * CurrencyTimer contract to the value on this proposal.
     *
     * This is executed in the storage context of the root policy contract.
     */
    function enacted(address self) public override {
        CurrencyTimer _currencyTimer = CurrencyTimer(
            policyFor(CURRENCY_TIMER_ID)
        );
        Notifier _notifier = Notifier(policyFor(NOTIFIER_ID));
        address _randomInflation = address(_currencyTimer.inflationImpl());

        Policed(_randomInflation).policyCommand(
            switcherRandomInflation,
            abi.encodeWithSignature("setIRHPImpl(address)", newIRHP)
        );

        _notifier.addTransaction(
            notifierTarget,
            IRHPUpgradeAndNotifierData(self).notifierData()
        );
    }
}