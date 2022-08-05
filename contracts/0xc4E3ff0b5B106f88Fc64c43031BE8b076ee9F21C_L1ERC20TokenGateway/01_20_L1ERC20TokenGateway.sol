// SPDX-FileCopyrightText: 2022 Lido <[email protected]>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IL1TokenGateway, IInterchainTokenGateway} from "./interfaces/IL1TokenGateway.sol";

import {L1CrossDomainEnabled} from "./L1CrossDomainEnabled.sol";
import {L1OutboundDataParser} from "./libraries/L1OutboundDataParser.sol";
import {InterchainERC20TokenGateway} from "./InterchainERC20TokenGateway.sol";

/// @author psirex
/// @notice Contract implements ITokenGateway interface and with counterpart L2ERC20TokenGatewy
///     allows bridging registered ERC20 compatible tokens between Ethereum and Arbitrum chains
contract L1ERC20TokenGateway is
    InterchainERC20TokenGateway,
    L1CrossDomainEnabled,
    IL1TokenGateway
{
    using SafeERC20 for IERC20;

    /// @param inbox_ Address of the Arbitrum’s Inbox contract in the L1 chain
    /// @param router_ Address of the router in the L1 chain
    /// @param counterpartGateway_ Address of the counterpart L2 gateway
    /// @param l1Token_ Address of the bridged token in the L1 chain
    /// @param l2Token_ Address of the token minted on the Arbitrum chain when token bridged
    constructor(
        address inbox_,
        address router_,
        address counterpartGateway_,
        address l1Token_,
        address l2Token_
    )
        InterchainERC20TokenGateway(
            router_,
            counterpartGateway_,
            l1Token_,
            l2Token_
        )
        L1CrossDomainEnabled(inbox_)
    {}

    /// @inheritdoc IL1TokenGateway
    function outboundTransfer(
        address l1Token_,
        address to_,
        uint256 amount_,
        uint256 maxGas_,
        uint256 gasPriceBid_,
        bytes calldata data_
    )
        external
        payable
        whenDepositsEnabled
        onlyNonZeroAccount(to_)
        onlySupportedL1Token(l1Token_)
        returns (bytes memory)
    {
        (address from, uint256 maxSubmissionCost) = L1OutboundDataParser.decode(
            router,
            data_
        );

        IERC20(l1Token_).safeTransferFrom(from, address(this), amount_);

        uint256 retryableTicketId = _sendOutboundTransferMessage(
            from,
            to_,
            amount_,
            CrossDomainMessageOptions({
                maxGas: maxGas_,
                callValue: 0,
                gasPriceBid: gasPriceBid_,
                maxSubmissionCost: maxSubmissionCost
            })
        );

        emit DepositInitiated(l1Token, from, to_, retryableTicketId, amount_);

        return abi.encode(retryableTicketId);
    }

    /// @inheritdoc IInterchainTokenGateway
    function finalizeInboundTransfer(
        address l1Token_,
        address from_,
        address to_,
        uint256 amount_,
        bytes calldata // data_
    )
        external
        whenWithdrawalsEnabled
        onlySupportedL1Token(l1Token_)
        onlyFromCrossDomainAccount(counterpartGateway)
    {
        IERC20(l1Token_).safeTransfer(to_, amount_);

        // The current implementation doesn't support fast withdrawals, so we
        // always use 0 for the exitNum argument in the event
        emit WithdrawalFinalized(l1Token_, from_, to_, 0, amount_);
    }

    function _sendOutboundTransferMessage(
        address from_,
        address to_,
        uint256 amount_,
        CrossDomainMessageOptions memory messageOptions
    ) private returns (uint256) {
        return
            sendCrossDomainMessage(
                from_,
                counterpartGateway,
                getOutboundCalldata(l1Token, from_, to_, amount_, ""),
                messageOptions
            );
    }
}