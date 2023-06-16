// SPDX-License-Identifier: GPL-3.0-or-later
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// NOTE: Adapted from Balancer's BalancerErrors.sol code.

pragma solidity ^0.7.6;

/// @dev Conventions in the methods below are as follows:
///
///      Suffixes:
///
///      - The suffix of a variable name denotes the type contained within the variable.
///        For instance "uint256 _incrementU96" is a 256-bit unsigned container representing
///        a 96-bit value, _increment.
///        In the case of "uint256 _balancerFeeDU1F18", the 256-bit unsigned container is
///        representing a 19 digit decimal value with 18 fractional digits. In this scenario,
///        the D=Decimal, U=Unsigned, F=Fractional.
///
///      - The suffix of a function name denotes what slot it is proprietary too as a
///        matter of convention. While unchecked at run-time or by the compiler, the naming
///        convention easily aids in understanding what slot a packed value is stored within.
///        For instance the function "unpackFeeShiftS3" unpacks the fee shift from slot 3. If
///        the value of slot 2 were passed to this method, the unpacked value would be
///        incorrect.

/// @notice Reverts if the specified condition is not true with the provided error code.
/// @param _condition A condition to test; must resolve to true to not revert.
/// @param _errorCodeD3 An 3 digit decimal error code to present if the condition
///                     resolves to false.
///                     Min. = 0, Max. = 999.
/// @dev WARNING: No checks of _errorCodeD3 are performed for efficiency!
///
// solhint-disable-next-line func-visibility
function requireErrCode(bool _condition, uint256 _errorCodeD3) pure {
  if (!_condition) {
    // We're going to dynamically create a revert string based on the error code, with the following format:
    // 'CFI#{errorCode}'
    // where the code is left-padded with zeroes to three digits (so they range from 000 to 999).
    //
    // We don't have revert strings embedded in the contract to save bytecode size: it takes much less space to store a
    // number (8 to 16 bits) than the individual string characters.
    //
    // The dynamic string creation algorithm that follows could be implemented in Solidity, but assembly allows for a
    // much denser implementation, again saving bytecode size. Given this function unconditionally reverts, this is a
    // safe place to rely on it without worrying about how its usage might affect e.g. memory contents.
    // solhint-disable-next-line no-inline-assembly
    assembly {
      // First, we need to compute the ASCII representation of the error code. We assume that it is in the 0-999
      // range, so we only need to convert three digits. To convert the digits to ASCII, we add 0x30, the value for
      // the '0' character.

      let units := add(mod(_errorCodeD3, 10), 0x30)

      _errorCodeD3 := div(_errorCodeD3, 10)
      let tenths := add(mod(_errorCodeD3, 10), 0x30)

      _errorCodeD3 := div(_errorCodeD3, 10)
      let hundreds := add(mod(_errorCodeD3, 10), 0x30)

      // With the individual characters, we can now construct the full string. The "CFI#" part is a known constant
      // (0x43464923): we simply shift this by 24 (to provide space for the 3 bytes of the error code), and add the
      // characters to it, each shifted by a multiple of 8.
      // The revert reason is then shifted left by 200 bits (256 minus the length of the string, 7 characters * 8 bits
      // per character = 56) to locate it in the most significant part of the 256 slot (the beginning of a byte
      // array).

      let revertReason := shl(200, add(0x43464923000000, add(add(units, shl(8, tenths)), shl(16, hundreds))))

      // We can now encode the reason in memory, which can be safely overwritten as we're about to revert. The encoded
      // message will have the following layout:
      // [ revert reason identifier ] [ string location offset ] [ string length ] [ string contents ]

      // The Solidity revert reason identifier is 0x08c739a0, the function selector of the Error(string) function. We
      // also write zeroes to the next 28 bytes of memory, but those are about to be overwritten.
      mstore(0x0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
      // Next is the offset to the location of the string, which will be placed immediately after (20 bytes away).
      mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
      // The string length is fixed: 7 characters.
      mstore(0x24, 7)
      // Finally, the string itself is stored.
      mstore(0x44, revertReason)

      // Even if the string is only 7 bytes long, we need to return a full 32 byte slot containing it. The length of
      // the encoded message is therefore 4 + 32 + 32 + 32 = 100.
      revert(0, 100)
    }
  }
}

library CronErrors {
  //
  // Permissions
  ////////////////////////////////////////////////////////////////////////////////

  uint256 internal constant SENDER_NOT_FACTORY = 0;
  uint256 internal constant SENDER_NOT_FACTORY_OWNER = 1;
  uint256 internal constant SENDER_NOT_ADMIN = 2;
  uint256 internal constant SENDER_NOT_ARBITRAGE_PARTNER = 3;
  uint256 internal constant NON_VAULT_CALLER = 4;
  uint256 internal constant SENDER_NOT_PARTNER = 5;
  uint256 internal constant SENDER_NOT_FEE_ADDRESS = 7;
  uint256 internal constant SENDER_NOT_ORDER_OWNER_OR_DELEGATE = 8;
  uint256 internal constant CANNOT_TRANSFER_TO_SELF_OR_NULL = 9;
  uint256 internal constant RECIPIENT_NOT_OWNER = 10;
  // A cleared order can be one that:
  //   - was cancelled
  //   - was withdrawn after expiry
  //   - never existed (i.e. empty blockchain state in the future)
  uint256 internal constant CLEARED_ORDER = 11;

  //
  // Modifiers
  ////////////////////////////////////////////////////////////////////////////////

  uint256 internal constant POOL_PAUSED = 100;

  //
  // Configuration & Parameterization
  ////////////////////////////////////////////////////////////////////////////////

  uint256 internal constant UNSUPPORTED_SWAP_KIND = 201;
  uint256 internal constant INSUFFICIENT_LIQUIDITY = 204;
  uint256 internal constant INCORRECT_POOL_ID = 206;
  uint256 internal constant ZERO_SALES_RATE = 208;
  uint256 internal constant NO_FUNDS_AVAILABLE = 212;
  uint256 internal constant MAX_ORDER_LENGTH_EXCEEDED = 223;
  uint256 internal constant NO_FEES_AVAILABLE = 224;
  uint256 internal constant UNSUPPORTED_TOKEN_DECIMALS = 225;
  uint256 internal constant NULL_RECIPIENT_ON_JOIN = 226;
  uint256 internal constant CANT_CANCEL_COMPLETED_ORDER = 227;
  uint256 internal constant MINIMUM_NOT_SATISFIED = 228;

  //
  // General
  ////////////////////////////////////////////////////////////////////////////////

  uint256 internal constant VALUE_EXCEEDS_CONTAINER_SZ = 400;
  uint256 internal constant OVERFLOW = 401;
  uint256 internal constant UNDERFLOW = 402;
  uint256 internal constant PARAM_ERROR = 403;

  //
  // Factory
  ////////////////////////////////////////////////////////////////////////////////

  uint256 internal constant ZERO_TOKEN_ADDRESSES = 500;
  uint256 internal constant IDENTICAL_TOKEN_ADDRESSES = 501;
  uint256 internal constant EXISTING_POOL = 502;
  uint256 internal constant INVALID_FACTORY_OWNER = 503;
  uint256 internal constant INVALID_PENDING_OWNER = 504;
  uint256 internal constant NON_EXISTING_POOL = 505;

  //
  // Periphery Relayer
  ////////////////////////////////////////////////////////////////////////////////
  uint256 internal constant P_ETH_TRANSFER = 600;
  uint256 internal constant P_NULL_USER_ADDRESS = 602;
  uint256 internal constant P_INSUFFICIENT_LIQUIDITY = 603;
  uint256 internal constant P_INSUFFICIENT_TOKEN_A_USER_BALANCE = 604;
  uint256 internal constant P_INSUFFICIENT_TOKEN_B_USER_BALANCE = 605;
  uint256 internal constant P_INVALID_POOL_TOKEN_AMOUNT = 606;
  uint256 internal constant P_INSUFFICIENT_POOL_TOKEN_USER_BALANCE = 607;
  uint256 internal constant P_INVALID_INTERVAL_AMOUNT = 608;
  uint256 internal constant P_DELEGATE_WITHDRAW_RECIPIENT_NOT_OWNER = 609;
  uint256 internal constant P_INVALID_OR_EXPIRED_ORDER_ID = 610;
  uint256 internal constant P_WITHDRAW_BY_ORDER_OR_DELEGATE_ONLY = 611;
  uint256 internal constant P_DELEGATE_CANCEL_RECIPIENT_NOT_OWNER = 612;
  uint256 internal constant P_CANCEL_BY_ORDER_OR_DELEGATE_ONLY = 613;
  uint256 internal constant P_INVALID_TOKEN_IN_ADDRESS = 614;
  uint256 internal constant P_INVALID_TOKEN_OUT_ADDRESS = 615;
  uint256 internal constant P_INVALID_POOL_TYPE = 616;
  uint256 internal constant P_NON_EXISTING_POOL = 617;
  uint256 internal constant P_INVALID_POOL_ADDRESS = 618;
  uint256 internal constant P_INVALID_AMOUNT_IN = 619;
  uint256 internal constant P_INSUFFICIENT_TOKEN_IN_USER_BALANCE = 620;
  uint256 internal constant P_POOL_HAS_NO_LIQUIDITY = 621;
  uint256 internal constant P_MAX_ORDER_LENGTH_EXCEEDED = 622;
  uint256 internal constant P_NOT_IMPLEMENTED = 624;
  uint256 internal constant P_MULTICALL_NOT_SUPPORTED = 625;
}