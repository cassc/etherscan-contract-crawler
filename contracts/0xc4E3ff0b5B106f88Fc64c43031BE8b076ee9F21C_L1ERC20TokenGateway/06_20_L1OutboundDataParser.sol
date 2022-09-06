// SPDX-FileCopyrightText: 2022 Lido <[email protected]>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

/// @author psirex
/// @notice A helper library to parse data passed to outboundTransfer() of L1TokensGateway
library L1OutboundDataParser {
    /// @dev Decodes value contained in data_ bytes array and returns it
    /// @param router_ Address of the Arbitrum’s L1GatewayRouter
    /// @param data_ Data encoded for the outboundTransfer() method
    /// @return Decoded (from, maxSubmissionCost) values
    function decode(address router_, bytes memory data_)
        internal
        view
        returns (address, uint256)
    {
        if (msg.sender != router_) {
            return (msg.sender, _parseSubmissionCostData(data_));
        }
        (address from, bytes memory extraData) = abi.decode(
            data_,
            (address, bytes)
        );
        return (from, _parseSubmissionCostData(extraData));
    }

    /// @dev Extracts the maxSubmissionCost value from the outboundTransfer() data
    function _parseSubmissionCostData(bytes memory data_)
        private
        pure
        returns (uint256)
    {
        (uint256 maxSubmissionCost, bytes memory extraData) = abi.decode(
            data_,
            (uint256, bytes)
        );
        if (extraData.length != 0) {
            revert ExtraDataNotEmpty();
        }
        return maxSubmissionCost;
    }

    error ExtraDataNotEmpty();
}