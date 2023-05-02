// SPDX-License-Identifier: CAL
pragma solidity =0.8.18;

import "rain.lib.typecast/LibConvert.sol";
import "sol.lib.memory/LibUint256Array.sol";
import "./bytes32/OpDecode256.sol";
import "./bytes32/OpEncode256.sol";
import "./bytes32/OpExplode32.sol";
import "./chainlink/OpChainlinkOraclePrice.sol";
import "./context/OpContext.sol";
import "./context/OpContextColumnHash.sol";
import "./context/OpContextRow.sol";
import "./context/OpFoldContext.sol";
import "./core/OpCall.sol";
import "./core/OpDebug.sol";
import "./core/OpDoWhile.sol";
import "./core/OpExtern.sol";
import "./core/OpLoopN.sol";
import "./core/OpReadMemory.sol";
import "./crypto/OpHash.sol";
import "./erc20/OpERC20BalanceOf.sol";
import "./erc20/OpERC20TotalSupply.sol";
import "./erc20/snapshot/OpERC20SnapshotBalanceOfAt.sol";
import "./erc20/snapshot/OpERC20SnapshotTotalSupplyAt.sol";
import "./erc721/OpERC721BalanceOf.sol";
import "./erc721/OpERC721OwnerOf.sol";
import "./erc1155/OpERC1155BalanceOf.sol";
import "./erc1155/OpERC1155BalanceOfBatch.sol";
import "./erc5313/OpERC5313Owner.sol";
import "./error/OpEnsure.sol";
import "./evm/OpBlockNumber.sol";
import "./evm/OpTimestamp.sol";
import "./math/fixedPoint/OpFixedPointScale18.sol";
import "./math/fixedPoint/OpFixedPointScale18Dynamic.sol";
import "./math/fixedPoint/OpFixedPointScaleN.sol";
import "./math/logic/OpAny.sol";
import "./math/logic/OpEagerIf.sol";
import "./math/logic/OpEqualTo.sol";
import "./math/logic/OpEvery.sol";
import "./math/logic/OpGreaterThan.sol";
import "./math/logic/OpIsZero.sol";
import "./math/logic/OpLessThan.sol";
import "./math/prb/OpPRBAvg.sol";
import "./math/prb/OpPRBCeil.sol";
import "./math/prb/OpPRBDiv.sol";
import "./math/prb/OpPRBExp.sol";
import "./math/prb/OpPRBExp2.sol";
import "./math/prb/OpPRBFloor.sol";
import "./math/prb/OpPRBFrac.sol";
import "./math/prb/OpPRBGm.sol";
import "./math/prb/OpPRBInv.sol";
import "./math/prb/OpPRBLn.sol";
import "./math/prb/OpPRBLog10.sol";
import "./math/prb/OpPRBLog2.sol";
import "./math/prb/OpPRBMul.sol";
import "./math/prb/OpPRBPow.sol";
import "./math/prb/OpPRBPowu.sol";
import "./math/prb/OpPRBSqrt.sol";
import "./math/saturating/OpSaturatingAdd.sol";
import "./math/saturating/OpSaturatingMul.sol";
import "./math/saturating/OpSaturatingSub.sol";
import "./math/OpAdd.sol";
import "./math/OpDiv.sol";
import "./math/OpExp.sol";
import "./math/OpMax.sol";
import "./math/OpMin.sol";
import "./math/OpMod.sol";
import "./math/OpMul.sol";
import "./math/OpSub.sol";
import "./rain/IOrderBookV2/OpIOrderBookV2VaultBalance.sol";
import "./rain/ISaleV2/OpISaleV2RemainingTokenInventory.sol";
import "./rain/ISaleV2/OpISaleV2Reserve.sol";
import "./rain/ISaleV2/OpISaleV2SaleStatus.sol";
import "./rain/ISaleV2/OpISaleV2Token.sol";
import "./rain/ISaleV2/OpISaleV2TotalReserveReceived.sol";
import "./rain/IVerifyV1/OpIVerifyV1AccountStatusAtTime.sol";

import "./store/OpGet.sol";
import "./store/OpSet.sol";

import "./tier/OpITierV2Report.sol";
import "./tier/OpITierV2ReportTimeForTier.sol";
import "./tier/OpITierV2SaturatingDiff.sol";
import "./tier/OpITierV2SelectLte.sol";
import "./tier/OpITierV2UpdateTimesForTierRange.sol";

/// Thrown when a dynamic length array is NOT 1 more than a fixed length array.
/// Should never happen outside a major breaking change to memory layouts.
error BadDynamicLength(uint256 dynamicLength, uint256 standardOpsLength);

/// @dev Number of ops currently provided by `AllStandardOps`.
uint256 constant ALL_STANDARD_OPS_LENGTH = 78;

/// @title AllStandardOps
/// @notice Every opcode available from the core repository laid out as a single
/// array to easily build function pointers for `IInterpreterV1`.
library AllStandardOps {
    using LibCast for uint256;
    using LibCast for function(uint256) pure returns (uint256);
    using LibCast for function(InterpreterState memory, uint256, StackPointer)
        view
        returns (StackPointer);
    using LibCast for function(InterpreterState memory, uint256, StackPointer)
        pure
        returns (StackPointer);
    using LibCast for function(InterpreterState memory, uint256, StackPointer)
        view
        returns (StackPointer)[];

    using AllStandardOps for function(
        IntegrityCheckState memory,
        Operand,
        StackPointer
    ) view returns (StackPointer)[ALL_STANDARD_OPS_LENGTH + 1];
    using AllStandardOps for function(
        InterpreterState memory,
        Operand,
        StackPointer
    ) view returns (StackPointer)[ALL_STANDARD_OPS_LENGTH + 1];

    using AllStandardOps for uint256[ALL_STANDARD_OPS_LENGTH + 1];

    using LibUint256Array for uint256[];
    using LibConvert for uint256[];
    using LibCast for uint256[];
    using LibCast for function(
        IntegrityCheckState memory,
        Operand,
        StackPointer
    ) view returns (StackPointer);
    using LibCast for function(
        IntegrityCheckState memory,
        Operand,
        StackPointer
    ) pure returns (StackPointer);
    using LibCast for function(
        IntegrityCheckState memory,
        Operand,
        StackPointer
    ) view returns (StackPointer)[];
    using LibCast for function(InterpreterState memory, Operand, StackPointer)
        view
        returns (StackPointer)[];

    /// An oddly specific length conversion between a fixed and dynamic `uint256`
    /// array. This is useful for the purpose of building metadata for bounds
    /// checks and dispatch of all the standard ops provided by `Rainterpreter`.
    /// The cast will fail if the length of the dynamic array doesn't match the
    /// first item of the fixed array; it relies on differences in memory
    /// layout in Solidity that MAY change in the future. The rollback guards
    /// against changes in Solidity memory layout silently breaking this cast.
    /// @param fixed_ The fixed size `uint256` array to cast to a dynamic
    /// `uint256` array. Specifically the size is fixed to match the number of
    /// standard ops.
    /// @param dynamic_ The dynamic `uint256` array with length of the standard
    /// ops.
    function asUint256Array(
        function(IntegrityCheckState memory, Operand, StackPointer)
            view
            returns (StackPointer)[ALL_STANDARD_OPS_LENGTH + 1]
            memory fixed_
    ) internal pure returns (uint256[] memory dynamic_) {
        assembly ("memory-safe") {
            dynamic_ := fixed_
        }
        if (dynamic_.length != ALL_STANDARD_OPS_LENGTH) {
            revert BadDynamicLength(dynamic_.length, ALL_STANDARD_OPS_LENGTH);
        }
    }

    /// An oddly specific conversion between a fixed and dynamic `uint256` array.
    /// This is useful for the purpose of building function pointers for the
    /// runtime dispatch of all the standard ops provided by `Rainterpreter`.
    /// The cast will fail if the length of the dynamic array doesn't match the
    /// first item of the fixed array; it relies on differences in memory
    /// layout in Solidity that MAY change in the future. The rollback guards
    /// against changes in Solidity memory layout silently breaking this cast.
    /// @param fixed_ The fixed size `uint256` array to cast to a dynamic
    /// `uint256` array. Specifically the size is fixed to match the number of
    /// standard ops.
    /// @param dynamic_ The dynamic `uint256` array with length of the standard
    /// ops.
    function asUint256Array(
        function(InterpreterState memory, Operand, StackPointer)
            view
            returns (StackPointer)[ALL_STANDARD_OPS_LENGTH + 1]
            memory fixed_
    ) internal pure returns (uint256[] memory dynamic_) {
        assembly ("memory-safe") {
            dynamic_ := fixed_
        }
        if (dynamic_.length != ALL_STANDARD_OPS_LENGTH) {
            revert BadDynamicLength(dynamic_.length, ALL_STANDARD_OPS_LENGTH);
        }
    }

    /// Retype an integer to an integrity function pointer.
    /// @param u_ The integer to cast to an integrity function pointer.
    /// @return fn_ The integrity function pointer.
    function asIntegrityFunctionPointer(
        uint256 u_
    )
        internal
        pure
        returns (
            function(IntegrityCheckState memory, Operand, StackPointer)
                internal
                view
                returns (StackPointer) fn_
        )
    {
        assembly ("memory-safe") {
            fn_ := u_
        }
    }

    /// Retype a list of integrity check function pointers to a `uint256[]`.
    /// @param fns_ The list of function pointers.
    /// @return us_ The list of pointers as `uint256[]`.
    function asUint256Array(
        function(IntegrityCheckState memory, Operand, StackPointer)
            internal
            view
            returns (StackPointer)[]
            memory fns_
    ) internal pure returns (uint256[] memory us_) {
        assembly ("memory-safe") {
            us_ := fns_
        }
    }

    /// Retype a list of integers to integrity check function pointers.
    /// @param us_ The list of integers to use as function pointers.
    /// @return fns_ The list of integrity check function pointers.
    function asIntegrityPointers(
        uint256[] memory us_
    )
        internal
        pure
        returns (
            function(IntegrityCheckState memory, Operand, StackPointer)
                view
                returns (StackPointer)[]
                memory fns_
        )
    {
        assembly ("memory-safe") {
            fns_ := us_
        }
    }

    function integrityFunctionPointers()
        internal
        pure
        returns (
            function(IntegrityCheckState memory, Operand, StackPointer)
                view
                returns (StackPointer)[]
                memory pointers_
        )
    {
        unchecked {
            function(IntegrityCheckState memory, Operand, StackPointer)
                view
                returns (StackPointer)[ALL_STANDARD_OPS_LENGTH + 1]
                memory pointersFixed_ = [
                    asIntegrityFunctionPointer(ALL_STANDARD_OPS_LENGTH),
                    OpDecode256.integrity,
                    OpEncode256.integrity,
                    OpExplode32.integrity,
                    OpChainlinkOraclePrice.integrity,
                    OpContext.integrity,
                    OpContextColumnHash.integrity,
                    OpContextRow.integrity,
                    OpFoldContext.integrity,
                    OpCall.integrity,
                    OpDebug.integrity,
                    OpDoWhile.integrity,
                    OpExtern.integrity,
                    OpLoopN.integrity,
                    OpReadMemory.integrity,
                    OpHash.integrity,
                    OpERC1155BalanceOf.integrity,
                    OpERC1155BalanceOfBatch.integrity,
                    OpERC20BalanceOf.integrity,
                    OpERC20TotalSupply.integrity,
                    OpERC20SnapshotBalanceOfAt.integrity,
                    OpERC20SnapshotTotalSupplyAt.integrity,
                    OpERC5313Owner.integrity,
                    OpERC721BalanceOf.integrity,
                    OpERC721OwnerOf.integrity,
                    OpEnsure.integrity,
                    OpBlockNumber.integrity,
                    OpTimestamp.integrity,
                    OpAdd.integrity,
                    OpDiv.integrity,
                    OpExp.integrity,
                    OpMax.integrity,
                    OpMin.integrity,
                    OpMod.integrity,
                    OpMul.integrity,
                    OpSub.integrity,
                    OpFixedPointScale18.integrity,
                    OpFixedPointScale18Dynamic.integrity,
                    OpFixedPointScaleN.integrity,
                    OpAny.integrity,
                    OpEagerIf.integrity,
                    OpEqualTo.integrity,
                    OpEvery.integrity,
                    OpGreaterThan.integrity,
                    OpIsZero.integrity,
                    OpLessThan.integrity,
                    OpPRBAvg.integrity,
                    OpPRBCeil.integrity,
                    OpPRBDiv.integrity,
                    OpPRBExp.integrity,
                    OpPRBExp2.integrity,
                    OpPRBFloor.integrity,
                    OpPRBFrac.integrity,
                    OpPRBGm.integrity,
                    OpPRBInv.integrity,
                    OpPRBLn.integrity,
                    OpPRBLog10.integrity,
                    OpPRBLog2.integrity,
                    OpPRBMul.integrity,
                    OpPRBPow.integrity,
                    OpPRBPowu.integrity,
                    OpPRBSqrt.integrity,
                    OpSaturatingAdd.integrity,
                    OpSaturatingMul.integrity,
                    OpSaturatingSub.integrity,
                    OpIOrderBookV2VaultBalance.integrity,
                    OpISaleV2RemainingTokenInventory.integrity,
                    OpISaleV2Reserve.integrity,
                    OpISaleV2SaleStatus.integrity,
                    OpISaleV2Token.integrity,
                    OpISaleV2TotalReserveReceived.integrity,
                    OpIVerifyV1AccountStatusAtTime.integrity,
                    // Store
                    OpGet.integrity,
                    OpSet.integrity,
                    OpITierV2Report.integrity,
                    OpITierV2ReportTimeForTier.integrity,
                    OpSaturatingDiff.integrity,
                    OpSelectLte.integrity,
                    OpUpdateTimesForTierRange.integrity
                ];
            assembly ("memory-safe") {
                pointers_ := pointersFixed_
            }
        }
    }

    /// Retype an integer to an opcode function pointer.
    /// @param u_ The integer to cast to an opcode function pointer.
    /// @return fn_ The opcode function pointer.
    function asOpFunctionPointer(
        uint256 u_
    )
        internal
        pure
        returns (
            function(InterpreterState memory, Operand, StackPointer)
                view
                returns (StackPointer) fn_
        )
    {
        assembly ("memory-safe") {
            fn_ := u_
        }
    }

    /// Retype a list of interpreter opcode function pointers to a `uint256[]`.
    /// @param fns_ The list of function pointers.
    /// @return us_ The list of pointers as `uint256[]`.
    function asUint256Array(
        function(InterpreterState memory, Operand, StackPointer)
            view
            returns (StackPointer)[]
            memory fns_
    ) internal pure returns (uint256[] memory us_) {
        assembly ("memory-safe") {
            us_ := fns_
        }
    }

    function opcodeFunctionPointers() internal pure returns (bytes memory) {
        unchecked {
            function(InterpreterState memory, Operand, StackPointer)
                view
                returns (StackPointer)[ALL_STANDARD_OPS_LENGTH + 1]
                memory pointersFixed_ = [
                    asOpFunctionPointer(ALL_STANDARD_OPS_LENGTH),
                    OpDecode256.run,
                    OpEncode256.run,
                    OpExplode32.run,
                    OpChainlinkOraclePrice.run,
                    OpContext.run,
                    OpContextColumnHash.run,
                    OpContextRow.run,
                    OpFoldContext.run,
                    OpCall.run,
                    // 1.001kb
                    OpDebug.run,
                    OpDoWhile.run,
                    OpExtern.intern,
                    OpLoopN.run,
                    OpReadMemory.run,
                    OpHash.run,
                    OpERC1155BalanceOf.run,
                    OpERC1155BalanceOfBatch.run,
                    OpERC20BalanceOf.run,
                    OpERC20TotalSupply.run,
                    OpERC20SnapshotBalanceOfAt.run,
                    OpERC20SnapshotTotalSupplyAt.run,
                    OpERC5313Owner.run,
                    OpERC721BalanceOf.run,
                    OpERC721OwnerOf.run,
                    OpEnsure.run,
                    OpBlockNumber.run,
                    OpTimestamp.run,
                    OpAdd.run,
                    OpDiv.run,
                    OpExp.run,
                    OpMax.run,
                    OpMin.run,
                    OpMod.run,
                    OpMul.run,
                    OpSub.run,
                    OpFixedPointScale18.run,
                    OpFixedPointScale18Dynamic.run,
                    OpFixedPointScaleN.run,
                    OpAny.run,
                    OpEagerIf.run,
                    OpEqualTo.run,
                    OpEvery.run,
                    OpGreaterThan.run,
                    OpIsZero.run,
                    OpLessThan.run,
                    OpPRBAvg.run,
                    OpPRBCeil.run,
                    OpPRBDiv.run,
                    OpPRBExp.run,
                    OpPRBExp2.run,
                    OpPRBFloor.run,
                    OpPRBFrac.run,
                    OpPRBGm.run,
                    OpPRBInv.run,
                    OpPRBLn.run,
                    // 3.683kb
                    OpPRBLog10.run,
                    OpPRBLog2.run,
                    OpPRBMul.run,
                    OpPRBPow.run,
                    OpPRBPowu.run,
                    OpPRBSqrt.run,
                    OpSaturatingAdd.run,
                    OpSaturatingMul.run,
                    OpSaturatingSub.run,
                    OpIOrderBookV2VaultBalance.run,
                    OpISaleV2RemainingTokenInventory.run,
                    OpISaleV2Reserve.run,
                    OpISaleV2SaleStatus.run,
                    OpISaleV2Token.run,
                    OpISaleV2TotalReserveReceived.run,
                    OpIVerifyV1AccountStatusAtTime.run,
                    // Store
                    OpGet.run,
                    OpSet.run,
                    OpITierV2Report.run,
                    OpITierV2ReportTimeForTier.run,
                    OpSaturatingDiff.run,
                    OpSelectLte.run,
                    OpUpdateTimesForTierRange.run
                ];
            return
                LibConvert.unsafeTo16BitBytes(asUint256Array(pointersFixed_));
        }
    }
}