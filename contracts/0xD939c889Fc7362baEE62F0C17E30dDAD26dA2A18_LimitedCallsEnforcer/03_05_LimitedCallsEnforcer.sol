//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {BytesLib} from "../libraries/BytesLib.sol";
import "../CaveatEnforcer.sol";

contract LimitedCallsEnforcer is CaveatEnforcer {
    mapping(address => mapping(bytes32 => uint256)) callCounts;

    function enforceCaveat(
        bytes calldata terms,
        Transaction calldata,
        bytes32 delegationHash
    ) public override returns (bool) {
        uint256 limit = BytesLib.toUint256(terms, 0);
        uint256 callCount = callCounts[msg.sender][delegationHash];
        require(callCount < limit, "LimitedCallsEnforcer:limit-exceeded");
        callCounts[msg.sender][delegationHash]++;
        return true;
    }
}