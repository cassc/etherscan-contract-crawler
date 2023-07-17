// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../policy/Policy.sol";
import "../../../policy/Policed.sol";
import "./Proposal.sol";
import "../../Notifier.sol";

/** @title LockupUpgradeAndNotifier
 * A proposal to update the Lockup implementation
 * Also
 */
contract AddTxToNotifier is Policy, Proposal {
    // The address of the L1ECOBridge
    address public immutable l1EcoBridge;

    // The data for performing a call to the rebase method on L1ECOBridge
    bytes public constant txData =
        abi.encodeWithSignature("rebase(uint32)", 0);

    // The new ID hash for the Notifier
    bytes32 public constant NOTIFIER_ID = keccak256("Notifier");

    /** Instantiate a new proposal.
     *
     * @param _l1ECOBridge The address of the l1EcoBridge contract
     */
    constructor(address _l1ECOBridge) {
        l1EcoBridge = _l1ECOBridge;
    }

    /** The name of the proposal.
     */
    function name() public pure override returns (string memory) {
        return "EGP #009 sync inflation multipliers on generation increment";
    }

    /** A description of what the proposal does.
     */
    function description() public pure override returns (string memory) {
        return
            "This proposal adds to the notifier a transaction that syncs the L2 inflation multiplier to the L1 one";
    }

    /** A URL where more details can be found.
     */
    function url() public pure override returns (string memory) {
        return
            "https://forums.eco.org/t/egp-009-sync-inflation-multipliers-on-generation-increment/264/1";
    }

    /** Adds new tx to notifier */
    function enacted(address) public override {
        address notifier = policyFor(NOTIFIER_ID);

        Notifier(notifier).addTransaction(l1EcoBridge, txData);
    }
}