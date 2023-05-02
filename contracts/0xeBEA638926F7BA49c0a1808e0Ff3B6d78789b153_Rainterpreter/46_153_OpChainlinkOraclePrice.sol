// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import {LibChainlink} from "../../../chainlink/LibChainlink.sol";
import "../../run/LibStackPointer.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";

/// @title OpChainlinkOraclePrice
/// @notice Opcode for chainlink oracle prices.
library OpChainlinkOraclePrice {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(
        uint256 feed_,
        uint256 staleAfter_
    ) internal view returns (uint256) {
        return LibChainlink.price(address(uint160(feed_)), staleAfter_);
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