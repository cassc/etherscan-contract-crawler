// SPDX-License-Identifier: CAL
pragma solidity =0.8.18;

import "sol.lib.datacontract/LibDataContract.sol";

import "../ops/AllStandardOps.sol";
import "rain.interface.interpreter/LibEncodedDispatch.sol";
import "../../kv/LibMemoryKV.sol";
import "rain.interface.interpreter/IInterpreterStoreV1.sol";
import {MathUpgradeable as Math} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import {IERC165Upgradeable as IERC165} from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

/// @title Rainterpreter
/// @notice Minimal binding of the `IIinterpreterV1` interface to the
/// `LibInterpreterState` library, including every opcode in `AllStandardOps`.
/// This is the default implementation of "an interpreter" but is designed such
/// that other interpreters can easily be developed alongside. Alterpreters can
/// either be built by inheriting and overriding the functions on this contract,
/// or using the relevant libraries to construct an alternative binding to the
/// same interface.
contract Rainterpreter is IInterpreterV1, IERC165 {
    using LibStackPointer for StackPointer;
    using LibInterpreterState for bytes;
    using LibInterpreterState for InterpreterState;
    using LibCast for function(InterpreterState memory, Operand, StackPointer)
        view
        returns (StackPointer)[];
    using Math for uint256;
    using LibMemoryKV for MemoryKV;
    using LibMemoryKV for MemoryKVPtr;
    using LibInterpreterState for StateNamespace;

    // @inheritdoc IERC165
    function supportsInterface(
        bytes4 interfaceId_
    ) public view virtual override returns (bool) {
        return
            interfaceId_ == type(IInterpreterV1).interfaceId ||
            interfaceId_ == type(IERC165).interfaceId;
    }

    /// @inheritdoc IInterpreterV1
    function eval(
        IInterpreterStoreV1 store_,
        StateNamespace namespace_,
        EncodedDispatch dispatch_,
        uint256[][] memory context_
    ) external view returns (uint256[] memory, uint256[] memory) {
        // Decode the dispatch.
        (
            address expression_,
            SourceIndex sourceIndex_,
            uint256 maxOutputs_
        ) = LibEncodedDispatch.decode(dispatch_);

        // Build the interpreter state from the onchain expression.
        InterpreterState memory state_ = LibDataContract
            .read(expression_)
            .deserialize();
        state_.stateKV = MemoryKV.wrap(0);
        state_.namespace = namespace_.qualifyNamespace();
        state_.store = store_;
        state_.context = context_;

        // Eval the expression and return up to maxOutputs_ from the final stack.
        StackPointer stackTop_ = state_.eval(sourceIndex_, state_.stackBottom);
        uint256 stackLength_ = state_.stackBottom.toIndex(stackTop_);
        (, uint256[] memory tail_) = stackTop_.list(
            stackLength_.min(maxOutputs_)
        );
        return (tail_, state_.stateKV.toUint256Array());
    }

    /// @inheritdoc IInterpreterV1
    function functionPointers() external view virtual returns (bytes memory) {
        return AllStandardOps.opcodeFunctionPointers();
    }
}