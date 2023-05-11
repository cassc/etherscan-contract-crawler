// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {TimeswapV2OptionSwapCallbackParam} from "../../structs/CallbackParam.sol";

/// @title Callback for ITimeswapV2Option#swap
/// @notice Any contract that calls ITimeswapV2Option#swap must implement this interface.
interface ITimeswapV2OptionSwapCallback {
  /// @notice Called to `msg.sender` after initiating a swap from ITimeswapV2Option#swap.
  /// @dev In the implementation, you must transfer token0 for the swap transaction.
  /// The caller of this method must be checked to be a Timeswap V2 Option pair deployed by the canonical Timeswap V2 Factory.
  /// @dev The long0 positions or long1 positions will already minted to the recipients.
  /// @param param The param of the swap callback.
  /// @return data The bytes code returned from the callback.
  function timeswapV2OptionSwapCallback(
    TimeswapV2OptionSwapCallbackParam calldata param
  ) external returns (bytes memory data);
}