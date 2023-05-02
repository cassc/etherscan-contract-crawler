// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import "./LibMemCpy.sol";

/// Thrown if a truncated length is longer than the array being truncated. It is
/// not possible to truncate something and increase its length as the memory
/// region after the array MAY be allocated for something else already.
error OutOfBoundsTruncate(uint256 arrayLength, uint256 truncatedLength);

/// @title Uint256Array
/// @notice Things we want to do carefully and efficiently with uint256 arrays
/// that Solidity doesn't give us native tools for.
library LibUint256Array {
    using LibUint256Array for uint256[];

    /// Pointer to the data of a bytes array NOT the length prefix.
    function dataPointer(uint256[] memory data_) internal pure returns (Pointer pointer_) {
        assembly ("memory-safe") {
            pointer_ := add(data_, 0x20)
        }
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a_ a single integer to build an array around.
    /// @return the newly allocated array including a_ as a single item.
    function arrayFrom(uint256 a_) internal pure returns (uint256[] memory) {
        uint256[] memory array_ = new uint256[](1);
        assembly ("memory-safe") {
            mstore(add(array_, 0x20), a_)
        }
        return array_;
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a_ the first integer to build an array around.
    /// @param b_ the second integer to build an array around.
    /// @return the newly allocated array including a_ and b_ as the only items.
    function arrayFrom(uint256 a_, uint256 b_) internal pure returns (uint256[] memory) {
        uint256[] memory array_ = new uint256[](2);
        assembly ("memory-safe") {
            mstore(add(array_, 0x20), a_)
            mstore(add(array_, 0x40), b_)
        }
        return array_;
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a_ the first integer to build an array around.
    /// @param b_ the second integer to build an array around.
    /// @param c_ the third integer to build an array around.
    /// @return the newly allocated array including a_, b_ and c_ as the only
    /// items.
    function arrayFrom(uint256 a_, uint256 b_, uint256 c_) internal pure returns (uint256[] memory) {
        uint256[] memory array_ = new uint256[](3);
        assembly ("memory-safe") {
            mstore(add(array_, 0x20), a_)
            mstore(add(array_, 0x40), b_)
            mstore(add(array_, 0x60), c_)
        }
        return array_;
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a_ the first integer to build an array around.
    /// @param b_ the second integer to build an array around.
    /// @param c_ the third integer to build an array around.
    /// @param d_ the fourth integer to build an array around.
    /// @return the newly allocated array including a_, b_, c_ and d_ as the only
    /// items.
    function arrayFrom(uint256 a_, uint256 b_, uint256 c_, uint256 d_) internal pure returns (uint256[] memory) {
        uint256[] memory array_ = new uint256[](4);
        assembly ("memory-safe") {
            mstore(add(array_, 0x20), a_)
            mstore(add(array_, 0x40), b_)
            mstore(add(array_, 0x60), c_)
            mstore(add(array_, 0x80), d_)
        }
        return array_;
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a_ the first integer to build an array around.
    /// @param b_ the second integer to build an array around.
    /// @param c_ the third integer to build an array around.
    /// @param d_ the fourth integer to build an array around.
    /// @param e_ the fifth integer to build an array around.
    /// @return the newly allocated array including a_, b_, c_, d_ and e_ as the
    /// only items.
    function arrayFrom(uint256 a_, uint256 b_, uint256 c_, uint256 d_, uint256 e_)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array_ = new uint256[](5);
        assembly ("memory-safe") {
            mstore(add(array_, 0x20), a_)
            mstore(add(array_, 0x40), b_)
            mstore(add(array_, 0x60), c_)
            mstore(add(array_, 0x80), d_)
            mstore(add(array_, 0xA0), e_)
        }
        return array_;
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a_ the first integer to build an array around.
    /// @param b_ the second integer to build an array around.
    /// @param c_ the third integer to build an array around.
    /// @param d_ the fourth integer to build an array around.
    /// @param e_ the fifth integer to build an array around.
    /// @param f_ the sixth integer to build an array around.
    /// @return the newly allocated array including a_, b_, c_, d_, e_ and f_ as
    /// the only items.
    function arrayFrom(uint256 a_, uint256 b_, uint256 c_, uint256 d_, uint256 e_, uint256 f_)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array_ = new uint256[](6);
        assembly ("memory-safe") {
            mstore(add(array_, 0x20), a_)
            mstore(add(array_, 0x40), b_)
            mstore(add(array_, 0x60), c_)
            mstore(add(array_, 0x80), d_)
            mstore(add(array_, 0xA0), e_)
            mstore(add(array_, 0xC0), f_)
        }
        return array_;
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a_ The head of the new array.
    /// @param tail_ The tail of the new array.
    /// @return The new array.
    function arrayFrom(uint256 a_, uint256[] memory tail_) internal pure returns (uint256[] memory) {
        uint256[] memory array_;
        assembly ("memory-safe") {
            let length_ := add(mload(tail_), 1)
            let outputCursor_ := mload(0x40)
            array_ := outputCursor_
            let outputEnd_ := add(outputCursor_, add(0x20, mul(length_, 0x20)))
            mstore(0x40, outputEnd_)

            mstore(outputCursor_, length_)
            mstore(add(outputCursor_, 0x20), a_)

            for {
                outputCursor_ := add(outputCursor_, 0x40)
                let inputCursor_ := add(tail_, 0x20)
            } lt(outputCursor_, outputEnd_) {
                outputCursor_ := add(outputCursor_, 0x20)
                inputCursor_ := add(inputCursor_, 0x20)
            } { mstore(outputCursor_, mload(inputCursor_)) }
        }
        return array_;
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a_ The first item of the new array.
    /// @param b_ The second item of the new array.
    /// @param tail_ The tail of the new array.
    /// @return The new array.
    function arrayFrom(uint256 a_, uint256 b_, uint256[] memory tail_) internal pure returns (uint256[] memory) {
        uint256[] memory array_;
        assembly ("memory-safe") {
            let length_ := add(mload(tail_), 2)
            let outputCursor_ := mload(0x40)
            array_ := outputCursor_
            let outputEnd_ := add(outputCursor_, add(0x20, mul(length_, 0x20)))
            mstore(0x40, outputEnd_)

            mstore(outputCursor_, length_)
            mstore(add(outputCursor_, 0x20), a_)
            mstore(add(outputCursor_, 0x40), b_)

            for {
                outputCursor_ := add(outputCursor_, 0x60)
                let inputCursor_ := add(tail_, 0x20)
            } lt(outputCursor_, outputEnd_) {
                outputCursor_ := add(outputCursor_, 0x20)
                inputCursor_ := add(inputCursor_, 0x20)
            } { mstore(outputCursor_, mload(inputCursor_)) }
        }
        return array_;
    }

    /// Solidity provides no way to change the length of in-memory arrays but
    /// it also does not deallocate memory ever. It is always safe to shrink an
    /// array that has already been allocated, with the caveat that the
    /// truncated items will effectively become inaccessible regions of memory.
    /// That is to say, we deliberately "leak" the truncated items, but that is
    /// no worse than Solidity's native behaviour of leaking everything always.
    /// The array is MUTATED in place so there is no return value and there is
    /// no new allocation or copying of data either.
    /// @param array_ The array to truncate.
    /// @param newLength_ The new length of the array after truncation.
    function truncate(uint256[] memory array_, uint256 newLength_) internal pure {
        if (newLength_ > array_.length) {
            revert OutOfBoundsTruncate(array_.length, newLength_);
        }
        assembly ("memory-safe") {
            mstore(array_, newLength_)
        }
    }

    /// Extends `base_` with `extend_` by allocating only an additional
    /// `extend_.length` words onto `base_` and copying only `extend_` if
    /// possible. If `base_` is large this MAY be significantly more efficient
    /// than allocating `base_.length + extend_.length` for an entirely new array
    /// and copying both `base_` and `extend_` into the new array one item at a
    /// time in Solidity.
    ///
    /// The efficient version of extension is only possible if the free memory
    /// pointer sits at the end of the base array at the moment of extension. If
    /// there is allocated memory after the end of base then extension will
    /// require copying both the base and extend arays to a new region of memory.
    /// The caller is responsible for optimising code paths to avoid additional
    /// allocations.
    ///
    /// This function is UNSAFE because the base array IS MUTATED DIRECTLY by
    /// some code paths AND THE FINAL RETURN ARRAY MAY POINT TO THE SAME REGION
    /// OF MEMORY. It is NOT POSSIBLE to reliably see this behaviour from the
    /// caller in all cases as the Solidity compiler optimisations may switch the
    /// caller between the allocating and non-allocating logic due to subtle
    /// optimisation reasons. To use this function safely THE CALLER MUST NOT USE
    /// THE BASE ARRAY AND MUST USE THE RETURNED ARRAY ONLY. It is safe to use
    /// the extend array after calling this function as it is never mutated, it
    /// is only copied from.
    ///
    /// @param b_ The base integer array that will be extended by `extend_`.
    /// @param e_ The extend integer array that extends `base_`.
    function unsafeExtend(uint256[] memory b_, uint256[] memory e_) internal pure returns (uint256[] memory final_) {
        assembly ("memory-safe") {
            // Slither doesn't recognise assembly function names as mixed case
            // even if they are.
            // https://github.com/crytic/slither/issues/1815
            //slither-disable-next-line naming-convention
            function extendInline(base_, extend_) -> baseAfter_ {
                let outputCursor_ := mload(0x40)
                let baseLength_ := mload(base_)
                let baseEnd_ := add(base_, add(0x20, mul(baseLength_, 0x20)))

                // If base is NOT the last thing in allocated memory, allocate,
                // copy and recurse.
                switch eq(outputCursor_, baseEnd_)
                case 0 {
                    let newBase_ := outputCursor_
                    let newBaseEnd_ := add(newBase_, sub(baseEnd_, base_))
                    mstore(0x40, newBaseEnd_)
                    // mstore(newBase_, baseLength_)
                    for { let inputCursor_ := base_ } lt(outputCursor_, newBaseEnd_) {
                        inputCursor_ := add(inputCursor_, 0x20)
                        outputCursor_ := add(outputCursor_, 0x20)
                    } { mstore(outputCursor_, mload(inputCursor_)) }

                    baseAfter_ := extendInline(newBase_, extend_)
                }
                case 1 {
                    let totalLength_ := add(baseLength_, mload(extend_))
                    let outputEnd_ := add(base_, add(0x20, mul(totalLength_, 0x20)))
                    mstore(base_, totalLength_)
                    mstore(0x40, outputEnd_)
                    for { let inputCursor_ := add(extend_, 0x20) } lt(outputCursor_, outputEnd_) {
                        inputCursor_ := add(inputCursor_, 0x20)
                        outputCursor_ := add(outputCursor_, 0x20)
                    } { mstore(outputCursor_, mload(inputCursor_)) }

                    baseAfter_ := base_
                }
            }

            final_ := extendInline(b_, e_)
        }
    }
}