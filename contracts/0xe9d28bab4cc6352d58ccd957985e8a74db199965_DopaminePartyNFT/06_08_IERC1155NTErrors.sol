// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title ERC1155NT Errors Interface
interface IERC1155NTErrors {

    /// @notice Mismatch between input arrays.
    error ArityMismatch();

    /// @notice Receiving address cannot be the zero address.
    error ReceiverInvalid();

    /// @notice Receiving contract does not implement the ERC-721 wallet interface.
    error SafeTransferUnsupported();

    /// @notice Token has already been minted.
    error TokenAlreadyMinted();

    /// @notice Token may not be transferred.
    error TokenNonTransferable();

}