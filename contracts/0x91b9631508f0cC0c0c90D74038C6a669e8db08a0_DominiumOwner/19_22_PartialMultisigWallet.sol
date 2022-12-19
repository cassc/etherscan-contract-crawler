//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IWallet} from "../../interfaces/IWallet.sol";

import {MutableQuorumGovernanceGroup} from "./MutableQuorumGovernanceGroup.sol";
import {LibEIP712Proposition} from "../../libraries/LibEIP712Proposition.sol";
import {LibEIP712Transaction} from "../../libraries/LibEIP712Transaction.sol";
import {LibTransfer} from "../../libraries/LibTransfer.sol";

/// @title Multi-sig wallet (without value transfer)
/// @author Amit Molek
/// @dev Please see `IWallet` and `MutableQuorumGovernanceGroup`.
/// Gives the ability to execute valueless transaction
contract PartialMultisigWallet is IWallet, MutableQuorumGovernanceGroup {
    /* FIELDS */

    /// @dev Maps between proposition hash and if it was already enacted
    mapping(bytes32 => bool) private _enactedPropositions;

    /* ERRORS */

    /// @dev Already enacted this proposition
    /// @param propositionHash The hash of the proposition
    error PropositionEnacted(bytes32 propositionHash);

    /// @dev The proposition ended/deadline passed
    /// @param propositionHash The hash of the proposition
    /// @param endedAt The proposition's deadline
    error PropositionEnded(bytes32 propositionHash, uint256 endedAt);

    /// @dev You can't transfer value using this wallet
    error ValueTransferUnsupported();

    constructor(address[] memory owners) MutableQuorumGovernanceGroup(owners) {}

    function enactProposition(
        Proposition memory proposition,
        bytes[] memory signatures
    ) external override returns (bool successful, bytes memory returnData) {
        // This wallet doesn't support transfer of value
        if (proposition.tx.value > 0) {
            revert ValueTransferUnsupported();
        }

        bytes32 propositionHash = toTypedDataHash(proposition);

        // A proposition can only be enacted once
        if (_enactedPropositions[propositionHash]) {
            revert PropositionEnacted(propositionHash);
        }

        // Make sure that the proposition is still alive
        uint256 endsAt = proposition.endsAt;
        // solhint-disable-next-line not-rely-on-time
        if (endsAt < block.timestamp) {
            revert PropositionEnded(propositionHash, endsAt);
        }

        // Verify that the proposition is agreed upon
        _verifyHashGuard(propositionHash, signatures);

        // Tag the proposition as enacted
        _enactedPropositions[propositionHash] = true;

        IWallet.Transaction memory transaction = proposition.tx;

        (successful, returnData) = LibTransfer._untrustedCall(
            transaction.to,
            0,
            transaction.data
        );

        emit ExecutedTransaction(toTypedDataHash(transaction), 0, successful);
    }

    function isPropositionEnacted(bytes32 propositionHash)
        external
        view
        override
        returns (bool)
    {
        return _enactedPropositions[propositionHash];
    }

    function maxAllowedTransfer() external pure override returns (uint256) {
        // This wallet doesn't allow to transfer or receive value
        return 0;
    }

    function toTypedDataHash(IWallet.Proposition memory proposition)
        public
        view
        returns (bytes32)
    {
        return LibEIP712Proposition._toTypedDataHash(proposition);
    }

    function toTypedDataHash(IWallet.Transaction memory transaction)
        public
        view
        returns (bytes32)
    {
        return LibEIP712Transaction._toTypedDataHash(transaction);
    }

    /* ERC165 */

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IWallet).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}