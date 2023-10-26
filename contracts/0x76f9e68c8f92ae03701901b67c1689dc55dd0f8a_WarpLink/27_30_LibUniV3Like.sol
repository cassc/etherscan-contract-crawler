// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * NOTE: Events and errors must be copied to ILibUniV3Like
 */
library LibUniV3Like {
  error CallbackAlreadyActive();
  error CallbackStillActive();

  bytes32 constant DIAMOND_STORAGE_SLOT = keccak256('diamond.storage.LibUniV3Like');

  /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
  uint160 internal constant MIN_SQRT_RATIO = 4295128739 + 1;

  /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
  uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342 - 1;

  struct CallbackState {
    uint256 amount;
    address payer;
    address token;
  }

  struct State {
    // TODO: Does this help by using `MSTORE8`?
    uint8 isActive;
    /**
     * Transient storage variable used in the callback
     */
    CallbackState callback;
  }

  function state() internal pure returns (State storage s) {
    bytes32 slot = DIAMOND_STORAGE_SLOT;

    assembly {
      s.slot := slot
    }
  }

  function beforeCallback(CallbackState memory callback) internal {
    if (state().isActive == 1) {
      revert CallbackAlreadyActive();
    }

    state().isActive = 1;
    state().callback = callback;
  }

  function afterCallback() internal view {
    if (state().isActive == 1) {
      // The field is expected to be zeroed out by the callback
      revert CallbackStillActive();
    }
  }
}