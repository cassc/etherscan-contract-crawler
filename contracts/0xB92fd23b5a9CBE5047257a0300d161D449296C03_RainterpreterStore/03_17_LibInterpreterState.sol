// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "rain.interface.interpreter/IInterpreterV1.sol";
import "rain.interface.interpreter/IExpressionDeployerV1.sol";
import "./LibStackPointer.sol";
import "rain.lib.typecast/LibConvert.sol";
import "sol.lib.memory/LibUint256Array.sol";
import "../../memory/LibMemorySize.sol";
import {SafeCastUpgradeable as SafeCast} from "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "../../kv/LibMemoryKV.sol";
import "hardhat/console.sol";

/// Debugging options for a standard console log over the interpreter state.
/// - Stack: Log the entire stack, respects the current stack top, i.e. DOES NOT
///   log every value of the underlying `uint256[]` unless the stack top points
///   to the end of the array.
/// - Constant: Log every constant available to the current expression.
/// - Context: Log every column/row of context available to the current eval.
/// - Source: Log all the raw bytes of the compiled sources being evaluated.
enum DebugStyle {
    Stack,
    Constant,
    Context,
    Source
}

/// The standard in-memory representation of an interpreter that facilitates
/// decoupled coordination between opcodes. Opcodes MAY:
///
/// - push and pop values to the shared stack
/// - read per-expression constants
/// - write to the final state changes set within the fully qualified namespace
/// - read per-eval context values
/// - recursively evaluate any compiled source associated with the expression
///
/// As the interpreter defines the opcodes it is its responsibility to ensure the
/// opcodes are incapable of doing anything to undermine security or correctness.
/// For example, a hypothetical opcode could modify the current namespace from
/// the stack, but this would be a very bad idea as it would allow expressions
/// to hijack storage values associated with other callers, fundamentally
/// breaking the state sandbox model.
///
/// The iterpreter MAY skip any runtime integrity checks that can be reasonably
/// assumed to have been performed by a competent expression deployer, such as
/// guarding against stack underflow. A competent expression deployer MAY NOT
/// have deployed the currently evaluating expression, so the interpreter MUST
/// avoid state changes during evaluation, but MAY return garbage data if the
/// calling contract fails to leverage an appropriate expression deployer.
///
/// @param stackBottom Opcodes write to the stack starting at the stack bottom,
/// ideally using `LibStackPointer` to normalise push and pop behaviours. A
/// competent expression deployer will calculate a memory preallocation that
/// pushes and pops above the stack bottom effectively allocate and deallocate
/// memory within.
/// @param constantsBottom Opcodes read constants starting at the pointer to
/// the bottom of the constants array. As the name implies the interpreter MUST
/// NOT write to the constants, it is read only.
/// @param stateKV The in memory key/value store that tracks reads/writes over
/// the underlying interpreter storage for the duration of a single expression
/// evaluation.
/// @param namespace The fully qualified namespace that all state reads and
/// writes MUST be performed under.
/// @param store The store to reference ostensibly for gets but perhaps other
/// things.
/// @param context A 2-dimensional array of per-eval data provided by the calling
/// contract. Opaque to the interpreter but presumably meaningful to the
/// expression.
/// @param compiledSources A list of sources that can be directly evaluated by
/// the interpreter, either as a top level entrypoint or nested e.g. under a
/// dispatch by `call`.
struct InterpreterState {
    StackPointer stackBottom;
    StackPointer constantsBottom;
    MemoryKV stateKV;
    FullyQualifiedNamespace namespace;
    IInterpreterStoreV1 store;
    uint256[][] context;
    bytes[] compiledSources;
}

/// @dev squiggly lines to make the debug output easier to read. Intentionlly
/// short to keep compiled code size down.
string constant DEBUG_DELIMETER = "~~~";

/// @title LibInterpreterState
/// @notice Main workhorse for `InterpeterState` including:
///
/// - the standard `eval` loop
/// - source compilation from opcodes
/// - state (de)serialization (more gas efficient than abi encoding)
/// - low level debugging utility
///
/// Interpreters are designed to be highly moddable behind the `IInterpreterV1`
/// interface, but pretty much any interpreter that uses `InterpreterState` will
/// need these low level facilities verbatim. Further, these facilities
/// (with possible exception of debugging logic), while relatively short in terms
/// of lines of code, are surprisingly fragile to maintain in a gas efficient way
/// so we don't recommend reinventing this wheel.
library LibInterpreterState {
    using SafeCast for uint256;
    using LibMemorySize for uint256;
    using LibMemorySize for uint256[];
    using LibMemorySize for bytes;
    using LibUint256Array for uint256[];
    using LibUint256Array for uint256;
    using LibInterpreterState for StackPointer;
    using LibStackPointer for uint256[];
    using LibStackPointer for StackPointer;
    using LibStackPointer for bytes;

    /// Thin wrapper around hardhat's `console.log` that loops over any array
    /// and logs each value delimited by `DEBUG_DELIMITER`.
    /// @param array_ The array to debug.
    function debugArray(uint256[] memory array_) internal view {
        unchecked {
            console.log(DEBUG_DELIMETER);
            for (uint256 i_ = 0; i_ < array_.length; i_++) {
                console.log(i_, array_[i_]);
            }
            console.log(DEBUG_DELIMETER);
        }
    }

    /// Copies the stack to a new array then debugs it. Definitely NOT gas
    /// efficient, but affords simple and effective debugging.
    /// @param stackBottom_ Pointer to the bottom of the stack.
    /// @param stackTop_ Pointer to the top of the stack.
    function debugStack(
        StackPointer stackBottom_,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        uint256 length_ = stackBottom_.toIndex(stackTop_);
        uint256[] memory array_ = new uint256[](length_);
        LibMemCpy.unsafeCopyWordsTo(
            Pointer.wrap(StackPointer.unwrap(stackTop_.down(length_))),
            array_.dataPointer(),
            length_
        );
        debugArray(array_);
        return stackTop_;
    }

    /// Console log various aspects of the Interpreter state. Gas intensive and
    /// relies on hardhat console so not intended for production but great for
    /// debugging expressions. MAY be exposed as an opcode so expression authors
    /// can debug the expressions directly onchain.
    /// @param state_ The interpreter state to debug the internals of.
    /// @param stackTop_ Pointer to the current stack top.
    /// @param debugStyle_ Enum variant defining what should be debugged from the
    /// interpreter state.
    function debug(
        InterpreterState memory state_,
        StackPointer stackTop_,
        DebugStyle debugStyle_
    ) internal view returns (StackPointer) {
        unchecked {
            if (debugStyle_ == DebugStyle.Source) {
                for (uint256 i_ = 0; i_ < state_.compiledSources.length; i_++) {
                    console.logBytes(state_.compiledSources[i_]);
                }
            } else {
                if (debugStyle_ == DebugStyle.Stack) {
                    state_.stackBottom.debugStack(stackTop_);
                } else if (debugStyle_ == DebugStyle.Constant) {
                    debugArray(state_.constantsBottom.down().asUint256Array());
                } else {
                    for (uint256 i_ = 0; i_ < state_.context.length; i_++) {
                        debugArray(state_.context[i_]);
                    }
                }
            }
            return stackTop_;
        }
    }

    function serializeSize(
        bytes[] memory sources_,
        uint256[] memory constants_,
        uint256 stackLength_
    ) internal pure returns (uint256) {
        uint256 size_ = 0;
        size_ += stackLength_.size();
        size_ += constants_.size();
        for (uint256 i_ = 0; i_ < sources_.length; i_++) {
            size_ += sources_[i_].size();
        }
        return size_;
    }

    /// Efficiently serializes some `IInterpreterV1` state config into bytes that
    /// can be deserialized to an `InterpreterState` without memory allocation or
    /// copying of data on the return trip. This is achieved by mutating data in
    /// place for both serialization and deserialization so it is much more gas
    /// efficient than abi encode/decode but is NOT SAFE to use the
    /// `ExpressionConfig` after it has been serialized. Notably the index based
    /// opcodes in the sources in `ExpressionConfig` will be replaced by function
    /// pointer based opcodes in place, so are no longer usable in a portable
    /// format.
    /// @param sources_ As per `IExpressionDeployerV1`.
    /// @param constants_ As per `IExpressionDeployerV1`.
    /// @param stackLength_ Stack length calculated by `IExpressionDeployerV1`
    /// that will be used to allocate memory for the stack upon deserialization.
    /// @param opcodeFunctionPointers_ As per `IInterpreterV1.functionPointers`,
    /// bytes to be compiled into the final `InterpreterState.compiledSources`.
    function serialize(
        Pointer memPointer_,
        bytes[] memory sources_,
        uint256[] memory constants_,
        uint256 stackLength_,
        bytes memory opcodeFunctionPointers_
    ) internal pure {
        unchecked {
            StackPointer pointer_ = StackPointer.wrap(
                Pointer.unwrap(memPointer_)
            );
            // Copy stack length.
            pointer_ = pointer_.push(stackLength_);

            // Then the constants.
            pointer_ = pointer_.pushWithLength(constants_);

            // Last the sources.
            bytes memory source_;
            for (uint256 i_ = 0; i_ < sources_.length; i_++) {
                source_ = sources_[i_];
                compile(source_, opcodeFunctionPointers_);
                pointer_ = pointer_.unalignedPushWithLength(source_);
            }
        }
    }

    /// Return trip from `serialize` but targets an `InterpreterState` NOT a
    /// `ExpressionConfig`. Allows serialized bytes to be written directly into
    /// contract code on the other side of an expression address, then loaded
    /// directly into an eval-able memory layout. The only allocation required
    /// is to initialise the stack for eval, there is no copying in memory from
    /// the serialized data as the deserialization merely calculates Solidity
    /// compatible pointers to positions in the raw serialized data. This is much
    /// more gas efficient than an equivalent abi.decode call which would involve
    /// more processing, copying and allocating.
    ///
    /// Note that per-eval data such as namespace and context is NOT initialised
    /// by the deserialization process and so will need to be handled by the
    /// interpreter as part of `eval`.
    ///
    /// @param serialized_ Bytes previously serialized by
    /// `LibInterpreterState.serialize`.
    /// @return An eval-able interpreter state with initialized stack.
    function deserialize(
        bytes memory serialized_
    ) internal pure returns (InterpreterState memory) {
        unchecked {
            InterpreterState memory state_;

            // Context will probably be overridden by the caller according to the
            // context scratch that we deserialize so best to just set it empty
            // here.
            state_.context = new uint256[][](0);

            StackPointer cursor_ = serialized_.asStackPointer().up();
            // The end of processing is the end of the state bytes.
            StackPointer end_ = cursor_.upBytes(cursor_.peek());

            // Read the stack length and build a stack.
            cursor_ = cursor_.up();
            uint256 stackLength_ = cursor_.peek();

            // The stack is never stored in stack bytes so we allocate a new
            // array for it with length as per the indexes and point the state
            // at it.
            uint256[] memory stack_ = new uint256[](stackLength_);
            state_.stackBottom = stack_.asStackPointerUp();

            // Reference the constants array and move cursor past it.
            cursor_ = cursor_.up();
            state_.constantsBottom = cursor_;
            cursor_ = cursor_.up(cursor_.peek());

            // Rebuild the sources array.
            uint256 i_ = 0;
            StackPointer lengthCursor_ = cursor_;
            uint256 sourcesLength_ = 0;
            while (
                StackPointer.unwrap(lengthCursor_) < StackPointer.unwrap(end_)
            ) {
                lengthCursor_ = lengthCursor_
                    .upBytes(lengthCursor_.peekUp())
                    .up();
                sourcesLength_++;
            }
            state_.compiledSources = new bytes[](sourcesLength_);
            while (StackPointer.unwrap(cursor_) < StackPointer.unwrap(end_)) {
                state_.compiledSources[i_] = cursor_.asBytes();
                cursor_ = cursor_.upBytes(cursor_.peekUp()).up();
                i_++;
            }
            return state_;
        }
    }

    /// Given a source in opcodes compile to an equivalent source with real
    /// function pointers for a given Interpreter contract. The "compilation"
    /// involves simply replacing the opcode with the pointer at the index of
    /// the opcode. i.e. opcode 4 will be replaced with `pointers_[4]`.
    /// Relies heavily on the integrity checks ensuring opcodes used are not OOB
    /// and that the pointers provided are valid and in the correct order. As the
    /// expression deployer is typically handling compilation during
    /// serialization, NOT the interpreter, the interpreter MUST guard against
    /// the compilation being garbage or outright hostile during `eval` by
    /// pointing to arbitrary internal functions of the interpreter.
    /// @param source_ The input source as index based opcodes.
    /// @param pointers_ The function pointers ordered by index to replace the
    /// index based opcodes with.
    function compile(
        bytes memory source_,
        bytes memory pointers_
    ) internal pure {
        assembly ("memory-safe") {
            for {
                let replaceMask_ := 0xFFFF
                let preserveMask_ := not(replaceMask_)
                let sourceLength_ := mload(source_)
                let pointersBottom_ := add(pointers_, 2)
                let cursor_ := add(source_, 2)
                let end_ := add(source_, sourceLength_)
            } lt(cursor_, end_) {
                cursor_ := add(cursor_, 4)
            } {
                let data_ := mload(cursor_)
                let pointer_ := and(
                    replaceMask_,
                    mload(
                        add(pointersBottom_, mul(2, and(data_, replaceMask_)))
                    )
                )
                mstore(cursor_, or(and(data_, preserveMask_), pointer_))
            }
        }
    }

    /// The main eval loop. Does as little as possible as it is an extremely hot
    /// performance and critical security path. Loads opcode/operand pairs from
    /// a precompiled source in the interpreter state and calls the function
    /// that the opcode points to. This function is in turn responsible for
    /// actually pushing/popping from the stack, etc. As `eval` receives the
    /// source index and stack top alongside its state, it supports recursive
    /// calls via. opcodes that can manage scoped substacks, etc. without `eval`
    /// needing to house that complexity itself.
    /// @param state_ The interpreter state to evaluate a source over.
    /// @param sourceIndex_ The index of the source to evaluate. MAY be an
    /// entrypoint or a nested call.
    /// @param stackTop_ The current stack top, MUST be equal to the stack bottom
    /// on the intepreter state if the current eval is for an entrypoint.
    function eval(
        InterpreterState memory state_,
        SourceIndex sourceIndex_,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        unchecked {
            uint256 cursor_;
            uint256 end_;
            assembly ("memory-safe") {
                cursor_ := mload(
                    add(
                        // MUST point to compiled sources. Needs updating if the
                        // `IntepreterState` struct changes fields.
                        mload(add(state_, 0xC0)),
                        add(
                            0x20,
                            mul(
                                0x20,
                                // SourceIndex is a uint16 so needs cleaning.
                                and(sourceIndex_, 0xFFFF)
                            )
                        )
                    )
                )
                end_ := add(cursor_, mload(cursor_))
            }

            // Loop until complete.
            while (cursor_ < end_) {
                function(InterpreterState memory, Operand, StackPointer)
                    internal
                    view
                    returns (StackPointer) fn_;
                Operand operand_;
                cursor_ += 4;
                {
                    uint256 op_;
                    assembly ("memory-safe") {
                        op_ := mload(cursor_)
                        operand_ := and(op_, 0xFFFF)
                        fn_ := and(shr(16, op_), 0xFFFF)
                    }
                }
                stackTop_ = fn_(state_, operand_, stackTop_);
            }
            return stackTop_;
        }
    }

    /// Standard way to elevate a caller-provided state namespace to a universal
    /// namespace that is disjoint from all other caller-provided namespaces.
    /// Essentially just hashes the `msg.sender` into the state namespace as-is.
    ///
    /// This is deterministic such that the same combination of state namespace
    /// and caller will produce the same fully qualified namespace, even across
    /// multiple transactions/blocks.
    ///
    /// @param stateNamespace_ The state namespace as specified by the caller.
    /// @return A fully qualified namespace that cannot collide with any other
    /// state namespace specified by any other caller.
    function qualifyNamespace(
        StateNamespace stateNamespace_
    ) internal view returns (FullyQualifiedNamespace) {
        return
            FullyQualifiedNamespace.wrap(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            msg.sender,
                            StateNamespace.unwrap(stateNamespace_)
                        )
                    )
                )
            );
    }
}