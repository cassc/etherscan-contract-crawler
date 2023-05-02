// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../run/LibStackPointer.sol";
import {MathUpgradeable as Math} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

import "rain.interface.interpreter/IExpressionDeployerV1.sol";
import "rain.interface.interpreter/IInterpreterV1.sol";

/// @dev The virtual stack pointers are never read or written so don't need to
/// point to a real location in memory. We only care that the stack never moves
/// below its starting point at the stack bottom. For the virtual stack used by
/// the integrity check we can start it in the middle of the `uint256` range and
/// achieve something analogous to signed integers with unsigned integer types.
StackPointer constant INITIAL_STACK_BOTTOM = StackPointer.wrap(
    type(uint256).max / 2
);

/// It is a misconfiguration to set the initial stack bottom to zero or some
/// small value as this trivially exposes the integrity check to potential
/// underflow issues that are gas intensive to repeatedly guard against on every
/// pop. The initial stack bottom for an `IntegrityCheckState` should be
/// `INITIAL_STACK_BOTTOM` to safely avoid the need for underflow checks due to
/// pops and pushes.
error MinStackBottom();

/// The virtual stack top has underflowed the stack highwater (or zero) during an
/// integrity check. The highwater will initially be the stack bottom but MAY
/// move higher due to certain operations such as placing multiple outputs on the
/// stack or copying from a stack position. The highwater prevents subsequent
/// popping of values that are considered immutable.
/// @param stackHighwaterIndex Index of the stack highwater at the moment of
/// underflow.
/// @param stackTopIndex Index of the stack top at the moment of underflow.
error StackPopUnderflow(uint256 stackHighwaterIndex, uint256 stackTopIndex);

/// The final stack produced by some source did not hit the minimum required for
/// its calling context.
/// @param minStackOutputs The required minimum stack height.
/// @param actualStackOutputs The final stack height after evaluating a source.
/// Will be less than the min stack outputs if this error is thrown.
error MinFinalStack(uint256 minStackOutputs, uint256 actualStackOutputs);

/// Running an integrity check is a stateful operation. As well as the basic
/// configuration of what is being checked such as the sources and size of the
/// constants, the current and maximum stack height is being recomputed on every
/// checked opcode. The stack is virtual during the integrity check so whatever
/// the `StackPointer` values are during the check, it's always undefined
/// behaviour to actually try to read/write to them.
///
/// @param sources All the sources of the expression are provided to the
/// integrity check as any entrypoint and non-entrypoint can `call` into some
/// other source at any time, provided the overall inputs and outputs to the
/// stack are valid.
/// @param constantsLength The integrity check assumes the existence of some
/// opcode that will read from a predefined list of constants. Technically this
/// opcode MAY NOT exist in some interpreter but it seems highly likely to be
/// included in most setups. The integrity check only needs the length of the
/// constants array to check for out of bounds reads, which allows runtime
/// behaviour to read without additional gas for OOB index checks.
/// @param stackBottom Pointer to the bottom of the virtual stack that the
/// integrity check uses to simulate a real eval.
/// @param stackMaxTop Pointer to the maximum height the virtual stack has
/// reached during the integrity check. The current virtual stack height will
/// be handled separately to the state during the check.
/// @param integrityFunctionPointers We pass an array of all the function
/// pointers to per-opcode integrity checks around with the state to facilitate
/// simple recursive integrity checking.
struct IntegrityCheckState {
    // Sources in zeroth position as we read from it in assembly without paying
    // gas to calculate offsets.
    bytes[] sources;
    uint256 constantsLength;
    StackPointer stackBottom;
    StackPointer stackHighwater;
    StackPointer stackMaxTop;
    function(IntegrityCheckState memory, Operand, StackPointer)
        view
        returns (StackPointer)[] integrityFunctionPointers;
}

/// @title LibIntegrityCheck
/// @notice "Dry run" versions of the key logic from `LibStackPointer` that
/// allows us to simulate a virtual stack based on the Solidity type system
/// itself. The core loop of an integrity check is to dispatch an integrity-only
/// version of a runtime opcode that then uses `LibIntegrityCheck` to apply a
/// function that simulates a stack movement. The simulated stack movement will
/// move a pointer to memory in the same way as a real pop/push would at runtime
/// but without any associated logic or even allocating and writing data in
/// memory on the other side of the pointer. Every pop is checked for out of
/// bounds reads, even if it is an intermediate pop within the logic of a single
/// opcode. The _gross_ stack movement is just as important as the net movement.
/// For example, consider a simple ERC20 total supply read. The _net_ movement
/// of a total supply read is 0, it pops the token address then pushes the total
/// supply. However the _gross_ movement is first -1 then +1, so we have to guard
/// against the -1 underflowing while reading the token address _during_ the
/// simulated opcode dispatch. In general this can be subtle, complex and error
/// prone, which is why `LibIntegrityCheck` and `LibStackPointer` take function
/// signatures as arguments, so that the overloading mechanism in Solidity itself
/// enforces correct pop/push calculations for every opcode.
library LibIntegrityCheck {
    using LibIntegrityCheck for IntegrityCheckState;
    using LibStackPointer for StackPointer;
    using Math for uint256;

    function newState(
        bytes[] memory sources_,
        uint256[] memory constants_,
        function(IntegrityCheckState memory, Operand, StackPointer)
            view
            returns (StackPointer)[]
            memory integrityFns_
    ) internal pure returns (IntegrityCheckState memory) {
        return
            IntegrityCheckState(
                sources_,
                constants_.length,
                INITIAL_STACK_BOTTOM,
                // Highwater starts underneath stack bottom as it errors on an
                // greater than _or equal to_ check.
                INITIAL_STACK_BOTTOM.down(),
                INITIAL_STACK_BOTTOM,
                integrityFns_
            );
    }

    /// If the given stack pointer is above the current state of the max stack
    /// top, the max stack top will be moved to the stack pointer.
    /// i.e. this works like `stackMaxTop = stackMaxTop.max(stackPointer_)` but
    /// with the type unwrapping boilerplate included for convenience.
    /// @param integrityCheckState_ The state of the current integrity check
    /// including the current max stack top.
    /// @param stackPointer_ The stack pointer to compare and potentially swap
    /// the max stack top for.
    function syncStackMaxTop(
        IntegrityCheckState memory integrityCheckState_,
        StackPointer stackPointer_
    ) internal pure {
        if (
            StackPointer.unwrap(stackPointer_) >
            StackPointer.unwrap(integrityCheckState_.stackMaxTop)
        ) {
            integrityCheckState_.stackMaxTop = stackPointer_;
        }
    }

    /// The main integrity check loop. Designed so that it can be called
    /// recursively by the dispatched integrity opcodes to support arbitrary
    /// nesting of sources and substacks, loops, etc.
    /// If ANY of the integrity checks for ANY opcode fails the entire integrity
    /// check will revert.
    /// @param integrityCheckState_ Current state of the integrity check passed
    /// by reference to allow for recursive/nested integrity checking.
    /// @param sourceIndex_ The source to check the integrity of which can be
    /// either an entrypoint or a non-entrypoint source if this is a recursive
    /// call to `ensureIntegrity`.
    /// @param stackTop_ The current top of the virtual stack as a pointer. This
    /// can be manipulated to create effective substacks/scoped/immutable
    /// runtime values by restricting how the `stackTop_` can move at deploy
    /// time.
    /// @param minStackOutputs_ The minimum stack height required by the end of
    /// this integrity check. The caller MUST ensure that it sets this value high
    /// enough so that it can safely read enough values from the final stack
    /// without out of bounds reads. The external interface to the expression
    /// deployer accepts an array of minimum stack heights against entrypoints,
    /// but the internal checks can be recursive against non-entrypoints and each
    /// opcode such as `call` can build scoped stacks, etc. so here we just put
    /// defining the requirements back on the caller.
    function ensureIntegrity(
        IntegrityCheckState memory integrityCheckState_,
        SourceIndex sourceIndex_,
        StackPointer stackTop_,
        uint256 minStackOutputs_
    ) internal view returns (StackPointer) {
        unchecked {
            // It's generally more efficient to ensure the stack bottom has
            // plenty of headroom to make underflows from pops impossible rather
            // than guard every single pop against underflow.
            if (
                StackPointer.unwrap(integrityCheckState_.stackBottom) <
                StackPointer.unwrap(INITIAL_STACK_BOTTOM)
            ) {
                revert MinStackBottom();
            }
            uint256 cursor_;
            uint256 end_;
            assembly ("memory-safe") {
                cursor_ := mload(
                    add(
                        mload(integrityCheckState_),
                        add(0x20, mul(0x20, sourceIndex_))
                    )
                )
                end_ := add(cursor_, mload(cursor_))
            }

            // Loop until complete.
            while (cursor_ < end_) {
                uint256 opcode_;
                Operand operand_;
                cursor_ += 4;
                assembly ("memory-safe") {
                    let op_ := mload(cursor_)
                    operand_ := and(op_, 0xFFFF)
                    opcode_ := and(shr(16, op_), 0xFFFF)
                }
                // We index into the function pointers here rather than using raw
                // assembly to ensure that any opcodes that we don't have a
                // pointer for will error as a standard Solidity OOB read.
                stackTop_ = integrityCheckState_.integrityFunctionPointers[
                    opcode_
                ](integrityCheckState_, operand_, stackTop_);
            }
            uint256 finalStackOutputs_ = integrityCheckState_
                .stackBottom
                .toIndex(stackTop_);
            if (minStackOutputs_ > finalStackOutputs_) {
                revert MinFinalStack(minStackOutputs_, finalStackOutputs_);
            }
            return stackTop_;
        }
    }

    /// Push a single virtual item onto the virtual stack.
    /// Simply moves the stack top up one and syncs the interpreter max stack
    /// height with it if needed.
    /// @param integrityCheckState_ The state of the current integrity check.
    /// @param stackTop_ The pointer to the virtual stack top for the current
    /// integrity check.
    /// @return The stack top after it has pushed an item.
    function push(
        IntegrityCheckState memory integrityCheckState_,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        stackTop_ = stackTop_.up();
        integrityCheckState_.syncStackMaxTop(stackTop_);
        return stackTop_;
    }

    /// Overloaded `push` to support `n_` pushes in a single movement.
    /// `n_` MAY be 0 and this is a virtual noop stack movement.
    /// @param integrityCheckState_ as per `push`.
    /// @param stackTop_ as per `push`.
    /// @param n_ The number of items to push to the virtual stack.
    function push(
        IntegrityCheckState memory integrityCheckState_,
        StackPointer stackTop_,
        uint256 n_
    ) internal pure returns (StackPointer) {
        stackTop_ = stackTop_.up(n_);
        // Any time we push more than 1 item to the stack we move the highwater
        // to the last item, as nested multioutput is disallowed.
        if (n_ > 1) {
            integrityCheckState_.stackHighwater = StackPointer.wrap(
                StackPointer.unwrap(integrityCheckState_.stackHighwater).max(
                    StackPointer.unwrap(stackTop_.down())
                )
            );
        }
        integrityCheckState_.syncStackMaxTop(stackTop_);
        return stackTop_;
    }

    /// As push for 0+ values. Does NOT move the highwater. This may be useful if
    /// the highwater is already calculated somehow by the caller. This is also
    /// dangerous if used incorrectly as it could allow uncaught underflows to
    /// creep in.
    function pushIgnoreHighwater(
        IntegrityCheckState memory integrityCheckState_,
        StackPointer stackTop_,
        uint256 n_
    ) internal pure returns (StackPointer) {
        stackTop_ = stackTop_.up(n_);
        integrityCheckState_.syncStackMaxTop(stackTop_);
        return stackTop_;
    }

    /// Move the stock top down one item then check that it hasn't underflowed
    /// the stack bottom. If all virtual stack movements are defined in terms
    /// of pops and pushes this will enforce that the gross stack movements do
    /// not underflow, which would lead to out of bounds stack reads at runtime.
    /// @param integrityCheckState_ The state of the current integrity check.
    /// @param stackTop_ The virtual stack top before an item is popped.
    /// @return The virtual stack top after the pop.
    function pop(
        IntegrityCheckState memory integrityCheckState_,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        stackTop_ = stackTop_.down();
        integrityCheckState_.popUnderflowCheck(stackTop_);
        return stackTop_;
    }

    /// Overloaded `pop` to support `n_` pops in a single movement.
    /// `n_` MAY be 0 and this is a virtual noop stack movement.
    /// @param integrityCheckState_ as per `pop`.
    /// @param stackTop_ as per `pop`.
    /// @param n_ The number of items to pop off the virtual stack.
    function pop(
        IntegrityCheckState memory integrityCheckState_,
        StackPointer stackTop_,
        uint256 n_
    ) internal pure returns (StackPointer) {
        if (n_ > 0) {
            stackTop_ = stackTop_.down(n_);
            integrityCheckState_.popUnderflowCheck(stackTop_);
        }
        return stackTop_;
    }

    /// DANGEROUS pop that does no underflow/highwater checks. The caller MUST
    /// ensure that this does not result in illegal stack reads.
    /// @param stackTop_ as per `pop`.
    /// @param n_ as per `pop`.
    function popIgnoreHighwater(
        IntegrityCheckState memory,
        StackPointer stackTop_,
        uint256 n_
    ) internal pure returns (StackPointer) {
        return stackTop_.down(n_);
    }

    /// Ensures that pops have not underflowed the stack, i.e. that the stack
    /// top is not below the stack bottom. We set a large stack bottom that is
    /// impossible to underflow within gas limits with realistic pops so that
    /// we don't have to deal with a numeric underflow of the stack top.
    /// @param integrityCheckState_ As per `pop`.
    /// @param stackTop_ as per `pop`.
    function popUnderflowCheck(
        IntegrityCheckState memory integrityCheckState_,
        StackPointer stackTop_
    ) internal pure {
        if (
            StackPointer.unwrap(stackTop_) <=
            StackPointer.unwrap(integrityCheckState_.stackHighwater)
        ) {
            revert StackPopUnderflow(
                integrityCheckState_.stackBottom.toIndex(
                    integrityCheckState_.stackHighwater
                ),
                integrityCheckState_.stackBottom.toIndex(stackTop_)
            );
        }
    }

    /// Maps `function(uint256, uint256) internal view returns (uint256)` to pops
    /// and pushes repeatedly N times. The function itself is irrelevant we only
    /// care about the signature to know how many items are popped/pushed.
    /// @param integrityCheckState_ as per `pop` and `push`.
    /// @param stackTop_ as per `pop` and `push`.
    /// @param n_ The number of times the function is applied to the stack.
    /// @return The stack top after the function has been applied n times.
    function applyFnN(
        IntegrityCheckState memory integrityCheckState_,
        StackPointer stackTop_,
        function(uint256, uint256) internal view returns (uint256),
        uint256 n_
    ) internal pure returns (StackPointer) {
        return
            integrityCheckState_.push(integrityCheckState_.pop(stackTop_, n_));
    }

    /// Maps `function(uint256) internal view` to pops and pushes repeatedly N
    /// times. The function itself is irrelevant we only care about the
    /// signature to know how many items are popped/pushed.
    /// @param integrityCheckState_ as per `pop` and `push`.
    /// @param stackTop_ as per `pop` and `push`.
    /// @param n_ The number of times the function is applied to the stack.
    /// @return The stack top after the function has been applied n times.
    function applyFnN(
        IntegrityCheckState memory integrityCheckState_,
        StackPointer stackTop_,
        function(uint256) internal view,
        uint256 n_
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.pop(stackTop_, n_);
    }

    /// Maps `function(uint256) internal view returns (uint256)` to pops and
    /// pushes once. The function itself is irrelevant we only care about the
    /// signature to know how many items are popped/pushed.
    /// @param integrityCheckState_ as per `pop` and `push`.
    /// @param stackTop_ as per `pop` and `push`.
    /// @return The stack top after the function has been applied once.
    function applyFn(
        IntegrityCheckState memory integrityCheckState_,
        StackPointer stackTop_,
        function(uint256) internal view returns (uint256)
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.push(integrityCheckState_.pop(stackTop_));
    }

    /// Maps `function(uint256, uint256) internal view` to pops and pushes once.
    /// The function itself is irrelevant we only care about the signature to
    /// know how many items are popped/pushed.
    /// @param integrityCheckState_ as per `pop` and `push`.
    /// @param stackTop_ as per `pop` and `push`.
    /// @return The stack top after the function has been applied once.
    function applyFn(
        IntegrityCheckState memory integrityCheckState_,
        StackPointer stackTop_,
        function(uint256, uint256) internal view
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.pop(stackTop_, 2);
    }

    /// Maps `function(uint256, uint256) internal view returns (uint256)` to
    /// pops and pushes once. The function itself is irrelevant we only care
    /// about the signature to know how many items are popped/pushed.
    /// @param integrityCheckState_ as per `pop` and `push`.
    /// @param stackTop_ as per `pop` and `push`.
    /// @return The stack top after the function has been applied once.
    function applyFn(
        IntegrityCheckState memory integrityCheckState_,
        StackPointer stackTop_,
        function(uint256, uint256) internal view returns (uint256)
    ) internal pure returns (StackPointer) {
        return
            integrityCheckState_.push(integrityCheckState_.pop(stackTop_, 2));
    }

    /// Maps
    /// `function(uint256, uint256, uint256) internal view returns (uint256)` to
    /// pops and pushes once. The function itself is irrelevant we only care
    /// about the signature to know how many items are popped/pushed.
    /// @param integrityCheckState_ as per `pop` and `push`.
    /// @param stackTop_ as per `pop` and `push`.
    /// @return The stack top after the function has been applied once.
    function applyFn(
        IntegrityCheckState memory integrityCheckState_,
        StackPointer stackTop_,
        function(uint256, uint256, uint256) internal view returns (uint256)
    ) internal pure returns (StackPointer) {
        return
            integrityCheckState_.push(integrityCheckState_.pop(stackTop_, 3));
    }

    /// Maps
    /// ```
    /// function(uint256, uint256, uint256, uint256)
    ///     internal
    ///     view
    ///     returns (uint256)
    /// ```
    /// to pops and pushes once. The function itself is irrelevant we only care
    /// about the signature to know how many items are popped/pushed.
    /// @param integrityCheckState_ as per `pop` and `push`.
    /// @param stackTop_ as per `pop` and `push`.
    /// @return The stack top after the function has been applied once.
    function applyFn(
        IntegrityCheckState memory integrityCheckState_,
        StackPointer stackTop_,
        function(uint256, uint256, uint256, uint256)
            internal
            view
            returns (uint256)
    ) internal pure returns (StackPointer) {
        return
            integrityCheckState_.push(integrityCheckState_.pop(stackTop_, 4));
    }

    /// Maps `function(uint256[] memory) internal view returns (uint256)` to
    /// pops and pushes once given that we know the length of the dynamic array
    /// at deploy time. The function itself is irrelevant we only care about the
    /// signature to know how many items are popped/pushed.
    /// @param integrityCheckState_ as per `pop` and `push`.
    /// @param stackTop_ as per `pop` and `push`.
    /// @param length_ The length of the dynamic input array.
    /// @return The stack top after the function has been applied once.
    function applyFn(
        IntegrityCheckState memory integrityCheckState_,
        StackPointer stackTop_,
        function(uint256[] memory) internal view returns (uint256),
        uint256 length_
    ) internal pure returns (StackPointer) {
        return
            integrityCheckState_.push(
                integrityCheckState_.pop(stackTop_, length_)
            );
    }

    /// Maps
    /// ```
    /// function(uint256, uint256, uint256[] memory)
    ///     internal
    ///     view
    ///     returns (uint256)
    /// ```
    /// to pops and pushes once given that we know the length of the dynamic
    /// array at deploy time. The function itself is irrelevant we only care
    /// about the signature to know how many items are popped/pushed.
    /// @param integrityCheckState_ as per `pop` and `push`.
    /// @param stackTop_ as per `pop` and `push`.
    /// @param length_ The length of the dynamic input array.
    /// @return The stack top after the function has been applied once.
    function applyFn(
        IntegrityCheckState memory integrityCheckState_,
        StackPointer stackTop_,
        function(uint256, uint256, uint256[] memory)
            internal
            view
            returns (uint256),
        uint256 length_
    ) internal pure returns (StackPointer) {
        unchecked {
            return
                integrityCheckState_.push(
                    integrityCheckState_.pop(stackTop_, length_ + 2)
                );
        }
    }

    /// Maps
    /// ```
    /// function(uint256, uint256, uint256, uint256[] memory)
    ///     internal
    ///     view
    ///     returns (uint256)
    /// ```
    /// to pops and pushes once given that we know the length of the dynamic
    /// array at deploy time. The function itself is irrelevant we only care
    /// about the signature to know how many items are popped/pushed.
    /// @param integrityCheckState_ as per `pop` and `push`.
    /// @param stackTop_ as per `pop` and `push`.
    /// @param length_ The length of the dynamic input array.
    /// @return The stack top after the function has been applied once.
    function applyFn(
        IntegrityCheckState memory integrityCheckState_,
        StackPointer stackTop_,
        function(uint256, uint256, uint256, uint256[] memory)
            internal
            view
            returns (uint256),
        uint256 length_
    ) internal pure returns (StackPointer) {
        unchecked {
            return
                integrityCheckState_.push(
                    integrityCheckState_.pop(stackTop_, length_ + 3)
                );
        }
    }

    /// Maps
    /// ```
    /// function(uint256, uint256[] memory, uint256[] memory)
    ///     internal
    ///     view
    ///     returns (uint256[] memory)
    /// ```
    /// to pops and pushes once given that we know the length of the dynamic
    /// array at deploy time. The function itself is irrelevant we only care
    /// about the signature to know how many items are popped/pushed.
    /// @param integrityCheckState_ as per `pop` and `push`.
    /// @param stackTop_ as per `pop` and `push`.
    /// @param length_ The length of the dynamic input array.
    /// @return The stack top after the function has been applied once.
    function applyFn(
        IntegrityCheckState memory integrityCheckState_,
        StackPointer stackTop_,
        function(uint256, uint256[] memory, uint256[] memory)
            internal
            view
            returns (uint256[] memory),
        uint256 length_
    ) internal pure returns (StackPointer) {
        unchecked {
            return
                integrityCheckState_.push(
                    integrityCheckState_.pop(stackTop_, length_ * 2 + 1),
                    length_
                );
        }
    }

    /// Maps `function(Operand, uint256) internal view returns (uint256)` to
    /// pops and pushes once. The function itself is irrelevant we only care
    /// about the signature to know how many items are popped/pushed.
    ///
    /// The operand MUST NOT influence the stack movements if this application
    /// is to be valid.
    ///
    /// @param integrityCheckState_ as per `pop` and `push`.
    /// @param stackTop_ as per `pop` and `push`.
    /// @return The stack top after the function has been applied once.
    function applyFn(
        IntegrityCheckState memory integrityCheckState_,
        StackPointer stackTop_,
        function(Operand, uint256) internal view returns (uint256)
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.push(integrityCheckState_.pop(stackTop_));
    }

    /// Maps
    /// `function(Operand, uint256, uint256) internal view returns (uint256)` to
    /// pops and pushes once. The function itself is irrelevant we only care
    /// about the signature to know how many items are popped/pushed.
    ///
    /// The operand MUST NOT influence the stack movements if this application
    /// is to be valid.
    ///
    /// @param integrityCheckState_ as per `pop` and `push`.
    /// @param stackTop_ as per `pop` and `push`.
    /// @return The stack top after the function has been applied once.
    function applyFn(
        IntegrityCheckState memory integrityCheckState_,
        StackPointer stackTop_,
        function(Operand, uint256, uint256) internal view returns (uint256)
    ) internal pure returns (StackPointer) {
        return
            integrityCheckState_.push(integrityCheckState_.pop(stackTop_, 2));
    }
}