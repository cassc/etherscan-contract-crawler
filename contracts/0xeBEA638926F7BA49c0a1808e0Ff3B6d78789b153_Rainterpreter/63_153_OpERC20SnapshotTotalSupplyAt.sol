// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import {ERC20SnapshotUpgradeable as ERC20Snapshot} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20SnapshotUpgradeable.sol";
import "../../../run/LibStackPointer.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityCheck.sol";

/// @title OpERC20SnapshotTotalSupplyAt
/// @notice Opcode for Open Zeppelin `ERC20Snapshot.totalSupplyAt`.
/// https://docs.openzeppelin.com/contracts/4.x/api/token/erc20#ERC20Snapshot
library OpERC20SnapshotTotalSupplyAt {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(
        uint256 token_,
        uint256 snapshotId_
    ) internal view returns (uint256) {
        return
            ERC20Snapshot(address(uint160(token_))).totalSupplyAt(snapshotId_);
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.applyFn(stackTop_, f);
    }

    function run(
        InterpreterState memory,
        Operand,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFn(f);
    }
}