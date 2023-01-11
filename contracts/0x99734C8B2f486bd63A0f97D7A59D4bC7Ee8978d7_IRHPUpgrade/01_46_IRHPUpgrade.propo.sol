// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../policy/Policy.sol";
import "../../../policy/Policed.sol";
import "./Proposal.sol";
import "../../CurrencyTimer.sol";

/** @title IRHPUpgrade
 * A proposal to update the InflationRootHashProposal implementation
 */
contract IRHPUpgrade is Policy, Proposal {
    /** The address of the updated InflationRootHashProposals contract
     */
    address public immutable newIRHP;

    /** The address of the switcher contract for RandomInflation
     * This contract has setter functions and the right storage layout
     */
    address public immutable switcherRandomInflation;

    // The ID hash for CurrencyTimer
    bytes32 public constant CURRENCY_TIMER_ID = keccak256("CurrencyTimer");

    /** Instantiate a new proposal.
     *
     * @param _newIRHP The address of the updated InflationRootHashProposal contract
     * @param _switcherRandomInflation The address of the switcher contract for RandomInflation
     */
    constructor(address _newIRHP, address _switcherRandomInflation) {
        newIRHP = _newIRHP;
        switcherRandomInflation = _switcherRandomInflation;
    }

    /** The name of the proposal.
     */
    function name() public pure override returns (string memory) {
        return "EGP #005 InflationRootHashProposal Upgrade 2";
    }

    /** A description of what the proposal does.
     */
    function description() public pure override returns (string memory) {
        return
            "This proposal patches an issue with the Inflation Root Hash Proposal";
    }

    /** A URL where more details can be found.
     */
    function url() public pure override returns (string memory) {
        return "https://forums.eco.org/t/egp-005-inflationroothashproposal-upgrade-2/";
    }

    /** This is executed in the storage context of the root policy contract.
     */
    function enacted(address self) public override {
        CurrencyTimer _currencyTimer = CurrencyTimer(
            policyFor(CURRENCY_TIMER_ID)
        );
        address _randomInflation = address(_currencyTimer.inflationImpl());

        Policed(_randomInflation).policyCommand(
            switcherRandomInflation,
            abi.encodeWithSignature("setIRHPImpl(address)", newIRHP)
        );
    }
}