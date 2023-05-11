// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {TimeswapV2PoolDeleverageChoiceCallbackParam, TimeswapV2PoolDeleverageCallbackParam} from "../../structs/CallbackParam.sol";

/// @dev The interface that needs to be implemented by a contract calling the deleverage function.
interface ITimeswapV2PoolDeleverageCallback {
  /// @dev Returns the amount of long0 position and long1 positions chosen to be deposited to the pool.
  /// @notice The StrikeConversion.combine of long0 position and long1 position must be greater than or equal to long amount.
  /// @dev The short positions will already be minted to the recipient.
  /// @return long0Amount Amount of long0 position to be deposited.
  /// @return long1Amount Amount of long1 position to be deposited.
  /// @param data The bytes of data to be sent to msg.sender.
  function timeswapV2PoolDeleverageChoiceCallback(
    TimeswapV2PoolDeleverageChoiceCallbackParam calldata param
  ) external returns (uint256 long0Amount, uint256 long1Amount, bytes memory data);

  /// @dev Require the transfer of long0 position and long1 position into the pool.
  /// @param data The bytes of data to be sent to msg.sender.
  function timeswapV2PoolDeleverageCallback(
    TimeswapV2PoolDeleverageCallbackParam calldata param
  ) external returns (bytes memory data);
}