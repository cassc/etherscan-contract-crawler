//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {StateEnum} from "../structs/StateEnum.sol";
import {LibState} from "../libraries/LibState.sol";
import {LibOwnership} from "../libraries/LibOwnership.sol";
import {LibTransfer} from "../libraries/LibTransfer.sol";
import {LibWallet} from "../libraries/LibWallet.sol";
import {IWallet} from "../interfaces/IWallet.sol";
import {JoinData} from "../structs/JoinData.sol";
import {LibAnticFee} from "../libraries/LibAnticFee.sol";
import {LibDeploymentRefund} from "../libraries/LibDeploymentRefund.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {StorageFormingProposition} from "../storage/StorageFormingProposition.sol";
import {LibEIP712Proposition} from "./LibEIP712Proposition.sol";

/// @author Amit Molek
/// @dev Please see `IGroup` for docs
library LibGroup {
    event Joined(address account, uint256 ownershipUnits);
    event AcquiredMore(address account, uint256 ownershipUnits);
    event Left(address account);

    function _calculateExpectedValue(uint256 ownershipUnits)
        internal
        view
        returns (uint256 anticFee, uint256 deploymentRefund)
    {
        require(
            LibDeploymentRefund._isDeploymentCostSet(),
            "Group: Deployment cost must be initialized"
        );

        anticFee = LibAnticFee._calculateAnticJoinFee(ownershipUnits);

        // If the deployer has not joined yet, he/she MUST be the next one to join,
        // and he/she doesn't need to pay the deployment cost refund.
        // Otherwise the next one to join, MUST pay the deployment refund
        deploymentRefund = !LibDeploymentRefund._isDeployerJoined()
            ? deploymentRefund = 0
            : LibDeploymentRefund._calculateDeploymentCostRefund(
                ownershipUnits
            );
    }

    function _internalJoin(
        address member,
        uint256 ownershipUnits,
        uint256 anticFee,
        uint256 deploymentRefund,
        bool newOwner
    ) internal {
        uint256 expectedTotal = anticFee + deploymentRefund + ownershipUnits;
        uint256 value = msg.value;

        // Verify that the caller passed enough value
        require(
            value == expectedTotal,
            string(
                abi.encodePacked(
                    "Group: Expected ",
                    Strings.toString(expectedTotal),
                    " but received ",
                    Strings.toString(value)
                )
            )
        );

        // Transfer fee to antic
        LibAnticFee._depositJoinFeePayment(member, anticFee);

        // Pay deployment cost
        LibDeploymentRefund._payDeploymentCost(deploymentRefund);

        if (newOwner) {
            // Add the member as a owner
            LibOwnership._addOwner(member, ownershipUnits);
        } else {
            // Update member's ownership
            LibOwnership._acquireMoreOwnershipUnits(member, ownershipUnits);
        }
    }

    /// @dev Decodes `data` and passes it to `_join`
    /// `data` must be encoded `JoinData` struct
    function _untrustedJoinDecode(bytes memory data) internal {
        JoinData memory joinData = abi.decode(data, (JoinData));

        _untrustedJoin(
            joinData.member,
            joinData.proposition,
            joinData.signatures,
            joinData.ownershipUnits
        );
    }

    /// @notice Internal join
    /// @dev Adds `member` to the group
    /// If the `member` fulfills the targeted ownership units -> enacts `proposition`
    /// Emits `Joined` event
    function _untrustedJoin(
        address member,
        IWallet.Proposition memory proposition,
        bytes[] memory signatures,
        uint256 ownershipUnits
    ) internal {
        // Members can join only when the group is forming (open)
        LibState._stateGuard(StateEnum.OPEN);

        (uint256 anticFee, uint256 deploymentRefund) = _calculateExpectedValue(
            ownershipUnits
        );

        if (!LibDeploymentRefund._isDeployerJoined()) {
            LibDeploymentRefund._deployerJoin(member, ownershipUnits);
        }

        _internalJoin(member, ownershipUnits, anticFee, deploymentRefund, true);

        emit Joined(member, ownershipUnits);

        _untrustedTryEnactFormingProposition(proposition, signatures);
    }

    /// @dev Decodes `data` and passes it to `_acquireMore`
    /// `data` must be encoded `JoinData` struct
    function _untrustedAcquireMoreDecode(bytes memory data) internal {
        JoinData memory joinData = abi.decode(data, (JoinData));

        _untrustedAcquireMore(
            joinData.member,
            joinData.proposition,
            joinData.signatures,
            joinData.ownershipUnits
        );
    }

    /// @notice Internal acquire more
    /// @dev `member` obtains more ownership units
    /// `member` must be an actual group member
    /// if the `member` fulfills the targeted ownership units -> enacts `proposition`
    /// Emits `AcquiredMore` event
    function _untrustedAcquireMore(
        address member,
        IWallet.Proposition memory proposition,
        bytes[] memory signatures,
        uint256 ownershipUnits
    ) internal {
        // Members can acquire more ownership units only when the group is forming (open)
        LibState._stateGuard(StateEnum.OPEN);

        (uint256 anticFee, uint256 deploymentRefund) = _calculateExpectedValue(
            ownershipUnits
        );

        _internalJoin(
            member,
            ownershipUnits,
            anticFee,
            deploymentRefund,
            false
        );

        emit AcquiredMore(member, ownershipUnits);

        _untrustedTryEnactFormingProposition(proposition, signatures);
    }

    /// @notice Enacts the group forming proposition
    /// @dev Enacts the given `proposition` if the group completely owns all the ownership units
    function _untrustedTryEnactFormingProposition(
        IWallet.Proposition memory proposition,
        bytes[] memory signatures
    ) internal {
        // Enacting the forming proposition is only available while the group is open
        // because this is the last step to form the group
        LibState._stateGuard(StateEnum.OPEN);

        // Last member to acquire the remaining ownership units, enacts the proposition
        // and forms the group
        if (LibOwnership._isCompletelyOwned()) {
            // Verify that we are going to enact the expected forming proposition
            require(
                _isValidFormingProposition(proposition),
                "Group: Unexpected proposition"
            );

            // The group is now formed
            LibState._changeState(StateEnum.FORMED);

            // Transfer Antic fee
            LibAnticFee._untrustedTransferJoinAnticFee();

            (bool successful, bytes memory returnData) = LibWallet
                ._untrustedEnactProposition(proposition, signatures);

            if (!successful) {
                LibTransfer._revertWithReason(returnData);
            }
        }
    }

    /// @notice Internal member leaves
    /// @dev `member` will be refunded with his join deposit and Antic fee
    /// Emits `Left` event
    function _leave() internal {
        // Members can leave only while the group is forming (open)
        LibState._stateGuard(StateEnum.OPEN);

        address member = msg.sender;

        // Caller renounce his ownership
        uint256 ownershipRefundAmount = LibOwnership._renounceOwnership();
        uint256 anticFeeRefundAmount = LibAnticFee._refundFeePayment(member);
        uint256 refundAmount = ownershipRefundAmount + anticFeeRefundAmount;

        emit Left(member);

        // Refund the caller with his join deposit
        LibTransfer._untrustedSendValue(payable(member), refundAmount);
    }

    function _isValidFormingProposition(IWallet.Proposition memory proposition)
        internal
        view
        returns (bool)
    {
        StorageFormingProposition.DiamondStorage
            storage ds = StorageFormingProposition.diamondStorage();

        bytes32 propositionHash = LibEIP712Proposition._toTypedDataHash(
            proposition
        );
        return propositionHash == ds.formingPropositionHash;
    }
}