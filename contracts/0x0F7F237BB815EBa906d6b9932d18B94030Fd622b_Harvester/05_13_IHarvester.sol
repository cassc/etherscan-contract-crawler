// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "../exchanges/IExchangeAggregator.sol";

interface IHarvester {
    event Exchange(
        address _platform,
        address _fromToken,
        uint256 _fromAmount,
        address _toToken,
        uint256 _exchangeAmount
    );
    event ReceiverChanged(address _receiver);

    event SellToChanged(address _sellTo);

    /// @notice Setting profit receive address.
    function setProfitReceiver(address _receiver) external;

    /// @notice Setting sell to token.
    function setSellTo(address _sellTo) external;

    /// @notice Collect reward tokens from all strategies
    function collect(address[] calldata _strategies) external;

    /// @notice Swap reward token to stablecoins
    function exchangeAndSend(IExchangeAggregator.ExchangeToken[] calldata _exchangeTokens) external;

    /**
     * @dev Transfer token to governor. Intended for recovering tokens stuck in
     *      contract, i.e. mistaken sends.
     * @param _asset Address for the asset
     * @param _amount Amount of the asset to transfer
     */
    function transferToken(address _asset, uint256 _amount) external;
}