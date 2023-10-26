// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IScribe} from "../IScribe.sol";

import {LibBytes} from "./LibBytes.sol";

/**
 * @title LibSchnorrData
 *
 * @notice Library for working with IScribe.SchnorrData
 */
library LibSchnorrData {
    using LibBytes for uint;

    /// @dev Size of a word is 32 bytes, i.e. 256 bits.
    uint private constant WORD_SIZE = 32;

    /// @dev Returns the signer index from schnorrData.signersBlob with index
    ///      `index`.
    ///
    /// @dev Note that schnorrData.signersBlob is big-endian encoded and
    ///      counting starts at the highest order byte, i.e. the signer index 0
    ///      is the highest order byte of schnorrData.signersBlob.
    ///
    /// @custom:example SignersBlob encoding via Solidity:
    ///
    ///      ```solidity
    ///      bytes memory signersBlob;
    ///      uint8[] memory indexes = someFuncReturningUint8Array();
    ///      for (uint i; i < indexes.length; i++) {
    ///          signersBlob = abi.encodePacked(signersBlob, indexes[i]);
    ///      }
    ///      ```
    ///
    /// @dev Calldata layout for `schnorrData`:
    ///
    ///      [schnorrData]        signature             -> schnorrData.signature
    ///      [schnorrData + 0x20] commitment            -> schnorrData.commitment
    ///      [schnorrData + 0x40] offset(signersBlob)
    ///      [schnorrData + 0x60] len(signersBlob)      -> schnorrData.signersBlob.length
    ///      [schnorrData + 0x80] signersBlob[0]        -> schnorrData.signersBlob[0]
    ///      ...
    ///
    ///      Note that the `schnorrData` variable holds the offset to the
    ///      `schnorrData` struct:
    ///
    ///      ```solidity
    ///      bytes32 signature;
    ///      assembly {
    ///         signature := calldataload(schnorrData)
    ///      }
    ///      assert(signature == schnorrData.signature)
    ///      ```
    ///
    ///      Note that `offset(signersBlob)` is the offset to `signersBlob[0]`
    ///      from the index `offset(signersBlob)`.
    ///
    /// @custom:invariant Reverts iff out of gas.
    function getSignerIndex(
        IScribe.SchnorrData calldata schnorrData,
        uint index
    ) internal pure returns (uint) {
        uint word;
        assembly ("memory-safe") {
            let wordIndex := mul(div(index, WORD_SIZE), WORD_SIZE)

            // Calldata index for schnorrData.signersBlob[0] is schnorrData's
            // offset plus 4 words, i.e. 0x80.
            let start := add(schnorrData, 0x80)

            // Note that reading non-existing calldata returns zero.
            // Note that overflow is no concern because index's upper limit is
            // bounded by bar, which is of type uint8.
            word := calldataload(add(start, wordIndex))
        }

        // Unchecked because the subtrahend is guaranteed to be less than or
        // equal to 31 due to being a (mod 32) result.
        uint byteIndex;
        unchecked {
            byteIndex = 31 - (index % WORD_SIZE);
        }

        return word.getByteAtIndex(byteIndex);
    }

    /// @dev Returns the number of signers encoded in schnorrData.signersBlob.
    function getSignerIndexLength(IScribe.SchnorrData calldata schnorrData)
        internal
        pure
        returns (uint)
    {
        uint index;
        assembly ("memory-safe") {
            // Calldata index for schnorrData.signersBlob.length is
            // schnorrData's offset plus 3 words, i.e. 0x60.
            index := calldataload(add(schnorrData, 0x60))
        }
        return index;
    }
}