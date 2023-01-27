// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import {IPermit2} from "src/interfaces/IPermit2.sol";
import {Constants} from "src/libraries/Constants.sol";

/// @title Permitter
/// @notice Enables to use permit from the Permit2 contract.
abstract contract Permitter {
    /// @notice Uses permit to transfer tokens.
    /// @param amount Amount of tokens to transfer.
    /// @param permit Permit data.
    /// @param signature Signature data.
    /// @param from Sender address.
    /// @param to Recipient address.
    function usePermit(
        uint256 amount,
        IPermit2.PermitTransferFrom calldata permit,
        bytes calldata signature,
        address from,
        address to
    ) external {
        if (from == Constants.MSG_SENDER) from = msg.sender;
        if (to == Constants.ADDRESS_THIS) to = address(this);

        IPermit2(Constants._PERMIT2).permitTransferFrom(
            permit, IPermit2.SignatureTransferDetails({to: to, requestedAmount: amount}), from, signature
        );
    }

    /// @notice Uses permit to transfer tokens in batch.
    /// @param permits Permit data.
    /// @param transferDetails Transfer details.
    /// @param from Sender address.
    /// @param signature Signature data.
    function usePermitMulti(
        IPermit2.PermitBatchTransferFrom calldata permits,
        IPermit2.SignatureTransferDetails[] memory transferDetails,
        address from,
        bytes calldata signature
    ) external {
        if (from == Constants.MSG_SENDER) from = msg.sender;
        for (uint8 i; i < transferDetails.length; ++i) {
            if (transferDetails[i].to == Constants.ADDRESS_THIS) transferDetails[i].to = address(this);
        }
        IPermit2(Constants._PERMIT2).permitTransferFrom(permits, transferDetails, from, signature);
    }
}