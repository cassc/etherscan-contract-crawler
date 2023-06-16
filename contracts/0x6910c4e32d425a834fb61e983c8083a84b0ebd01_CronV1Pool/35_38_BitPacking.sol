// (c) Copyright 2023, Bad Pumpkin Inc. All Rights Reserved
//
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.7.6;

import { C } from "./Constants.sol";
import { requireErrCode, CronErrors } from "./Errors.sol";

/// @notice Library for bit-packing generic and specific values pertinent to Cron-Fi TWAMM
///         into storage-slots efficiently (both for gas use and contract size).
///
/// @dev Many custom representations are used herein (i.e. non native word lengths) and there
///      are a number of explicit checks against the maximum of these non native word lengths.
///      Furthermore there are unchecked operations (this code targets Solidity 0.7.x which
///      didn't yet feature implicit arithmetic checks or have the 'unchecked' block feature)
///      in this library for reasons of efficiency or desired overflow. Wherever they appear
///      they will be documented and accompanied with one of the following tags:
///        - #unchecked
///        - #overUnderFlowIntended
///      Identified risks will be accompanied and described with the following tag:
///        - #RISK
///
/// @dev Generic shifting methods were eschewed because of their additional gas use.
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
///
///      Bit-Numbering:
///
///      - Bits are counted starting with the least-significant bit (LSB) from 1. Thus for
///        a 256-bit slot, the most-significant bit (MSB) is bit 256 and the LSB is bit 1.
///
///
///      Offsets:
///
///      - Offsets are the distance from the LSB to the desired LSB of the word being
///        placed within a slot. For instance, to store an 8-bit word in a 256-bit slot
///        at bits 16 down to 9, an offset of 8-bits should be specified.
///
///
///      Pairs
///
///      - The following methods which operate upon pairs follow the convention that a
///        pair consists of two same sized words, with word0 stored above word1 within
///        a slot. For example, a pair of 96-bit words will be stored with word0
///        occupying bits 192 downto 97 and word1 occupying bits 96 downto 1. The following
///        diagram depicts this scenario:
///
///              bit-256     bit-192      bit-96      bit-1
///                 |           |            |           |
///                 v           v            v           v
///
///           MSB < I    ???   II   word0   II   word1   I > LSB
///
///                            ^            ^
///                            |            |
///                         bit-193      bit-97
///
library BitPackingLib {
  //
  // Generic Packing Functions
  ////////////////////////////////////////////////////////////////////////////////

  /// @notice Packs bit _bitU1 into the provided 256-bit slot, _slot, at location _offsetU8
  ///         bits from the provided slot's LSB, bit 1.
  /// @param _slot A 256-bit container to pack bit _bitU1 within.
  /// @param _bitU1 A 1-bit value to pack into the provided slot.
  ///               Min. = 0, Max. = 1.
  /// @param _offsetU8 The distance in bits from the provided slot's LSB to store _bitU1 at.
  ///                  Min. = 0, Max. = 255.
  /// @dev WARNING: No checks of _offsetU8 are performed for efficiency!
  /// @return slot The modified slot containing _bitU1 at bit position _offsetU8 + 1.
  ///
  function packBit(
    uint256 _slot,
    uint256 _bitU1,
    uint256 _offsetU8
  ) internal pure returns (uint256 slot) {
    requireErrCode(_bitU1 <= C.MAX_U1, CronErrors.VALUE_EXCEEDS_CONTAINER_SZ);

    uint256 mask = C.MAX_U1 << _offsetU8;
    slot = (_bitU1 != 0) ? (_slot | mask) : (_slot & (~mask));
  }

  /// @notice Unpacks bitU1 from the provided 256-bit slot, _slot, at location _offsetU8
  ///         bits from the provided slot's LSB, bit 1.
  /// @param _slot A 256-bit container to unpack bitU1 from.
  /// @param _offsetU8 The distance in bits from the provided slot's LSB to unpack bitU1 from.
  ///                  Min. = 0, Max. = 255.
  /// @dev WARNING: No checks of _offsetU8 are performed for efficiency!
  /// @return bitU1 The 1-bit value unpacked from the provided slot.
  ///               Min. = 0, Max. = 1.
  ///
  function unpackBit(uint256 _slot, uint256 _offsetU8) internal pure returns (uint256 bitU1) {
    bitU1 = ((_slot >> _offsetU8) & C.MAX_U1);
  }

  /// @notice Packs ten-bit word, _wordU10, into the provided 256-bit slot, _slot, at location
  ///         _offsetU8 bits from the provided slot's LSB, bit 1.
  /// @param _slot A 256-bit container to pack bit _wordU10 within.
  /// @param _wordU10 A ten-bit word to pack into the provided slot.
  ///                 Min. = 0, Max. = (2**10)-1.
  /// @param _offsetU8 The distance in bits from the provided slot's LSB to store _bitU1 at.
  ///                  Min. = 0, Max. = 255.
  /// @dev WARNING: No checks of _offsetU8 are performed for efficiency!
  /// @return slot The modified slot containing _wordU10 at bit position _offsetU8 + 1.
  ///
  function packU10(
    uint256 _slot,
    uint256 _wordU10,
    uint256 _offsetU8
  ) internal pure returns (uint256 slot) {
    requireErrCode(_wordU10 <= C.MAX_U10, CronErrors.VALUE_EXCEEDS_CONTAINER_SZ);

    uint256 clearMask = ~(C.MAX_U10 << _offsetU8);
    uint256 setMask = _wordU10 << _offsetU8;
    slot = (_slot & clearMask) | setMask;
  }

  /// @notice Unpacks wordU10 from the provided 256-bit slot, _slot, at location _offsetU8
  ///         bits from the provided slot's LSB, bit 1.
  /// @param _slot A 256-bit container to unpack wordU10 from.
  /// @param _offsetU8 The distance in bits from the provided slot's LSB to unpack wordU10 from.
  ///                  Min. = 0, Max. = 255.
  /// @dev WARNING: No checks of _offsetU8 are performed for efficiency!
  /// @return wordU10 The ten-bit word unpacked from the provided slot.
  ///                  Min. = 0, Max. = (2**10)-1.
  function unpackU10(uint256 _slot, uint256 _offsetU8) internal pure returns (uint256 wordU10) {
    wordU10 = (_slot >> _offsetU8) & C.MAX_U10;
  }

  /// @notice Increments the 96-bit words, word0 and/or word1, stored within the provided
  ///         256-bit slot, _slot, by the values provided in _increment0U96 and _increment1U96
  ///         respectively. Importantly, if the increment results in overflow, the value
  ///         will "clamp" to the maximum value (2**96)-1.
  /// @dev    See the section on Pairs in the notes on Conventions to understand how the two
  ///         words are stored within the provided slot.
  /// @param _slot A 256-bit container holding two 96-bit words, word0 and word1.
  /// @param _increment0U96 The amount to increment word0 by.
  ///                       Min. = 0, Max. = (2**96)-1.
  /// @param _increment1U96 The amount to increment word1 by.
  ///                       Min. = 0, Max. = (2**96)-1.
  /// @return slot The modified slot containing incremented values of word0 and/or word1.
  ///
  function incrementPairWithClampU96(
    uint256 _slot,
    uint256 _increment0U96,
    uint256 _increment1U96
  ) internal pure returns (uint256 slot) {
    uint256 word0U96 = ((_slot >> 96) & C.MAX_U96);
    uint256 word1U96 = (_slot & C.MAX_U96);

    if (_increment0U96 > 0) {
      requireErrCode(C.MAX_U256 - word0U96 >= _increment0U96, CronErrors.OVERFLOW);
      // #unchecked
      //            safe from overflow in increment below because of check above.
      word0U96 += _increment0U96;
      // Clamp the resulting value to (2**96)+1 on overflow of U96 beyond MAX_U96:
      if (word0U96 > C.MAX_U96) {
        word0U96 = C.MAX_U96;
      }
    }

    if (_increment1U96 > 0) {
      requireErrCode(C.MAX_U256 - word1U96 >= _increment1U96, CronErrors.OVERFLOW);
      // #unchecked
      //            safe from overflow in increment below because of check above.
      word1U96 += _increment1U96;
      // Clamp the resulting value to (2**96)+1 on overflow of U96 beyond MAX_U96:
      if (word1U96 > C.MAX_U96) {
        word1U96 = C.MAX_U96;
      }
    }

    // NOTE: No need create set masks as _value*U96 above checked against MAX_U96/clamped.
    slot = (_slot & C.CLEAR_MASK_PAIR_U96) | (word0U96 << 96) | word1U96;
  }

  /// @notice Unpacks the two 96-bit values, word0 and word1, from the provided slot, _slot,
  ///         returning them along with the provided slot modified to clear the values
  ///         or word0 and word1 to zero.
  /// @dev    See the section on Pairs in the notes on Conventions to understand how the two
  ///         words are stored within the provided slot.
  /// @param _slot A 256-bit container holding two 96-bit words, word0 and word1.
  /// @return slot The modified slot containing cleared values of word0 and word1.
  /// @return word0U96 The value of word0 prior to clearing it.
  ///                  Min. = 0, Max. = (2**96)-1.
  /// @return word1U96 The value of word1 prior to clearing it.
  ///                  Min. = 0, Max. = (2**96)-1.
  ///
  function unpackAndClearPairU96(uint256 _slot)
    internal
    pure
    returns (
      uint256 slot,
      uint256 word0U96,
      uint256 word1U96
    )
  {
    word0U96 = (_slot >> 96) & C.MAX_U96;
    word1U96 = _slot & C.MAX_U96;

    slot = _slot & C.CLEAR_MASK_PAIR_U96;
  }

  /// @notice Unpacks and returns the two 96-bit values, word0 and word1, from the provided slot.
  /// @dev    See the section on Pairs in the notes on Conventions to understand how the two
  ///         words are stored within the provided slot.
  /// @param _slot A 256-bit container holding two 96-bit words, word0 and word1.
  /// @return word0U96 The value of word0.
  ///                  Min. = 0, Max. = (2**96)-1.
  /// @return word1U96 The value of word1.
  ///                  Min. = 0, Max. = (2**96)-1.
  ///
  function unpackPairU96(uint256 _slot) internal pure returns (uint256 word0U96, uint256 word1U96) {
    word0U96 = (_slot >> 96) & C.MAX_U96;
    word1U96 = _slot & C.MAX_U96;
  }

  /// @notice Packs the two provided 112-bit words, word0 and word1, into the provided 256-bit
  ///         slot, _slot.
  /// @dev    See the section on Pairs in the notes on Conventions to understand how the two
  ///         words are stored within the provided slot.
  /// @param _slot A 256-bit container holding two 112-bit words, word0 and word1.
  /// @param _word0U112 The value of word0 to pack.
  ///                   Min. = 0, Max. = (2**112)-1.
  /// @param _word1U112 The value of word1 to pack.
  ///                   Min. = 0, Max. = (2**112)-1.
  /// @return slot The modified slot containing the values of word0 and word1.
  ///
  function packPairU112(
    uint256 _slot,
    uint256 _word0U112,
    uint256 _word1U112
  ) internal pure returns (uint256 slot) {
    requireErrCode(_word0U112 <= C.MAX_U112, CronErrors.VALUE_EXCEEDS_CONTAINER_SZ);
    requireErrCode(_word1U112 <= C.MAX_U112, CronErrors.VALUE_EXCEEDS_CONTAINER_SZ);

    slot = (_slot & C.CLEAR_MASK_PAIR_U112) | (_word0U112 << 112) | _word1U112;
  }

  /// @notice Unpacks and returns the two 112-bit values, word0 and word1, from the provided slot.
  /// @dev    See the section on Pairs in the notes on Conventions to understand how the two
  ///         words are stored within the provided slot.
  /// @param _slot A 256-bit container holding two 112-bit words, word0 and word1.
  /// @return word0U112 The value of word0.
  ///                  Min. = 0, Max. = (2**112)-1.
  /// @return word1U112 The value of word1.
  ///                  Min. = 0, Max. = (2**112)-1.
  ///
  function unpackPairU112(uint256 _slot) internal pure returns (uint256 word0U112, uint256 word1U112) {
    word0U112 = (_slot >> 112) & C.MAX_U112;
    word1U112 = _slot & C.MAX_U112;
  }

  /// @notice Increments the 112-bit words, word0 and/or word1, stored within the provided
  ///         256-bit slot, _slot, by the values provided in _increment0U112 and _increment1U112
  ///         respectively. Errors on overflow.
  /// @dev    See the section on Pairs in the notes on Conventions to understand how the two
  ///         words are stored within the provided slot.
  /// @param _slot A 256-bit container holding two 112-bit words, word0 and word1.
  /// @param _increment0U112 The amount to increment word0 by.
  ///                        Min. = 0, Max. = (2**112)-1.
  /// @param _increment1U112 The amount to increment word1 by.
  ///                        Min. = 0, Max. = (2**112)-1.
  /// @return slot The modified slot containing incremented values of word0 and/or word1.
  ///
  function incrementPairU112(
    uint256 _slot,
    uint256 _increment0U112,
    uint256 _increment1U112
  ) internal pure returns (uint256 slot) {
    uint256 word0U112 = ((_slot >> 112) & C.MAX_U112);
    uint256 word1U112 = (_slot & C.MAX_U112);

    if (_increment0U112 > 0) {
      requireErrCode(C.MAX_U112 - word0U112 >= _increment0U112, CronErrors.OVERFLOW);
      // #unchecked
      //            safe from overflow in increment below because of check above.
      word0U112 += _increment0U112;
    }
    if (_increment1U112 > 0) {
      requireErrCode(C.MAX_U112 - word1U112 >= _increment1U112, CronErrors.OVERFLOW);
      // #unchecked
      //            safe from overflow in increment below because of check above.
      word1U112 += _increment1U112;
    }

    // NOTE: No need to create set masks as _value*U112 above checked against MAX_U112.
    slot = (_slot & C.CLEAR_MASK_PAIR_U112) | (word0U112 << 112) | word1U112;
  }

  /// @notice Decrements the 112-bit words, word0 and/or word1, stored within the provided
  ///         256-bit slot, _slot, by the values provided in _decrement0U112 and
  ///         _decrement1U112 respectively. Errors on underflow.
  /// @dev    See the section on Pairs in the notes on Conventions to understand how the two
  ///         words are stored within the provided slot.
  /// @param _slot A 256-bit container holding two 112-bit words, word0 and word1.
  /// @param _decrement0U112 The amount to decrement word0 by.
  ///                        Min. = 0, Max. = (2**112)-1.
  /// @param _decrement1U112 The amount to decrement word1 by.
  ///                        Min. = 0, Max. = (2**112)-1.
  /// @return slot The modified slot containing decremented values of word0 and/or word1.
  ///
  function decrementPairU112(
    uint256 _slot,
    uint256 _decrement0U112,
    uint256 _decrement1U112
  ) internal pure returns (uint256 slot) {
    uint256 word0U112 = ((_slot >> 112) & C.MAX_U112);
    uint256 word1U112 = (_slot & C.MAX_U112);

    if (_decrement0U112 > 0) {
      requireErrCode(word0U112 >= _decrement0U112, CronErrors.UNDERFLOW);
      // #unchecked
      //            safe from underflow in decrement below because of check above.
      word0U112 -= _decrement0U112;
    }
    if (_decrement1U112 > 0) {
      requireErrCode(word1U112 >= _decrement1U112, CronErrors.UNDERFLOW);
      // #unchecked
      //            safe from underflow in decrement below because of check above.
      word1U112 -= _decrement1U112;
    }

    // NOTE: No need to create set masks as _value*U112 above both at most MAX_U112 (correct by
    //       construction--checked at creation/pack) and operation is subtraction with underflow
    //       checked;
    slot = (_slot & C.CLEAR_MASK_PAIR_U112) | (word0U112 << 112) | word1U112;
  }

  /// @notice Unpacks and returns the specified 128-bit values, word0 or word1, from the provided slot,
  ///         depending on the value of isWord0.
  /// @dev    See the section on Pairs in the notes on Conventions to understand how the two
  ///         words are stored within the provided slot.
  /// @param _slot A 256-bit container holding two 128-bit words, word0 and word1.
  /// @param _isWord0 Instructs this method to unpack the upper 128-bits corresponding to word0 when true.
  ///                 Otherwise the lower 128-bits, word1 are unpacked.
  /// @return wordU128 The value of word0.
  ///                  Min. = 0, Max. = (2**128)-1.
  ///
  function unpackU128(uint256 _slot, bool _isWord0) internal pure returns (uint256 wordU128) {
    wordU128 = _isWord0 ? _slot >> 128 : _slot & C.MAX_U128;
  }

  /// @notice Packs the two provided 128-bit words, word0 and word1, into a 256-bit slot.
  /// @dev    See the section on Pairs in the notes on Conventions to understand how the two
  ///         words are stored within the slot.
  /// @param _word0U128 The value of word0 to pack.
  ///                   Min. = 0, Max. = (2**128)-1.
  /// @param _word1U128 The value of word1 to pack.
  ///                   Min. = 0, Max. = (2**128)-1.
  /// @return slot A slot containing the 128-bit values word0 and word1.
  ///
  function packPairU128(uint256 _word0U128, uint256 _word1U128) internal pure returns (uint256 slot) {
    requireErrCode(_word0U128 <= C.MAX_U128, CronErrors.VALUE_EXCEEDS_CONTAINER_SZ);
    requireErrCode(_word1U128 <= C.MAX_U128, CronErrors.VALUE_EXCEEDS_CONTAINER_SZ);

    slot = (_word0U128 << 128) | _word1U128;
  }

  /// @notice Unpacks and returns the two 128-bit values, word0 and word1, from the provided slot.
  /// @dev    See the section on Pairs in the notes on Conventions to understand how the two
  ///         words are stored within the provided slot.
  /// @param _slot A 256-bit container holding two 128-bit words, word0 and word1.
  /// @return word0U128 The value of word0.
  ///                   Min. = 0, Max. = (2**128)-1.
  /// @return word1U128 The value of word1.
  ///                   Min. = 0, Max. = (2**128)-1.
  ///
  function unpackPairU128(uint256 _slot) internal pure returns (uint256 word0U128, uint256 word1U128) {
    word0U128 = _slot >> 128;
    word1U128 = _slot & C.MAX_U128;
  }

  //
  // Slot 2 Specific Packing Functions
  ////////////////////////////////////////////////////////////////////////////////

  /// @notice Packs the 32-bit oracle time stamp, _oracleTimeStampU32, into the provided 256-bit slot.
  /// @param _slot A 256-bit container to pack the oracle time stamp within.
  /// @param _oracleTimeStampU32 The 32-bit oracle time stamp.
  ///                            Min. = 0, Max. = (2**32)-1.
  /// @return slot The modified slot containing the oracle time stamp.
  ///
  function packOracleTimeStampS2(uint256 _slot, uint256 _oracleTimeStampU32) internal pure returns (uint256 slot) {
    requireErrCode(_oracleTimeStampU32 <= C.MAX_U32, CronErrors.VALUE_EXCEEDS_CONTAINER_SZ);

    uint256 setMask = _oracleTimeStampU32 << C.S2_OFFSET_ORACLE_TIMESTAMP;
    slot = (_slot & C.CLEAR_MASK_ORACLE_TIMESTAMP) | setMask;
  }

  /// @notice Unpacks the 32-bit oracle time stamp, oracleTimeStampU32, from the provided 256-bit slot,
  /// @param _slot A 256-bit container to unpack the oracle time stamp from.
  /// @return oracleTimeStampU32 The 32-bit oracle time stamp.
  ///                            Min. = 0, Max. = (2**32)-1.
  function unpackOracleTimeStampS2(uint256 _slot) internal pure returns (uint256 oracleTimeStampU32) {
    oracleTimeStampU32 = (_slot >> C.S2_OFFSET_ORACLE_TIMESTAMP) & C.MAX_U32;
  }

  //
  // Slot 3 Specific Packing Functions
  ////////////////////////////////////////////////////////////////////////////////

  /// @notice Packs the 3-bit fee shift, _feeShiftU3, into the provided 256-bit slot.
  /// @param _slot A 256-bit container to pack the fee shift into.
  /// @param _feeShiftU3 The 3-bit fee shift.
  ///                    Min. = 0, Max. = 7.
  /// @return slot The modified slot containing the new fee shift value.
  ///
  function packFeeShiftS3(uint256 _slot, uint256 _feeShiftU3) internal pure returns (uint256 slot) {
    requireErrCode(_feeShiftU3 <= C.MAX_U3, CronErrors.VALUE_EXCEEDS_CONTAINER_SZ);

    uint256 setMask = _feeShiftU3 << C.S3_OFFSET_FEE_SHIFT_U3;
    slot = (_slot & C.CLEAR_MASK_FEE_SHIFT) | setMask;
  }

  /// @notice Unpacks the 3-bit fee shift, feeShiftU3, from the provided 256-bit slot,
  /// @param _slot A 256-bit container to unpack the fee shift from.
  /// @return feeShiftU3 The 3-bit fee shift.
  ///                    Min. = 0, Max. = 7.
  function unpackFeeShiftS3(uint256 _slot) internal pure returns (uint256 feeShiftU3) {
    feeShiftU3 = (_slot >> C.S3_OFFSET_FEE_SHIFT_U3) & C.MAX_U3;
  }

  //
  // Slot 4 Specific Packing Functions
  ////////////////////////////////////////////////////////////////////////////////

  /// @notice Packs the balancer fee, _balancerFeeDU1F18, into the provided 256-bit slot.
  /// @param _slot A 256-bit container to pack the balancer fee into.
  /// @param _balancerFeeDU1F18 The balancer fee representing a 19 decimal digit
  ///                           value with 18 fractional digits, NOT TO EXCEED 10**19.
  ///                           Min. = 0, Max. = 10**19.
  /// @return slot The modified slot containing the new balancer fee value.
  ///
  function packBalancerFeeS4(uint256 _slot, uint256 _balancerFeeDU1F18) internal pure returns (uint256 slot) {
    requireErrCode(_balancerFeeDU1F18 <= C.MAX_U60, CronErrors.VALUE_EXCEEDS_CONTAINER_SZ);

    uint256 setMask = _balancerFeeDU1F18 << C.S4_OFFSET_BALANCER_FEE;
    slot = (_slot & C.CLEAR_MASK_BALANCER_FEE) | setMask;
  }

  /// @notice Unpacks the 60-bit balancer fee representation, balancerFeeDU1F18, from the
  ///         provided 256-bit slot,
  /// @param _slot A 256-bit container to unpack the balancer fee from.
  /// @return balancerFeeDU1F18 The 60-bit balancer fee representing a 19 decimal digit value
  ///                           with 18 fractional digits.
  ///                           Min. = 0, Max. = (2**60)-1.
  function unpackBalancerFeeS4(uint256 _slot) internal pure returns (uint256 balancerFeeDU1F18) {
    balancerFeeDU1F18 = (_slot >> C.S4_OFFSET_BALANCER_FEE) & C.MAX_U60;
  }
}