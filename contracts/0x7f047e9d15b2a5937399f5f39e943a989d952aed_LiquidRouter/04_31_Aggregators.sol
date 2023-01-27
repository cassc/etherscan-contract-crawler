// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import {TokenUtils} from "src/common/TokenUtils.sol";
import {Constants} from "src/libraries/Constants.sol";

/// @title Aggregators
/// @notice Enables to interact with different aggregators.
abstract contract Aggregators {
    /// @notice AugustusSwapper contract address.
    address public constant AUGUSTUS = 0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57;

    /// @notice 1nch Router v5 contract address.
    address public constant INCH_ROUTER = 0x1111111254EEB25477B68fb85Ed929f73A960582;

    /// @notice LiFi Diamond contract address.
    address public constant LIFI_DIAMOND = 0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE;

    /// @notice Paraswap Token pull contract address.
    address public constant TOKEN_TRANSFER_PROXY = 0x216B4B4Ba9F3e719726886d34a177484278Bfcae;

    /// @notice Emitted when tokens are exchanged.
    /// @param _from Address of the sender.
    /// @param _to Address of the recipient.
    /// @param _tokenFrom Address of the source token.
    /// @param _tokenTo Address of the destination token.
    /// @param _amountFrom Amount of source token exchanged.
    /// @param _amountTo Amount of destination token received.
    event Exchanged(
        address indexed _from,
        address indexed _to,
        address _tokenFrom,
        address _tokenTo,
        uint256 _amountFrom,
        uint256 _amountTo
    );

    /// @notice Checks if the aggregator is valid.
    modifier onlyValidAggregator(address aggregator) {
        if (aggregator != AUGUSTUS && aggregator != INCH_ROUTER && aggregator != LIFI_DIAMOND) {
            revert Constants.INVALID_AGGREGATOR();
        }
        _;
    }

    /// @notice Exchanges tokens using different aggregators.
    /// @param aggregator Aggregator contract address.
    /// @param srcToken Source token address.
    /// @param destToken Destination token address.
    /// @param underlyingAmount Amount of source token to exchange.
    /// @param callData Data to call the aggregator.
    /// @return received Amount of destination token received.
    function exchange(
        address aggregator,
        address srcToken,
        address destToken,
        uint256 underlyingAmount,
        bytes memory callData,
        address recipient
    ) external payable onlyValidAggregator(aggregator) returns (uint256 received) {
        underlyingAmount = TokenUtils._amountIn(underlyingAmount, srcToken);

        bool success;
        if (srcToken == Constants._ETH) {
            (success,) = aggregator.call{value: underlyingAmount}(callData);
        } else {
            TokenUtils._approve(srcToken, aggregator == AUGUSTUS ? TOKEN_TRANSFER_PROXY : aggregator);
            (success,) = aggregator.call(callData);
        }
        if (!success) revert Constants.SWAP_FAILED();

        if (recipient == Constants.MSG_SENDER) {
            recipient = msg.sender;

            if (destToken == Constants._ETH) {
                received = TokenUtils._balanceInOf(Constants._ETH, address(this));
                TokenUtils._transfer(Constants._ETH, recipient, received);
            } else {
                received = TokenUtils._balanceInOf(destToken, address(this));
                TokenUtils._transfer(destToken, recipient, received);
            }
        }

        emit Exchanged(msg.sender, recipient, srcToken, destToken, underlyingAmount, received);
    }

    receive() external payable {}
}