// SPDX-FileCopyrightText: 2022 Lido <[email protected]>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import {IInterchainTokenGateway} from "./IInterchainTokenGateway.sol";

/// @author psirex
/// @notice L1 part of the tokens bridge compatible with Arbitrum's GatewayRouter
interface IL1TokenGateway is IInterchainTokenGateway {
    /// @notice Initiates the tokens bridging from the Ethereum into the Arbitrum chain
    /// @param l1Token_ Address in the L1 chain of the token to bridge
    /// @param to_ Address of the recipient of the token on the corresponding chain
    /// @param amount_ Amount of tokens to bridge
    /// @param maxGas_ Gas limit for immediate L2 execution attempt
    /// @param gasPriceBid_ L2 gas price bid for immediate L2 execution attempt
    /// @param data_ Additional data required for the transaction
    function outboundTransfer(
        address l1Token_,
        address to_,
        uint256 amount_,
        uint256 maxGas_,
        uint256 gasPriceBid_,
        bytes calldata data_
    ) external payable returns (bytes memory);

    event DepositInitiated(
        address l1Token,
        address indexed from,
        address indexed to,
        uint256 indexed sequenceNumber,
        uint256 amount
    );

    event WithdrawalFinalized(
        address l1Token,
        address indexed from,
        address indexed to,
        uint256 indexed exitNum,
        uint256 amount
    );
}