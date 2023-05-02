// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "rain.interface.interpreter/IInterpreterV1.sol";
import "sol.lib.memory/LibUint256Array.sol";
import "sol.lib.memory/LibMemory.sol";
import "sol.lib.memory/LibMemCpy.sol";

/// Thrown when the length of an array as the result of an applied function does
/// not match expectations.
error UnexpectedResultLength(uint256 expectedLength, uint256 actualLength);

/// Custom type to point to memory ostensibly in a stack.
type StackPointer is uint256;

/// @title LibStackPointer
/// @notice A `StackPointer` is just a pointer to some memory. Ostensibly it is
/// pointing at a stack item in memory used by the `RainInterpreter` so that
/// means it can move "up" and "down" (increment and decrement) by `uint256`
/// (32 bytes) increments. Structurally a stack is a `uint256[]` but we can save
/// a lot of gas vs. default Solidity handling of array indexes by using assembly
/// to bypass runtime bounds checks on every read and write. Of course, this
/// means we have to introduce some mechanism that gives us equivalent guarantees
/// and we do, in the form of the `IExpressionDeployerV1` integrity check.
///
/// The pointer to the bottom of a stack points at the 0th item, NOT the length
/// of the implied `uint256[]` and the top of a stack points AFTER the last item.
/// e.g. consider a `uint256[]` in memory with values `3 A B C` and assume this
/// starts at position `0` in memory, i.e. `0` points to value `3` for the
/// array length. In this case the stack bottom would be
/// `StackPointer.wrap(0x20)` (32 bytes above 0, past the length) and the stack
/// top would be `StackPointer.wrap(0x80)` (96 bytes above the stack bottom).
///
/// Most of the functions in this library are equivalent to each other via
/// composition, i.e. everything could be achieved with just `up`, `down`,
/// `pop`, `push`, `peek`. The reason there is so much overloaded/duplicated
/// logic is that the Solidity compiler seems to fail at inlining equivalent
/// logic quite a lot. Perhaps once the IR compilation of Solidity is better
/// supported by tooling etc. we could remove a lot of this duplication as the
/// compiler itself would handle the optimisations.
library LibStackPointer {
    using LibStackPointer for StackPointer;
    using LibStackPointer for uint256[];
    using LibStackPointer for bytes;
    using LibUint256Array for uint256[];
    using LibMemory for uint256;

    /// Reads the value above the stack pointer. If the stack pointer is the
    /// current stack top this is an out of bounds read! The caller MUST ensure
    /// that this is not the case and that the stack pointer being read is within
    /// the stack and not after it.
    /// @param stackPointer_ Position to read past/above.
    function peekUp(
        StackPointer stackPointer_
    ) internal pure returns (uint256) {
        uint256 a_;
        assembly ("memory-safe") {
            a_ := mload(stackPointer_)
        }
        return a_;
    }

    /// Read the value immediately below the given stack pointer. Equivalent to
    /// calling `pop` and discarding the `stackPointerAfter_` value, so may be
    /// less gas than setting and discarding a value.
    /// @param stackPointer_ The stack pointer to read below.
    /// @return a_ The value that was read.
    function peek(StackPointer stackPointer_) internal pure returns (uint256) {
        uint256 a_;
        assembly ("memory-safe") {
            a_ := mload(sub(stackPointer_, 0x20))
        }
        return a_;
    }

    /// Reads 2 values below the given stack pointer.
    /// The following statements are equivalent but A may use gas if the
    /// compiler fails to inline some function calls.
    /// A:
    /// ```
    /// (uint256 a_, uint256 b_) = stackPointer_.peek2();
    /// ```
    /// B:
    /// ```
    /// uint256 b_;
    /// (stackPointer_, b_) = stackPointer_.pop();
    /// uint256 a_ = stackPointer_.peek();
    /// ```
    /// @param stackPointer_ The stack top to peek below.
    function peek2(
        StackPointer stackPointer_
    ) internal pure returns (uint256, uint256) {
        uint256 a_;
        uint256 b_;
        assembly ("memory-safe") {
            a_ := mload(sub(stackPointer_, 0x40))
            b_ := mload(sub(stackPointer_, 0x20))
        }
        return (a_, b_);
    }

    /// Read the value immediately below the given stack pointer and return the
    /// stack pointer that points to the value that was read alongside the value.
    /// The following are equivalent but A may be cheaper if the compiler
    /// fails to inline some function calls:
    /// A:
    /// ```
    /// uint256 a_;
    /// (stackPointer_, a_) = stackPointer_.pop();
    /// ```
    /// B:
    /// ```
    /// stackPointer_ = stackPointer_.down();
    /// uint256 a_ = stackPointer_.peekUp();
    /// ```
    /// @param stackPointer_ The stack pointer to read below.
    /// @return stackPointerAfter_ Points to the value that was read.
    /// @return a_ The value that was read.
    function pop(
        StackPointer stackPointer_
    ) internal pure returns (StackPointer, uint256) {
        StackPointer stackPointerAfter_;
        uint256 a_;
        assembly ("memory-safe") {
            stackPointerAfter_ := sub(stackPointer_, 0x20)
            a_ := mload(stackPointerAfter_)
        }
        return (stackPointerAfter_, a_);
    }

    /// Given two stack pointers that bound a stack build an array of all values
    /// above the given sentinel value. The sentinel will be _replaced_ by the
    /// length of the array, allowing for efficient construction of a valid
    /// `uint256[]` without additional allocation or copying in memory. As the
    /// returned value is a `uint256[]` it can be treated as a substack and the
    /// same (or different) sentinel can be consumed many times to build many
    /// arrays from the main stack.
    ///
    /// As the sentinel is mutated in place into a length it is NOT safe to call
    /// this in a context where the stack is expected to be immutable.
    ///
    /// The sentinel MUST be chosen to have a negligible chance of colliding with
    /// a real value in the array, otherwise an intended array item will be
    /// interpreted as a sentinel and the array will be split into two slices.
    ///
    /// If the sentinel is absent in the stack this WILL REVERT. The intent is
    /// to represent dynamic length arrays without forcing expression authors to
    /// calculate lengths on the stack. If the expression author wants to model
    /// an empty/optional/absent value they MAY provided a sentinel for a zero
    /// length array and the calling contract SHOULD handle this.
    ///
    /// @param stackTop_ Pointer to the top of the stack.
    /// @param stackBottom_ Pointer to the bottom of the stack.
    /// @param sentinel_ The value to expect as the sentinel. MUST be present in
    /// the stack or `consumeSentinel` will revert. MUST NOT collide with valid
    /// stack items (or be cryptographically improbable to do so).
    /// @param stepSize_ Number of items to move over in the array per loop
    /// iteration. If the array has a known multiple of items it can be more
    /// efficient to find a sentinel moving in N-item increments rather than
    /// reading every item individually.
    function consumeSentinel(
        StackPointer stackTop_,
        StackPointer stackBottom_,
        uint256 sentinel_,
        uint256 stepSize_
    ) internal pure returns (StackPointer, uint256[] memory) {
        uint256[] memory array_;
        assembly ("memory-safe") {
            // Underflow is not allowed and pointing at position 0 in memory is
            // corrupt behaviour anyway.
            if iszero(stackBottom_) {
                revert(0, 0)
            }
            let sentinelLocation_ := 0
            let length_ := 0
            let step_ := mul(stepSize_, 0x20)
            for {
                stackTop_ := sub(stackTop_, 0x20)
                let end_ := sub(stackBottom_, 0x20)
            } gt(stackTop_, end_) {
                stackTop_ := sub(stackTop_, step_)
                length_ := add(length_, stepSize_)
            } {
                if eq(sentinel_, mload(stackTop_)) {
                    sentinelLocation_ := stackTop_
                    break
                }
            }
            // Sentinel MUST exist in the stack if consumer expects it to there.
            if iszero(sentinelLocation_) {
                revert(0, 0)
            }
            mstore(sentinelLocation_, length_)
            array_ := sentinelLocation_
        }
        return (stackTop_, array_);
    }

    /// Abstraction over `consumeSentinel` to build an array of solidity structs.
    /// Solidity won't exactly allow this due to its type system not supporting
    /// generics, so instead we return an array of references to struct data that
    /// can be assigned/cast to an array of structs easily with assembly. This
    /// is NOT intended to be a general purpose workhorse for this task, only
    /// structs of pointers to `uint256[]` values are supported.
    ///
    /// ```
    /// struct Foo {
    ///   uint256[] a;
    ///   uint256[] b;
    /// }
    ///
    /// (StackPointer stackPointer_, uint256[] memory refs_) = consumeStructs(...);
    /// Foo[] memory foo_;
    /// assembly ("memory-safe") {
    ///   mstore(foo_, refs_)
    /// }
    /// ```
    ///
    /// @param stackTop_ The top of the stack as per `consumeSentinel`.
    /// @param stackBottom_ The bottom of the stack as per `consumeSentinel`.
    /// @param sentinel_ The sentinel as per `consumeSentinel`.
    /// @param structSize_ The number of `uint256[]` fields on the struct.
    function consumeStructs(
        StackPointer stackTop_,
        StackPointer stackBottom_,
        uint256 sentinel_,
        uint256 structSize_
    ) internal pure returns (StackPointer, uint256[] memory) {
        (StackPointer stackTopAfter_, uint256[] memory tempArray_) = stackTop_
            .consumeSentinel(stackBottom_, sentinel_, structSize_);
        uint256 structsLength_ = tempArray_.length / structSize_;
        uint256[] memory refs_ = new uint256[](structsLength_);
        assembly ("memory-safe") {
            for {
                let refCursor_ := add(refs_, 0x20)
                let refEnd_ := add(refCursor_, mul(mload(refs_), 0x20))
                let tempCursor_ := add(tempArray_, 0x20)
                let tempStepSize_ := mul(structSize_, 0x20)
            } lt(refCursor_, refEnd_) {
                refCursor_ := add(refCursor_, 0x20)
                tempCursor_ := add(tempCursor_, tempStepSize_)
            } {
                mstore(refCursor_, tempCursor_)
            }
        }
        return (stackTopAfter_, refs_);
    }

    /// Write a value at the stack pointer. Typically only useful as intermediate
    /// logic within some opcode etc. as the value will be treated as an out of
    /// bounds for future reads unless the stack top after the opcode logic is
    /// above the pointer.
    /// @param stackPointer_ The stack top to write the value at.
    /// @param a_ The value to write.
    function set(StackPointer stackPointer_, uint256 a_) internal pure {
        assembly ("memory-safe") {
            mstore(stackPointer_, a_)
        }
    }

    /// Store a `uint256` at the stack pointer and return the stack pointer
    /// above the written value. The following statements are equivalent in
    /// functionality but A may be less gas if the compiler fails to inline
    /// some function calls.
    /// A:
    /// ```
    /// stackPointer_ = stackPointer_.push(a_);
    /// ```
    /// B:
    /// ```
    /// stackPointer_.set(a_);
    /// stackPointer_ = stackPointer_.up();
    /// ```
    /// @param stackPointer_ The stack pointer to write at.
    /// @param a_ The value to write.
    /// @return The stack pointer above where `a_` was written to.
    function push(
        StackPointer stackPointer_,
        uint256 a_
    ) internal pure returns (StackPointer) {
        assembly ("memory-safe") {
            mstore(stackPointer_, a_)
            stackPointer_ := add(stackPointer_, 0x20)
        }
        return stackPointer_;
    }

    /// Store a `uint256[]` at the stack pointer and return the stack pointer
    /// above the written values. The length of the array is NOT written to the
    /// stack, ONLY the array values are copied to the stack. The following
    /// statements are equivalent in functionality but A may be less gas if the
    /// compiler fails to inline some function calls.
    /// A:
    /// ```
    /// stackPointer_ = stackPointer_.push(array_);
    /// ```
    /// B:
    /// ```
    /// unchecked {
    ///   for (uint256 i_ = 0; i_ < array_.length; i_++) {
    ///     stackPointer_ = stackPointer_.push(array_[i_]);
    ///   }
    /// }
    /// ```
    /// @param stackPointer_ The stack pointer to write at.
    /// @param array_ The array of values to write.
    /// @return The stack pointer above the array.
    function push(
        StackPointer stackPointer_,
        uint256[] memory array_
    ) internal pure returns (StackPointer) {
        LibMemCpy.unsafeCopyWordsTo(
            array_.dataPointer(),
            Pointer.wrap(StackPointer.unwrap(stackPointer_)),
            array_.length
        );
        return stackPointer_.up(array_.length);
    }

    /// Store a `uint256[]` at the stack pointer and return the stack pointer
    /// above the written values. The length of the array IS written to the
    /// stack.
    /// @param stackPointer_ The stack pointer to write at.
    /// @param array_ The array of values and length to write.
    /// @return The stack pointer above the array.
    function pushWithLength(
        StackPointer stackPointer_,
        uint256[] memory array_
    ) internal pure returns (StackPointer) {
        return stackPointer_.push(array_.length).push(array_);
    }

    /// Store `bytes` at the stack pointer and return the stack pointer above
    /// the written bytes. The length of the bytes is NOT written to the stack,
    /// ONLY the bytes are written. As `bytes` may be of arbitrary length, i.e.
    /// it MAY NOT be a multiple of 32, the push is unaligned. The caller MUST
    /// ensure that this is safe in context of subsequent reads and writes.
    /// @param stackPointer_ The stack top to write at.
    /// @param bytes_ The bytes to write at the stack top.
    /// @return The stack top above the written bytes.
    function unalignedPush(
        StackPointer stackPointer_,
        bytes memory bytes_
    ) internal pure returns (StackPointer) {
        LibMemCpy.unsafeCopyBytesTo(
            Pointer.wrap(StackPointer.unwrap(bytes_.asStackPointer().up())),
            Pointer.wrap(StackPointer.unwrap(stackPointer_)),
            bytes_.length
        );
        return stackPointer_.upBytes(bytes_.length);
    }

    /// Store `bytes` at the stack pointer and return the stack top above the
    /// written bytes. The length of the bytes IS written to the stack in
    /// addition to the bytes. As `bytes` may be of arbitrary length, i.e. it
    /// MAY NOT be a multiple of 32, the push is unaligned. The caller MUST
    /// ensure that this is safe in context of subsequent reads and writes.
    /// @param stackPointer_ The stack pointer to write at.
    /// @param bytes_ The bytes to write with their length at the stack pointer.
    /// @return The stack pointer above the written bytes.
    function unalignedPushWithLength(
        StackPointer stackPointer_,
        bytes memory bytes_
    ) internal pure returns (StackPointer) {
        return stackPointer_.push(bytes_.length).unalignedPush(bytes_);
    }

    /// Store 8x `uint256` at the stack pointer and return the stack pointer
    /// above the written value. The following statements are equivalent in
    /// functionality but A may be cheaper if the compiler fails to
    /// inline some function calls.
    /// A:
    /// ```
    /// stackPointer_ = stackPointer_.push(a_, b_, c_, d_, e_, f_, g_, h_);
    /// ```
    /// B:
    /// ```
    /// stackPointer_ = stackPointer_
    ///   .push(a_)
    ///   .push(b_)
    ///   .push(c_)
    ///   .push(d_)
    ///   .push(e_)
    ///   .push(f_)
    ///   .push(g_)
    ///   .push(h_);
    /// @param stackPointer_ The stack pointer to write at.
    /// @param a_ The first value to write.
    /// @param b_ The second value to write.
    /// @param c_ The third value to write.
    /// @param d_ The fourth value to write.
    /// @param e_ The fifth value to write.
    /// @param f_ The sixth value to write.
    /// @param g_ The seventh value to write.
    /// @param h_ The eighth value to write.
    /// @return The stack pointer above where `h_` was written.
    function push(
        StackPointer stackPointer_,
        uint256 a_,
        uint256 b_,
        uint256 c_,
        uint256 d_,
        uint256 e_,
        uint256 f_,
        uint256 g_,
        uint256 h_
    ) internal pure returns (StackPointer) {
        assembly ("memory-safe") {
            mstore(stackPointer_, a_)
            mstore(add(stackPointer_, 0x20), b_)
            mstore(add(stackPointer_, 0x40), c_)
            mstore(add(stackPointer_, 0x60), d_)
            mstore(add(stackPointer_, 0x80), e_)
            mstore(add(stackPointer_, 0xA0), f_)
            mstore(add(stackPointer_, 0xC0), g_)
            mstore(add(stackPointer_, 0xE0), h_)
            stackPointer_ := add(stackPointer_, 0x100)
        }
        return stackPointer_;
    }

    /// Execute a function, reading and writing inputs and outputs on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @return The new stack top above the outputs of fn_.
    function applyFn(
        StackPointer stackTop_,
        function(uint256) internal view returns (uint256) fn_
    ) internal view returns (StackPointer) {
        uint256 a_;
        uint256 location_;
        assembly ("memory-safe") {
            location_ := sub(stackTop_, 0x20)
            a_ := mload(location_)
        }
        a_ = fn_(a_);
        assembly ("memory-safe") {
            mstore(location_, a_)
        }
        return stackTop_;
    }

    /// Execute a function, reading and writing inputs and outputs on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @return The new stack top above the outputs of fn_.
    function applyFn(
        StackPointer stackTop_,
        function(Operand, uint256) internal view returns (uint256) fn_,
        Operand operand_
    ) internal view returns (StackPointer) {
        uint256 a_;
        uint256 location_;
        assembly ("memory-safe") {
            location_ := sub(stackTop_, 0x20)
            a_ := mload(location_)
        }
        a_ = fn_(operand_, a_);
        assembly ("memory-safe") {
            mstore(location_, a_)
        }
        return stackTop_;
    }

    /// Execute a function, reading and writing inputs and outputs on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @return The new stack top above the outputs of fn_.
    function applyFn(
        StackPointer stackTop_,
        function(uint256, uint256) internal view returns (uint256) fn_
    ) internal view returns (StackPointer) {
        uint256 a_;
        uint256 b_;
        uint256 location_;
        assembly ("memory-safe") {
            stackTop_ := sub(stackTop_, 0x20)
            location_ := sub(stackTop_, 0x20)
            a_ := mload(location_)
            b_ := mload(stackTop_)
        }
        a_ = fn_(a_, b_);
        assembly ("memory-safe") {
            mstore(location_, a_)
        }
        return stackTop_;
    }

    /// Reduce a function N times, reading and writing inputs and the accumulated
    /// result on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @param n_ The number of times to apply fn_ to accumulate a final result.
    /// @return stackTopAfter_ The new stack top above the outputs of fn_.
    function applyFnN(
        StackPointer stackTop_,
        function(uint256, uint256) internal view returns (uint256) fn_,
        uint256 n_
    ) internal view returns (StackPointer) {
        unchecked {
            uint256 bottom_;
            uint256 cursor_;
            uint256 a_;
            uint256 b_;
            StackPointer stackTopAfter_;
            assembly ("memory-safe") {
                bottom_ := sub(stackTop_, mul(n_, 0x20))
                a_ := mload(bottom_)
                stackTopAfter_ := add(bottom_, 0x20)
                cursor_ := stackTopAfter_
            }
            while (cursor_ < StackPointer.unwrap(stackTop_)) {
                assembly ("memory-safe") {
                    b_ := mload(cursor_)
                }
                a_ = fn_(a_, b_);
                cursor_ += 0x20;
            }
            assembly ("memory-safe") {
                mstore(bottom_, a_)
            }
            return stackTopAfter_;
        }
    }

    /// Reduce a function N times, reading and writing inputs and the accumulated
    /// result on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @param n_ The number of times to apply fn_ to accumulate a final result.
    /// @return stackTopAfter_ The new stack top above the outputs of fn_.
    function applyFnN(
        StackPointer stackTop_,
        function(uint256) internal view fn_,
        uint256 n_
    ) internal view returns (StackPointer) {
        uint256 cursor_;
        uint256 a_;
        StackPointer stackTopAfter_;
        assembly ("memory-safe") {
            stackTopAfter_ := sub(stackTop_, mul(n_, 0x20))
            cursor_ := stackTopAfter_
        }
        while (cursor_ < StackPointer.unwrap(stackTop_)) {
            assembly ("memory-safe") {
                a_ := mload(cursor_)
                cursor_ := add(cursor_, 0x20)
            }
            fn_(a_);
        }
        return stackTopAfter_;
    }

    /// Execute a function, reading and writing inputs and outputs on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @return The new stack top above the outputs of fn_.
    function applyFn(
        StackPointer stackTop_,
        function(uint256, uint256, uint256) internal view returns (uint256) fn_
    ) internal view returns (StackPointer) {
        uint256 a_;
        uint256 b_;
        uint256 c_;
        uint256 location_;
        assembly ("memory-safe") {
            stackTop_ := sub(stackTop_, 0x40)
            location_ := sub(stackTop_, 0x20)
            a_ := mload(location_)
            b_ := mload(stackTop_)
            c_ := mload(add(stackTop_, 0x20))
        }
        a_ = fn_(a_, b_, c_);
        assembly ("memory-safe") {
            mstore(location_, a_)
        }
        return stackTop_;
    }

    /// Execute a function, reading and writing inputs and outputs on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @return The new stack top above the outputs of fn_.
    function applyFn(
        StackPointer stackTop_,
        function(uint256, uint256, uint256, uint256)
            internal
            view
            returns (uint256) fn_
    ) internal view returns (StackPointer) {
        uint256 a_;
        uint256 b_;
        uint256 c_;
        uint256 d_;
        uint256 location_;
        assembly ("memory-safe") {
            stackTop_ := sub(stackTop_, 0x60)
            location_ := sub(stackTop_, 0x20)
            a_ := mload(location_)
            b_ := mload(stackTop_)
            c_ := mload(add(stackTop_, 0x20))
            d_ := mload(add(stackTop_, 0x40))
        }
        a_ = fn_(a_, b_, c_, d_);
        assembly ("memory-safe") {
            mstore(location_, a_)
        }
        return stackTop_;
    }

    /// Execute a function, reading and writing inputs and outputs on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @param operand_ Operand is passed from the source instead of the stack.
    /// @return The new stack top above the outputs of fn_.
    function applyFn(
        StackPointer stackTop_,
        function(Operand, uint256, uint256) internal view returns (uint256) fn_,
        Operand operand_
    ) internal view returns (StackPointer) {
        uint256 a_;
        uint256 b_;
        uint256 location_;
        assembly ("memory-safe") {
            stackTop_ := sub(stackTop_, 0x20)
            location_ := sub(stackTop_, 0x20)
            a_ := mload(location_)
            b_ := mload(stackTop_)
        }
        a_ = fn_(operand_, a_, b_);
        assembly ("memory-safe") {
            mstore(location_, a_)
        }
        return stackTop_;
    }

    /// Execute a function, reading and writing inputs and outputs on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @param length_ The length of the array to pass to fn_ from the stack.
    /// @return stackTopAfter_ The new stack top above the outputs of fn_.
    function applyFn(
        StackPointer stackTop_,
        function(uint256[] memory) internal view returns (uint256) fn_,
        uint256 length_
    ) internal view returns (StackPointer) {
        (uint256 a_, uint256[] memory tail_) = stackTop_.list(length_);
        uint256 b_ = fn_(tail_);
        return tail_.asStackPointer().push(a_).push(b_);
    }

    /// Execute a function, reading and writing inputs and outputs on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @param length_ The length of the array to pass to fn_ from the stack.
    /// @return stackTopAfter_ The new stack top above the outputs of fn_.
    function applyFn(
        StackPointer stackTop_,
        function(uint256, uint256, uint256[] memory)
            internal
            view
            returns (uint256) fn_,
        uint256 length_
    ) internal view returns (StackPointer) {
        (uint256 b_, uint256[] memory tail_) = stackTop_.list(length_);
        StackPointer stackTopAfter_ = tail_.asStackPointer();
        (StackPointer location_, uint256 a_) = stackTopAfter_.pop();
        location_.set(fn_(a_, b_, tail_));
        return stackTopAfter_;
    }

    /// Execute a function, reading and writing inputs and outputs on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @param length_ The length of the array to pass to fn_ from the stack.
    /// @return The new stack top above the outputs of fn_.
    function applyFn(
        StackPointer stackTop_,
        function(uint256, uint256, uint256, uint256[] memory)
            internal
            view
            returns (uint256) fn_,
        uint256 length_
    ) internal view returns (StackPointer) {
        (uint256 c_, uint256[] memory tail_) = stackTop_.list(length_);
        (StackPointer stackTopAfter_, uint256 b_) = tail_
            .asStackPointer()
            .pop();
        uint256 a_ = stackTopAfter_.peek();
        stackTopAfter_.down().set(fn_(a_, b_, c_, tail_));
        return stackTopAfter_;
    }

    /// Execute a function, reading and writing inputs and outputs on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @param length_ The length of the arrays to pass to fn_ from the stack.
    /// @return The new stack top above the outputs of fn_.
    function applyFn(
        StackPointer stackTop_,
        function(uint256, uint256[] memory, uint256[] memory)
            internal
            view
            returns (uint256[] memory) fn_,
        uint256 length_
    ) internal view returns (StackPointer) {
        StackPointer csStart_ = stackTop_.down(length_);
        uint256[] memory cs_ = new uint256[](length_);
        LibMemCpy.unsafeCopyWordsTo(
            Pointer.wrap(StackPointer.unwrap(csStart_)),
            cs_.dataPointer(),
            length_
        );
        (uint256 a_, uint256[] memory bs_) = csStart_.list(length_);

        uint256[] memory results_ = fn_(a_, bs_, cs_);
        if (results_.length != length_) {
            revert UnexpectedResultLength(length_, results_.length);
        }

        StackPointer bottom_ = bs_.asStackPointer();
        LibMemCpy.unsafeCopyWordsTo(
            results_.dataPointer(),
            Pointer.wrap(StackPointer.unwrap(bottom_)),
            length_
        );
        return bottom_.up(length_);
    }

    /// Returns `length_` values from the stack as an array without allocating
    /// new memory. As arrays always start with their length, this requires
    /// writing the length value to the stack below the array values. The value
    /// that is overwritten in the process is also returned so that data is not
    /// lost. For example, imagine a stack `[ A B C D ]` and we list 2 values.
    /// This will write the stack to look like `[ A 2 C D ]` and return both `B`
    /// and a pointer to `2` represented as a `uint256[]`.
    /// The returned array is ONLY valid for as long as the stack DOES NOT move
    /// back into its memory. As soon as the stack moves up again and writes into
    /// the array it will be corrupt. The caller MUST ensure that it does not
    /// read from the returned array after it has been corrupted by subsequent
    /// stack writes.
    /// @param stackPointer_ The stack pointer to read the values below into an
    /// array.
    /// @param length_ The number of values to include in the returned array.
    /// @return head_ The value that was overwritten with the length.
    /// @return tail_ The array constructed from the stack memory.
    function list(
        StackPointer stackPointer_,
        uint256 length_
    ) internal pure returns (uint256, uint256[] memory) {
        uint256 head_;
        uint256[] memory tail_;
        assembly ("memory-safe") {
            tail_ := sub(stackPointer_, add(0x20, mul(length_, 0x20)))
            head_ := mload(tail_)
            mstore(tail_, length_)
        }
        return (head_, tail_);
    }

    /// Cast a `uint256[]` array to a stack pointer. The stack pointer will
    /// point to the length of the array, NOT its first value.
    /// @param array_ The array to cast to a stack pointer.
    /// @return stackPointer_ The stack pointer that points to the length of the
    /// array.
    function asStackPointer(
        uint256[] memory array_
    ) internal pure returns (StackPointer) {
        StackPointer stackPointer_;
        assembly ("memory-safe") {
            stackPointer_ := array_
        }
        return stackPointer_;
    }

    /// Cast a stack pointer to an array. The value immediately above the stack
    /// pointer will be treated as the length of the array, so the proceeding
    /// length values will be the items of the array. The caller MUST ensure the
    /// values above the stack position constitute a valid array. The returned
    /// array will be corrupt if/when the stack subsequently moves into it and
    /// writes to those memory locations. The caller MUST ensure that it does
    /// NOT read from the returned array after the stack writes over it.
    /// @param stackPointer_ The stack pointer that will be cast to an array.
    /// @return array_ The array above the stack pointer.
    function asUint256Array(
        StackPointer stackPointer_
    ) internal pure returns (uint256[] memory) {
        uint256[] memory array_;
        assembly ("memory-safe") {
            array_ := stackPointer_
        }
        return array_;
    }

    /// Cast a stack position to bytes. The value immediately above the stack
    /// position will be treated as the length of the `bytes`, so the proceeding
    /// length bytes will be the data of the `bytes`. The caller MUST ensure the
    /// length and bytes above the stack top constitute valid `bytes` data. The
    /// returned `bytes` will be corrupt if/when the stack subsequently moves
    /// into it and writes to those memory locations. The caller MUST ensure
    // that it does NOT read from the returned bytes after the stack writes over
    /// it.
    /// @param stackPointer_ The stack pointer that will be cast to bytes.
    /// @return bytes_ The bytes above the stack top.
    function asBytes(
        StackPointer stackPointer_
    ) internal pure returns (bytes memory) {
        bytes memory bytes_;
        assembly ("memory-safe") {
            bytes_ := stackPointer_
        }
        return bytes_;
    }

    /// Cast a `uint256[]` array to a stack pointer after its length. The stack
    /// pointer will point to the first item of the array, NOT its length.
    /// @param array_ The array to cast to a stack pointer.
    /// @return stackPointer_ The stack pointer that points to the first item of
    /// the array.
    function asStackPointerUp(
        uint256[] memory array_
    ) internal pure returns (StackPointer) {
        StackPointer stackPointer_;
        assembly ("memory-safe") {
            stackPointer_ := add(array_, 0x20)
        }
        return stackPointer_;
    }

    /// Cast a `uint256[]` array to a stack pointer after its items. The stack
    /// pointer will point after the last item of the array. It is out of bounds
    /// to read above the returned pointer. This can be interpreted as the stack
    /// top assuming the entire given array is a valid stack.
    /// @param array_ The array to cast to a stack pointer.
    /// @return stackPointer_ The stack pointer that points after the last item
    /// of the array.
    function asStackPointerAfter(
        uint256[] memory array_
    ) internal pure returns (StackPointer) {
        StackPointer stackPointer_;
        assembly ("memory-safe") {
            stackPointer_ := add(array_, add(0x20, mul(mload(array_), 0x20)))
        }
        return stackPointer_;
    }

    /// Cast `bytes` to a stack pointer. The stack pointer will point to the
    /// length of the `bytes`, NOT the first byte.
    /// @param bytes_ The `bytes` to cast to a stack pointer.
    /// @return stackPointer_ The stack top that points to the length of the
    /// bytes.
    function asStackPointer(
        bytes memory bytes_
    ) internal pure returns (StackPointer) {
        StackPointer stackPointer_;
        assembly ("memory-safe") {
            stackPointer_ := bytes_
        }
        return stackPointer_;
    }

    /// Returns the stack pointer 32 bytes above/past the given stack pointer.
    /// @param stackPointer_ The stack pointer at the starting position.
    /// @return The stack pointer 32 bytes above the input stack pointer.
    function up(
        StackPointer stackPointer_
    ) internal pure returns (StackPointer) {
        unchecked {
            return StackPointer.wrap(StackPointer.unwrap(stackPointer_) + 0x20);
        }
    }

    /// Returns the stack pointer `n_ * 32` bytes above/past the given stack
    /// pointer.
    /// @param stackPointer_ The stack pointer at the starting position.
    /// @param n_ The multiplier on the stack movement. MAY be zero.
    /// @return The stack pointer `n_ * 32` bytes above/past the input stack
    /// pointer.
    function up(
        StackPointer stackPointer_,
        uint256 n_
    ) internal pure returns (StackPointer) {
        unchecked {
            return
                StackPointer.wrap(
                    StackPointer.unwrap(stackPointer_) + 0x20 * n_
                );
        }
    }

    /// Returns the stack pointer `n_` bytes above/past the given stack pointer.
    /// The returned stack pointer MAY NOT be aligned with the given stack
    /// pointer for subsequent 32 byte reads and writes. The caller MUST ensure
    /// that it is safe to read and write data relative to the returned stack
    /// pointer.
    /// @param stackPointer_ The stack pointer at the starting position.
    /// @param n_ The number of bytes to move.
    /// @return The stack pointer `n_` bytes above/past the given stack pointer.
    function upBytes(
        StackPointer stackPointer_,
        uint256 n_
    ) internal pure returns (StackPointer) {
        unchecked {
            return StackPointer.wrap(StackPointer.unwrap(stackPointer_) + n_);
        }
    }

    /// Returns the stack pointer 32 bytes below/before the given stack pointer.
    /// @param stackPointer_ The stack pointer at the starting position.
    /// @return The stack pointer 32 bytes below/before the given stack pointer.
    function down(
        StackPointer stackPointer_
    ) internal pure returns (StackPointer) {
        unchecked {
            return StackPointer.wrap(StackPointer.unwrap(stackPointer_) - 0x20);
        }
    }

    /// Returns the stack pointer `n_ * 32` bytes below/before the given stack
    /// pointer.
    /// @param stackPointer_ The stack pointer at the starting position.
    /// @param n_ The multiplier on the movement.
    /// @return The stack pointer `n_ * 32` bytes below/before the given stack
    /// pointer.
    function down(
        StackPointer stackPointer_,
        uint256 n_
    ) internal pure returns (StackPointer) {
        unchecked {
            return
                StackPointer.wrap(
                    StackPointer.unwrap(stackPointer_) - 0x20 * n_
                );
        }
    }

    /// Convert two stack pointer values to a single stack index. A stack index
    /// is the distance in 32 byte increments between two stack pointers. The
    /// calculations assumes the two stack pointers are aligned. The caller MUST
    /// ensure the alignment of both values. The calculation is unchecked and MAY
    /// underflow. The caller MUST ensure that the stack top is always above the
    /// stack bottom.
    /// @param stackBottom_ The lower of the two values.
    /// @param stackTop_ The higher of the two values.
    /// @return The stack index as 32 byte distance between the top and bottom.
    function toIndex(
        StackPointer stackBottom_,
        StackPointer stackTop_
    ) internal pure returns (uint256) {
        unchecked {
            return
                (StackPointer.unwrap(stackTop_) -
                    StackPointer.unwrap(stackBottom_)) / 0x20;
        }
    }
}