// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./IExchangeAdapter.sol";

/// @title IExchangeAggregator interface
interface IExchangeAggregator {

    /// @param platform Called exchange platforms
    /// @param method The method of the exchange platform
    /// @param encodeExchangeArgs The encoded parameters to call
    /// @param slippage The slippage when exchange
    /// @param oracleAdditionalSlippage The additional slippage for oracle estimated
    struct ExchangeParam {
        address platform;
        uint8 method;
        bytes encodeExchangeArgs;
        uint256 slippage;
        uint256 oracleAdditionalSlippage;
    }

    /// @param platform Called exchange platforms
    /// @param method The method of the exchange platform
    /// @param data The encoded parameters to call
    /// @param swapDescription swap info
    struct SwapParam {
        address platform;
        uint8 method;
        bytes data;
        IExchangeAdapter.SwapDescription swapDescription;
    }

    /// @param srcToken The token swap from
    /// @param dstToken The token swap to
    /// @param amount The amount of token swap from
    /// @param exchangeParam The struct of ExchangeParam
    struct ExchangeToken {
        address fromToken;
        address toToken;
        uint256 fromAmount;
        ExchangeParam exchangeParam;
    }

    /// @param _exchangeAdapters The exchange adapter list to add
    event ExchangeAdapterAdded(address[] _exchangeAdapters);

    /// @param _exchangeAdapters The exchange adapter list to remove
    event ExchangeAdapterRemoved(address[] _exchangeAdapters);

    /// @param _platform Called exchange platforms
    /// @param _amount The amount to swap
    /// @param _srcToken The token swap from
    /// @param _dstToken The token swap to
    /// @param _exchangeAmount The return amount of this swap
    /// @param _receiver The receiver of return token 
    /// @param _sender The sender of this swap
    event Swap(
        address _platform,
        uint256 _amount,
        address _srcToken,
        address _dstToken,
        uint256 _exchangeAmount,
        address indexed _receiver,
        address _sender
    );

    /// @notice Swap from ETHs or tokens to tokens or ETHs
    /// @dev Swap with `_sd` data by using `_method` and `_data` on `_platform`.
    /// @param _platform Called exchange platforms
    /// @param _method The method of the exchange platform
    /// @param _data The encoded parameters to call
    /// @param _sd The description info of this swap
    /// @return The return amount of this swap
    function swap(
        address _platform,
        uint8 _method,
        bytes calldata _data,
        IExchangeAdapter.SwapDescription calldata _sd
    ) external payable returns (uint256);

    /// @notice Batch swap from ETHs or tokens to tokens or ETHs
    /// @param _swapParams The swap param list
    /// @return The return amount list of this batch swap
    function batchSwap(SwapParam[] calldata _swapParams) external payable returns (uint256[] memory);

    /// @notice Get all exchange adapters and its identifiers
    function getExchangeAdapters()
        external
        view
        returns (address[] memory _exchangeAdapters, string[] memory _identifiers);

    /// @notice Add multi exchange adapters
    /// @param _exchangeAdapters The new exchange adapter list to add
    function addExchangeAdapters(address[] calldata _exchangeAdapters) external;

    /// @notice Remove multi exchange adapters
    /// @param _exchangeAdapters The exchange adapter list to remov
    function removeExchangeAdapters(address[] calldata _exchangeAdapters) external;
}