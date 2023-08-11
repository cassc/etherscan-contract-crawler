// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ISwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Native
interface INativeRouter is ISwapCallback {
    struct WidgetFee {
        address signer;
        address feeRecipient;
        uint256 feeRate;
    }

    event SetWidgetFeeSigner(address widgetFeeSigner);

    event WidgetFeeTransfer(
        address widgetFeeRecipient,
        uint256 widgetFeeRate,
        uint256 widgetFeeAmount,
        address widgetFeeToken
    );

    function setWidgetFeeSigner(address _widgetFeeSigner) external;

    function setPauser(address _pauser) external;

    function setContractCallerWhitelistToggle(bool value) external;

    function setContractCallerWhitelist(address caller, bool value) external;

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes orders;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        WidgetFee widgetFee;
        bytes widgetFeeSignature;
        bytes[] fallbackSwapDataArray;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    error ZeroAddressInput();
    error InvalidDeltaValue(int amount0Delta, int amount1Delta);
    error CallbackNotFromOrderBuyer(address caller);
    error MultipleOrdersForInputSingle();
    error MultipleFallbackDataForInputSingle();
    error InvalidWidgetFeeSinger();
    error InvalidWidgetFeeSignature();
    error InvalidWidgetFeeRate();
    error InvalidAmountInValue();
    error CallerNotMsgSender(address caller, address msgSender);
    error CallerNotEOAAndNotWhitelisted();
    error NotEnoughAmountOut(uint256 amountOut, uint256 amountOutMinimum);
    error Missing1inchCalldata();
    error onlyOwnerOrPauserCanCall();
    error InvalidUniswapV3FeeTierInput(uint24);
    error InvalidOrderBuyer();
}