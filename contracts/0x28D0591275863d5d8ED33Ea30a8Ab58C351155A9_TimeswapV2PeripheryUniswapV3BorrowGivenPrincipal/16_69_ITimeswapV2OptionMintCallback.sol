// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {TimeswapV2OptionMintCallbackParam} from "../../structs/CallbackParam.sol";

/// @title Callback for ITimeswapV2Option#mint
/// @notice Any contract that calls ITimeswapV2Option#mint must implement this interface.
interface ITimeswapV2OptionMintCallback {
  /// @notice Called to `msg.sender` after initiating a mint from ITimeswapV2Option#mint.
  /// @dev In the implementation, you must transfer token0 and token1 for the mint transaction.
  /// The caller of this method must be checked to be a Timeswap V2 Option pair deployed by the canonical Timeswap V2 Factory.
  /// @dev The long0 positions, long1 positions, and/or short positions will already minted to the recipients.
  /// @param param The parameter of the callback.
  /// @return data The bytes code returned from the callback.
  function timeswapV2OptionMintCallback(
    TimeswapV2OptionMintCallbackParam calldata param
  ) external returns (bytes memory data);
}