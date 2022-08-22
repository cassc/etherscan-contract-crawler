//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../CaveatEnforcer.sol";
import {BytesLib} from "../libraries/BytesLib.sol";

contract TimestampEnforcer is CaveatEnforcer {
    function enforceCaveat(
        bytes calldata terms,
        Transaction calldata tx,
        bytes32 delegationHash
    ) public override returns (bool) {
        uint128 logicOperator = BytesLib.toUint128(terms, 0);
        uint128 blockExpiration = BytesLib.toUint128(terms, 16);
        if (logicOperator == 0) {
            if (blockExpiration < block.timestamp) {
                return true;
            } else {
                revert("TimestampEnforcer:expired-delegation");
            }
        } else {
            if (blockExpiration > block.timestamp) {
                return true;
            } else {
                revert("TimestampEnforcer:early-delegation");
            }
        }
    }
}