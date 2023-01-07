// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

/// @title IPriceOracleConsumer interface
interface IPriceOracleConsumer {

    /// @return The number of decimals for getting user representation of a token amount.
    function decimals() external view returns(uint8);

    /// @return The price of 'stEth' token in ETH
    function stEthPriceInEth() external view returns(uint);

    /// @return The price of 'wstEth' token in ETH
    function wstEthPriceInEth() external view returns(uint);

    /// @return The price of 'cbEth' token in ETH
    function cbEthPriceInEth() external view returns(uint);

    /// @return The price of 'rEth' token in ETH
    function rEthPriceInEth() external view returns(uint);

    /// @return The price of 'wEth' token in ETH
    function wEthPriceInEth() external view returns(uint);

    /// @return The price of 'sEth' token in ETH
    function sEthPriceInEth() external view returns(uint);

    /// @return The price of 'sEth2' token in ETH
    function sEth2PriceInEth() external view returns(uint);

    /// @return The price of 'rEth2' token in ETH
    function rEth2PriceInEth() external view returns (uint);

    /// @return The price of 'ETH' token in USD
    function ethPriceInUsd() external view returns(uint);

    /// @return The price of 'stEth' token in USD
    function stEthPriceInUsd() external view returns(uint);

    /// @return The price of 'wstEth' token in USD
    function wstEthPriceInUsd() external view returns(uint);

    /// @return The price of 'cbEth' token in USD
    function cbEthPriceInUsd() external view returns(uint);

    /// @return The price of '' token in USD
    function rEthPriceInUsd() external view returns(uint);

    /// @return The price of 'rEth' token in USD
    function wEthPriceInUsd() external view returns(uint);

    /// @return The price of 'sEth2' token in USD
    function sEth2PriceInUsd() external view returns(uint);

    /// @return The price of 'rEth2' token in USD
    function rEth2PriceInUsd() external view returns (uint);

    /// @return The price of '_asset' token in ETH
    function priceInEth(address _asset) external view returns(uint);

    /// @return The price of '_asset' token in USD
    function priceInUSD(address _asset) external view returns(uint);

    /// @return The value of '_asset' with `_amount` in ETH
    function valueInEth(address _asset,uint _amount) external view returns(uint);

    /// @return The value of '_asset' with `_amount` in USD
    function valueInUsd(address _asset,uint _amount) external view returns(uint);

    /// @return The value of '_fromToken' with `_amount` in unit of the `_toToken`
    function valueInTargetToken(address _fromToken, uint256 _amount, address _toToken) external view returns(uint256);

}