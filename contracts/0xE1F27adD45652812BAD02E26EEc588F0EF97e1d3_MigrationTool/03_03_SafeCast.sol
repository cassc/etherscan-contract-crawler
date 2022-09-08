/** 
 *  SourceUnit: /Users/patrickmckelvy/code/defi/os/alchemix/alops/submodules/v2-foundry/src/migration/MigrationTool.sol
*/
            
pragma solidity ^0.8.13;

/// @notice An error used to indicate that an action could not be completed because either the `msg.sender` or
///         `msg.origin` is not authorized.
error Unauthorized();

/// @notice An error used to indicate that an action could not be completed because the contract either already existed
///         or entered an illegal condition which is not recoverable from.
error IllegalState();

/// @notice An error used to indicate that an action could not be completed because of an illegal argument was passed
///         to the function.
error IllegalArgument();

/** 
 *  SourceUnit: /Users/patrickmckelvy/code/defi/os/alchemix/alops/submodules/v2-foundry/src/migration/MigrationTool.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: GPL-2.0-or-later
pragma solidity >=0.5.0;

////import {IllegalArgument} from "../base/Errors.sol";

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
  /// @notice Cast a uint256 to a int256, revert on overflow
  /// @param y The uint256 to be casted
  /// @return z The casted integer, now type int256
  function toInt256(uint256 y) internal pure returns (int256 z) {
    if (y >= 2**255) {
      revert IllegalArgument();
    }
    z = int256(y);
  }

  /// @notice Cast a int256 to a uint256, revert on underflow
  /// @param y The int256 to be casted
  /// @return z The casted integer, now type uint256
  function toUint256(int256 y) internal pure returns (uint256 z) {
    if (y < 0) {
      revert IllegalArgument();
    }
    z = uint256(y);
  }
}