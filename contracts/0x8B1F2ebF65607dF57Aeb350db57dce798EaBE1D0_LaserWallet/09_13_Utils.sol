// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

import "../interfaces/IEIP1271.sol";

/**
 * @title Utils - Helper functions for Laser wallet and modules.
 */
library Utils {
    /*//////////////////////////////////////////////////////////////
                            Errors
    //////////////////////////////////////////////////////////////*/

    error Utils__returnSigner__invalidSignature();

    error Utils__returnSigner__invalidContractSignature();

    /**
     * @param signedHash  The hash that was signed.
     * @param signatures  Result of signing the has.
     * @param pos         Position of the signer.
     *
     * @return signer      Address that signed the hash.
     */
    function returnSigner(
        bytes32 signedHash,
        bytes memory signatures,
        uint256 pos
    ) internal view returns (address signer) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        (r, s, v) = splitSigs(signatures, pos);

        if (v == 0) {
            // If v is 0, then it is a contract signature.
            // The address of the contract is encoded into r.
            signer = address(uint160(uint256(r)));

            // The signature(s) of the EOA's that control the target contract.
            bytes memory contractSignature;

            assembly {
                contractSignature := add(add(signatures, s), 0x20)
            }

            if (IEIP1271(signer).isValidSignature(signedHash, contractSignature) != 0x1626ba7e) {
                revert Utils__returnSigner__invalidContractSignature();
            }
        } else if (v > 30) {
            signer = ecrecover(
                keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", signedHash)),
                v - 4,
                r,
                s
            );
        } else {
            signer = ecrecover(signedHash, v, r, s);
        }

        if (signer == address(0)) revert Utils__returnSigner__invalidSignature();
    }

    /**
     * @dev Returns the r, s and v values of the signature.
     *
     * @param pos Which signature to read.
     */
    function splitSigs(bytes memory signatures, uint256 pos)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        assembly {
            let sigPos := mul(0x41, pos)
            r := mload(add(signatures, add(sigPos, 0x20)))
            s := mload(add(signatures, add(sigPos, 0x40)))
            v := byte(0, mload(add(signatures, add(sigPos, 0x60))))
        }
    }

    /**
     * @dev Calls a target address, sends value and / or data payload.
     *
     * @param to     Destination address.
     * @param value  Amount in WEI to transfer.
     * @param callData   Data payload for the transaction.
     */
    function call(
        address to,
        uint256 value,
        bytes memory callData,
        uint256 txGas
    ) internal returns (bool success) {
        assembly {
            success := call(txGas, to, value, add(callData, 0x20), mload(callData), 0, 0)
        }
    }

    /**
     * @dev Calculates the gas price for the transaction.
     */
    function calculateGasPrice(uint256 maxFeePerGas, uint256 maxPriorityFeePerGas) internal view returns (uint256) {
        if (maxFeePerGas == maxPriorityFeePerGas) {
            // Legacy mode (pre-EIP1559)
            return min(maxFeePerGas, tx.gasprice);
        }

        // EIP-1559
        // priority_fee_per_gas = min(transaction.max_priority_fee_per_gas, transaction.max_fee_per_gas - block.base_fee_per_gas)
        // effective_gas_price = priority_fee_per_gas + block.base_fee_per_gas
        uint256 priorityFeePerGas = min(maxPriorityFeePerGas, maxFeePerGas - block.basefee);

        // effective_gas_price
        return priorityFeePerGas + block.basefee;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}