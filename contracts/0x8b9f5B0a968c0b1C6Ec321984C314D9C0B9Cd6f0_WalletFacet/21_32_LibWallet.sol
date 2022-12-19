//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IWallet} from "../interfaces/IWallet.sol";
import {LibQuorumGovernance} from "../libraries/LibQuorumGovernance.sol";
import {LibEIP712Transaction} from "../libraries/LibEIP712Transaction.sol";
import {LibEIP712} from "../libraries/LibEIP712.sol";
import {StorageEnactedPropositions} from "../storage/StorageEnactedPropositions.sol";
import {LibEIP712Proposition} from "../libraries/LibEIP712Proposition.sol";
import {LibState} from "../libraries/LibState.sol";
import {StateEnum} from "../structs/StateEnum.sol";
import {LibTransfer} from "../libraries/LibTransfer.sol";
import {LibWalletHash} from "./LibWalletHash.sol";
import {LibDeploymentRefund} from "./LibDeploymentRefund.sol";
import {LibReceive} from "./LibReceive.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/// @author Amit Molek
/// @dev Please see `IWallet` for docs
library LibWallet {
    event ExecutedTransaction(
        bytes32 indexed hash,
        uint256 value,
        bool successful
    );

    function _maxAllowedTransfer() internal view returns (uint256) {
        return
            address(this).balance -
            LibDeploymentRefund._refundable() -
            LibReceive._totalWithdrawable();
    }

    /// @dev Reverts if the transaction's value exceeds the maximum allowed value
    /// max allowed = (balance - deployer's refund - total withdrawable value by members)
    /// revert message example: "Wallet: 42 exceeds maximum value of 6"
    function _maxAllowedTransferGuard(uint256 value) internal view {
        uint256 maxValueAllowed = _maxAllowedTransfer();
        require(
            value <= maxValueAllowed,
            string(
                abi.encodePacked(
                    "Wallet: ",
                    Strings.toString(value),
                    " exceeds maximum value of ",
                    Strings.toString(maxValueAllowed)
                )
            )
        );
    }

    /// @dev Emits `ExecutedTransaction` event
    /// @param transaction the transaction to execute
    function _untrustedExecuteTransaction(
        IWallet.Transaction memory transaction
    ) internal returns (bool successful, bytes memory returnData) {
        // Verify that the transaction's value doesn't exceeds
        // the maximum allowed value.
        // The deployer's refund and each member's withdrawable value
        _maxAllowedTransferGuard(transaction.value);

        (successful, returnData) = LibTransfer._untrustedCall(
            transaction.to,
            transaction.value,
            transaction.data
        );

        emit ExecutedTransaction(
            LibEIP712Transaction._hashTransaction(transaction),
            transaction.value,
            successful
        );
    }

    /// @dev Can revert:
    ///     - "Wallet: Enacted proposition given": If the proposition was already enacted
    ///     - "Wallet: Proposition ended": If the proposition's time-to-live ended
    ///     - "Wallet: Unapproved proposition": If group members did not reach on agreement on `proposition`
    ///     - "Wallet: Group not formed": If the group state is not valid
    /// Emits `ApprovedHash` and `ExecutedTransaction` events
    function _untrustedEnactProposition(
        IWallet.Proposition memory proposition,
        bytes[] memory signatures
    ) internal returns (bool successful, bytes memory returnData) {
        LibState._stateGuard(StateEnum.FORMED);

        bytes32 propositionHash = LibEIP712Proposition._toTypedDataHash(
            proposition
        );

        StorageEnactedPropositions.DiamondStorage
            storage enactedPropositionsStorage = StorageEnactedPropositions
                .diamondStorage();

        // A proposition can only be executed once
        require(
            !enactedPropositionsStorage.enactedPropositions[propositionHash],
            "Wallet: Enacted proposition given"
        );

        require(
            // solhint-disable-next-line not-rely-on-time
            proposition.endsAt >= block.timestamp,
            "Wallet: Proposition ended"
        );

        // Verify that the proposition is agreed upon
        bool isPropositionVerified = LibQuorumGovernance._verifyHash(
            propositionHash,
            signatures
        );
        require(isPropositionVerified, "Wallet: Unapproved proposition");

        // Tag the proposition as enacted
        enactedPropositionsStorage.enactedPropositions[propositionHash] = true;

        if (proposition.relevantHash != bytes32(0)) {
            // Store the approved hash for later (probably for EIP1271)
            LibWalletHash._internalApproveHash(proposition.relevantHash);
        }

        return _untrustedExecuteTransaction(proposition.tx);
    }

    function _isPropositionEnacted(bytes32 propositionHash)
        internal
        view
        returns (bool)
    {
        StorageEnactedPropositions.DiamondStorage
            storage ds = StorageEnactedPropositions.diamondStorage();

        return ds.enactedPropositions[propositionHash];
    }
}