// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {TimeswapV2TokenMintCallbackParam} from "../../structs/CallbackParam.sol";

interface ITimeswapV2TokenMintCallback {
  /// @dev Callback for `ITimeswapV2Token.mint`
  function timeswapV2TokenMintCallback(
    TimeswapV2TokenMintCallbackParam calldata param
  ) external returns (bytes memory data);
}