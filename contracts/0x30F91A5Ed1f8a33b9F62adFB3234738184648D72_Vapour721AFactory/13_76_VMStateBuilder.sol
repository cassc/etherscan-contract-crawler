// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;
import "./RainVM.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../sstore2/SSTORE2.sol";

/// Config required to build a new `State`.
/// @param sources Sources verbatim.
/// @param constants Constants verbatim.
struct StateConfig {
    bytes[] sources;
    uint256[] constants;
}

/// @param stackIndex The current stack index as the state builder moves
/// through each opcode and applies the appropriate pops and pushes.
/// @param stackLength The maximum length of the stack seen so far due to stack
/// index movements. If the stack index underflows this will be close to
/// uint256 max and will ultimately error. It will also error if it overflows
/// MAX_STACK_LENGTH.
/// @param argumentsLength The maximum length of arguments seen so far due to
/// zipmap calls. Will be 0 if there are no zipmap calls.
/// @param storageLength The VM contract MUST specify which range of storage
/// slots can be read by VM scripts as [0, storageLength). If the storageLength
/// is 0 then no storage slots may be read by opcodes. In practise opcodes are
/// uint8 so storage slots beyond 255 cannot be read, notably all mappings will
/// be inaccessible.
/// @param opcodesLength The VM contract MUST specify how many valid opcodes
/// there are, where a valid opcode is one with a corresponding valid function
/// pointer in the array returned by `fnPtrs`. If this is not set correctly
/// then an attacker may specify an opcode that points to data beyond the valid
/// fnPtrs, which has undefined and therefore possibly catastrophic behaviour
/// for the implementing contract, up to and including total funds loss.
struct Bounds {
    uint256 entrypoint;
    uint256 minFinalStackIndex;
    uint256 stackIndex;
    uint256 stackLength;
    uint256 argumentsLength;
    uint256 storageLength;
    uint256 opcodesLength;
}

uint256 constant MAX_STACK_LENGTH = type(uint8).max;

library LibFnPtrs {
    function insertStackMovePtr(
        bytes memory fnPtrs_,
        uint256 i_,
        function(uint256) view returns (uint256) fn_
    ) internal pure {
        unchecked {
            uint256 offset_ = i_ * 0x20;
            require(offset_ < fnPtrs_.length, "FN_PTRS_OVERFLOW");
            assembly {
                mstore(add(fnPtrs_, add(0x20, mul(i_, 0x20))), fn_)
            }
        }
    }

    function insertOpPtr(
        bytes memory fnPtrs_,
        uint256 i_,
        function(uint256, uint256) view returns (uint256) fn_
    ) internal pure {
        unchecked {
            uint256 offset_ = i_ * 0x20;
            require(offset_ < fnPtrs_.length, "FN_PTRS_OVERFLOW");
            assembly {
                mstore(add(fnPtrs_, add(0x20, mul(i_, 0x20))), fn_)
            }
        }
    }
}

contract VMStateBuilder {
    using Math for uint256;

    address private immutable _stackPopsFnPtrs;
    address private immutable _stackPushesFnPtrs;
    mapping(address => address) private ptrCache;

    constructor() {
        _stackPopsFnPtrs = SSTORE2.write(stackPopsFnPtrs());
        _stackPushesFnPtrs = SSTORE2.write(stackPushesFnPtrs());
    }

    function _packedFnPtrs(address vm_) private returns (bytes memory) {
        unchecked {
            bytes memory packedPtrs_ = SSTORE2.read(ptrCache[vm_]);
            if (packedPtrs_.length == 0) {
                ptrCache[vm_] = SSTORE2.write(packFnPtrs(RainVM(vm_).fnPtrs()));
                return _packedFnPtrs(vm_);
            }
            return packedPtrs_;
        }
    }

    /// Builds a new `State` bytes from `StateConfig`.
    /// Empty stack and arguments with stack index 0.
    /// @param config_ State config to build the new `State`.
    function buildState(
        address vm_,
        StateConfig memory config_,
        Bounds[] memory boundss_
    ) external returns (bytes memory) {
        unchecked {
            bytes memory packedFnPtrs_ = _packedFnPtrs(vm_);
            uint256 storageLength_ = RainVM(vm_).storageOpcodesRange().length;
            uint256 argumentsLength_ = 0;
            uint256 stackLength_ = 0;

            for (uint256 b_ = 0; b_ < boundss_.length; b_++) {
                boundss_[b_].storageLength = storageLength_;

                // Opcodes are 1 byte and fnPtrs are 2 bytes so we halve the
                // length to get the valid opcodes length.
                boundss_[b_].opcodesLength = packedFnPtrs_.length / 2;
                ensureIntegrity(config_, boundss_[b_]);
                argumentsLength_ = argumentsLength_.max(
                    boundss_[b_].argumentsLength
                );
                stackLength_ = stackLength_.max(boundss_[b_].stackLength);
                // Stack needs to be high enough to read from after eval.
                require(
                    boundss_[b_].stackIndex >= boundss_[b_].minFinalStackIndex,
                    "FINAL_STACK_INDEX"
                );
            }

            // build a new constants array with space for the arguments.
            uint256[] memory constants_ = new uint256[](
                config_.constants.length + argumentsLength_
            );
            for (uint256 i_ = 0; i_ < config_.constants.length; i_++) {
                constants_[i_] = config_.constants[i_];
            }

            bytes[] memory ptrSources_ = new bytes[](config_.sources.length);
            for (uint256 i_ = 0; i_ < config_.sources.length; i_++) {
                ptrSources_[i_] = ptrSource(packedFnPtrs_, config_.sources[i_]);
            }

            return
                LibState.toBytesPacked(
                    State(
                        0,
                        new uint256[](stackLength_),
                        ptrSources_,
                        constants_,
                        config_.constants.length
                    )
                );
        }
    }

    function ptrSource(bytes memory packedFnPtrs_, bytes memory source_)
        public
        pure
        returns (bytes memory)
    {
        unchecked {
            uint256 sourceLen_ = source_.length;
            require(sourceLen_ % 2 == 0, "ODD_SOURCE_LENGTH");

            bytes memory ptrSource_ = new bytes((sourceLen_ * 3) / 2);

            uint256 rainVMOpsLength_ = RAIN_VM_OPS_LENGTH;
            assembly {
                let start_ := 1
                let end_ := add(sourceLen_, 1)
                for {
                    let i_ := start_
                    let o_ := 0
                } lt(i_, end_) {
                    i_ := add(i_, 1)
                } {
                    let op_ := byte(31, mload(add(source_, i_)))
                    // is opcode
                    if mod(i_, 2) {
                        // core ops simply zero pad.
                        if lt(op_, rainVMOpsLength_) {
                            o_ := add(o_, 1)
                            mstore8(add(ptrSource_, add(0x20, o_)), op_)
                        }
                        if iszero(lt(op_, rainVMOpsLength_)) {
                            let fn_ := mload(
                                add(packedFnPtrs_, add(0x2, mul(op_, 0x2)))
                            )
                            mstore8(
                                add(ptrSource_, add(0x20, o_)),
                                byte(30, fn_)
                            )
                            o_ := add(o_, 1)
                            mstore8(
                                add(ptrSource_, add(0x20, o_)),
                                byte(31, fn_)
                            )
                        }
                    }
                    // is operand
                    if iszero(mod(i_, 2)) {
                        mstore8(add(ptrSource_, add(0x20, o_)), op_)
                    }
                    o_ := add(o_, 1)
                }
            }
            return ptrSource_;
        }
    }

    function packFnPtrs(bytes memory fnPtrs_)
        internal
        pure
        returns (bytes memory)
    {
        unchecked {
            require(fnPtrs_.length % 0x20 == 0, "BAD_FN_PTRS_LENGTH");
            bytes memory fnPtrsPacked_ = new bytes(fnPtrs_.length / 0x10);
            assembly {
                for {
                    let i_ := 0
                    let o_ := 0x02
                } lt(i_, mload(fnPtrs_)) {
                    i_ := add(i_, 0x20)
                    o_ := add(o_, 0x02)
                } {
                    let location_ := add(fnPtrsPacked_, o_)
                    let old_ := mload(location_)
                    let new_ := or(old_, mload(add(fnPtrs_, add(0x20, i_))))
                    mstore(location_, new_)
                }
            }
            return fnPtrsPacked_;
        }
    }

    function _ensureIntegrityZipmap(
        StateConfig memory stateConfig_,
        Bounds memory bounds_,
        uint256 operand_
    ) private view {
        unchecked {
            uint256 valLength_ = (operand_ >> 5) + 1;
            // read underflow here will show up as an OOB max later.
            bounds_.stackIndex -= valLength_;
            bounds_.stackLength = bounds_.stackLength.max(bounds_.stackIndex);
            bounds_.argumentsLength = bounds_.argumentsLength.max(valLength_);
            uint256 loopTimes_ = 1 << ((operand_ >> 3) & 0x03);
            uint256 outerEntrypoint_ = bounds_.entrypoint;
            uint256 innerEntrypoint_ = operand_ & 0x07;
            bounds_.entrypoint = innerEntrypoint_;
            for (uint256 n_ = 0; n_ < loopTimes_; n_++) {
                ensureIntegrity(stateConfig_, bounds_);
            }
            bounds_.entrypoint = outerEntrypoint_;
        }
    }

    function ensureIntegrity(
        StateConfig memory stateConfig_,
        Bounds memory bounds_
    ) public view {
        unchecked {
            uint256 entrypoint_ = bounds_.entrypoint;
            require(stateConfig_.sources.length > entrypoint_, "MIN_SOURCES");
            bytes memory stackPopsFns_ = SSTORE2.read(_stackPopsFnPtrs);
            bytes memory stackPushesFns_ = SSTORE2.read(_stackPushesFnPtrs);
            uint256 i_ = 0;
            uint256 sourceLen_;
            uint256 opcode_;
            uint256 operand_;
            uint256 sourceLocation_;

            assembly {
                sourceLocation_ := mload(
                    add(mload(stateConfig_), add(0x20, mul(entrypoint_, 0x20)))
                )

                sourceLen_ := mload(sourceLocation_)
            }

            while (i_ < sourceLen_) {
                assembly {
                    i_ := add(i_, 2)
                    let op_ := mload(add(sourceLocation_, i_))
                    opcode_ := byte(30, op_)
                    operand_ := byte(31, op_)
                }

                // Additional integrity checks for core opcodes.
                if (opcode_ < RAIN_VM_OPS_LENGTH) {
                    if (opcode_ == OPCODE_CONSTANT) {
                        // trying to read past the end of the constants array.
                        // note that it is possible for a script to reach into
                        // arguments space after a zipmap has completed. While
                        // this is almost certainly a critical bug for the
                        // script it doesn't expose the ability to read past
                        // the constants array in memory so we allow it here.
                        require(
                            operand_ <
                                (bounds_.argumentsLength +
                                    stateConfig_.constants.length),
                                    "OOB_CONSTANT"
                        );
                        bounds_.stackIndex++;
                    } else if (opcode_ == OPCODE_STACK) {
                        // trying to read past the current stack top.
                        require(operand_ < bounds_.stackIndex, "OOB_STACK");
                        bounds_.stackIndex++;
                    } else if (opcode_ == OPCODE_CONTEXT) {
                        // Note that context length check is handled at runtime
                        // because we don't know how long context should be at
                        // this point.
                        bounds_.stackIndex++;
                    } else if (opcode_ == OPCODE_STORAGE) {
                        // trying to read past allowed storage slots.
                        require(operand_ < bounds_.storageLength, "OOB_STORAGE");
                        bounds_.stackIndex++;
                    }
                    if (opcode_ == OPCODE_ZIPMAP) {
                        _ensureIntegrityZipmap(stateConfig_, bounds_, operand_);
                    }
                } else {
                    // Opcodes can't exceed the bounds of valid fn pointers.
                    require(opcode_ < bounds_.opcodesLength, "MAX_OPCODE");
                    function(uint256) pure returns (uint256) popsFn_;
                    function(uint256) pure returns (uint256) pushesFn_;
                    assembly {
                        popsFn_ := mload(
                            add(stackPopsFns_, add(0x20, mul(opcode_, 0x20)))
                        )
                        pushesFn_ := mload(
                            add(stackPushesFns_, add(0x20, mul(opcode_, 0x20)))
                        )
                    }

                    // This will catch popping/reading from underflowing the
                    // stack as it will show up as an overflow on the stack
                    // length below.
                    bounds_.stackIndex -= popsFn_(operand_);
                    bounds_.stackLength = bounds_.stackLength.max(
                        bounds_.stackIndex
                    );

                    bounds_.stackIndex += pushesFn_(operand_);
                }

                bounds_.stackLength = bounds_.stackLength.max(
                    bounds_.stackIndex
                );
            }
            // Both an overflow or underflow in uint256 space will show up as
            // an upper bound exceeding the uint8 space.
            require(bounds_.stackLength <= MAX_STACK_LENGTH, "MAX_STACK");
        }
    }

    function stackPopsFnPtrs() public pure virtual returns (bytes memory) {}

    function stackPushesFnPtrs() public pure virtual returns (bytes memory) {}
}