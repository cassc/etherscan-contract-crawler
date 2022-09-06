//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../CaveatEnforcer.sol";

contract AllowedMethodsEnforcer is CaveatEnforcer {
    function enforceCaveat(
        bytes calldata terms,
        Transaction calldata transaction,
        bytes32 delegationHash
    ) public pure override returns (bool) {
        bytes4 targetSig = bytes4(transaction.data[0:4]);
        for (uint256 i = 0; i < terms.length; i += 4) {
            bytes4 allowedSig = bytes4(terms[i:i + 4]);
            if (allowedSig == targetSig) {
                return true;
            }
        }
        revert("AllowedMethodsEnforcer:method-not-allowed");
    }
}