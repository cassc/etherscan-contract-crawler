// SPDX-FileCopyrightText: 2022 Lido <[email protected]>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import {BridgingManager} from "../BridgingManager.sol";
import {BridgeableTokens} from "../BridgeableTokens.sol";

import {IInterchainTokenGateway} from "./interfaces/IInterchainTokenGateway.sol";

/// @author psirex
/// @notice The contract keeps logic shared among both L1 and L2 gateways, adding the methods for
///     bridging management: enabling and disabling withdrawals/deposits
abstract contract InterchainERC20TokenGateway is
    BridgingManager,
    BridgeableTokens,
    IInterchainTokenGateway
{
    /// @notice Address of the router in the corresponding chain
    address public immutable router;

    /// @inheritdoc IInterchainTokenGateway
    address public immutable counterpartGateway;

    /// @param router_ Address of the router in the corresponding chain
    /// @param counterpartGateway_ Address of the counterpart gateway used in the bridging process
    /// @param l1Token_ Address of the bridged token in the Ethereum chain
    /// @param l2Token_ Address of the token minted on the Arbitrum chain when token bridged
    constructor(
        address router_,
        address counterpartGateway_,
        address l1Token_,
        address l2Token_
    ) BridgeableTokens(l1Token_, l2Token_) {
        router = router_;
        counterpartGateway = counterpartGateway_;
    }

    /// @inheritdoc IInterchainTokenGateway
    /// @dev The current implementation returns the l2Token address when passed l1Token_ equals
    ///     to l1Token declared in the contract and address(0) in other cases
    function calculateL2TokenAddress(address l1Token_)
        external
        view
        returns (address)
    {
        if (l1Token_ == l1Token) {
            return l2Token;
        }
        return address(0);
    }

    /// @inheritdoc IInterchainTokenGateway
    function getOutboundCalldata(
        address l1Token_,
        address from_,
        address to_,
        uint256 amount_,
        bytes memory // data_
    ) public pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                IInterchainTokenGateway.finalizeInboundTransfer.selector,
                l1Token_,
                from_,
                to_,
                amount_,
                ""
            );
    }
}