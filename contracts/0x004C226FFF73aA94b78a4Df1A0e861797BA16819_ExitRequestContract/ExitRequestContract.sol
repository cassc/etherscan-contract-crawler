/**
 *Submitted for verification at Etherscan.io on 2023-04-12
*/

// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2023 Kiln <[email protected]>
//
// ██╗  ██╗██╗██╗     ███╗   ██╗
// ██║ ██╔╝██║██║     ████╗  ██║
// █████╔╝ ██║██║     ██╔██╗ ██║
// ██╔═██╗ ██║██║     ██║╚██╗██║
// ██║  ██╗██║███████╗██║ ╚████║
// ╚═╝  ╚═╝╚═╝╚══════╝╚═╝  ╚═══╝
//
pragma solidity 0.8.17;

/// @title Exit Request Contract
/// @author pwnh4 @ Kiln
/// @notice ExitRequestContract helps stakers notice their node operator to exit their validators
contract ExitRequestContract {
    /// @notice Thrown when a wallet is requesting an exit of a validator
    /// @param caller wallet requesting the validator exit
    /// @param pubkey public key of the validator to exit
    event ExitRequest(address caller, bytes pubkey);

    /// @notice Request exit for one or many validators
    /// @param validators_ list of validator pubkeys to request exit for
    function requestExit(bytes[] calldata validators_) external {
        for (uint256 i = 0; i < validators_.length; ) {
            emit ExitRequest(msg.sender, validators_[i]);
            unchecked {
                ++i;
            }
        }
    }
}