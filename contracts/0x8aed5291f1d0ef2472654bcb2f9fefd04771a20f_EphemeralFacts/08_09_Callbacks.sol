/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.0;

/**
 * @notice Helper for providing fair gas limits in callbacks, adapted from Chainlink
 */
library Callbacks {
    // 5k is plenty for an EXTCODESIZE call (2600) + warm CALL (100)
    // and some arithmetic operations.
    uint256 private constant GAS_FOR_CALL_EXACT_CHECK = 5_000;

    /**
     * @notice calls target address with exactly gasAmount gas and data as calldata
     *         or reverts if at least gasAmount gas is not available.
     * @param gasAmount the exact amount of gas to call with
     * @param target the address to call
     * @param data the calldata to pass
     * @return success whether the call succeeded
     */
    function callWithExactGas(
        uint256 gasAmount,
        address target,
        bytes memory data
    ) internal returns (bool success, bytes memory result) {
        // solhint-disable-next-line no-inline-assembly
        uint256 returnsize;
        assembly {
            function notEnoughGas() {
                // revert Error("not enough gas for call")
                mstore(0x00, hex"08c379a000000000000000000000000000000000000000000000000000000000")
                mstore(0x20, hex"0000002000000000000000000000000000000000000000000000000000000000")
                mstore(0x40, hex"0000001b6e6f7420656e6f7567682067617320666f722063616c6c0000000000")
                revert(0, 0x60)
            }
            function notContract() {
                // revert Error("call target not contract")
                mstore(0x00, hex"08c379a000000000000000000000000000000000000000000000000000000000")
                mstore(0x20, hex"0000002000000000000000000000000000000000000000000000000000000000")
                mstore(0x40, hex"0000001a63616c6c20746172676574206e6f74206120636f6e74726163740000")
                revert(0, 0x60)
            }
            let g := gas()
            // Compute g -= GAS_FOR_CALL_EXACT_CHECK and check for underflow
            // The gas actually passed to the callee is min(gasAmount, 63//64*gas available).
            // We want to ensure that we revert if gasAmount >  63//64*gas available
            // as we do not want to provide them with less, however that check itself costs
            // gas.  GAS_FOR_CALL_EXACT_CHECK ensures we have at least enough gas to be able
            // to revert if gasAmount >  63//64*gas available.
            if lt(g, GAS_FOR_CALL_EXACT_CHECK) {
                notEnoughGas()
            }
            g := sub(g, GAS_FOR_CALL_EXACT_CHECK)
            // if g - g//64 <= gasAmount, revert
            // (we subtract g//64 because of EIP-150)
            if iszero(gt(sub(g, div(g, 64)), gasAmount)) {
                notEnoughGas()
            }
            // solidity calls check that a contract actually exists at the destination, so we do the same
            if iszero(extcodesize(target)) {
                notContract()
            }
            // call and return whether we succeeded. ignore return data
            // call(gas,addr,value,argsOffset,argsLength,retOffset,retLength)
            success := call(gasAmount, target, 0, add(data, 0x20), mload(data), 0, 0)
            returnsize := returndatasize()
        }
        // copy the return data
        result = new bytes(returnsize);
        assembly {
            returndatacopy(add(result, 0x20), 0, returnsize)
        }
    }

    /**
     * @notice reverts the current call with the provided raw data
     * @param data the revert data to return
     */
    function revertWithData(bytes memory data) internal pure {
        assembly {
            revert(add(data, 0x20), mload(data))
        }
    }
}