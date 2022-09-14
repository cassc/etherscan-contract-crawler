// SPDX-License-Identifier: MIT

// Original source: https://github.com/ensdomains/offchain-resolver/blob/2bc616f19a94370828c35f29f71d5d4cab3a9a4f/packages/contracts/contracts/SignatureVerifier.sol

pragma solidity ^0.8.13;

import { ECDSAUpgradeable } from "openzeppelin/utils/cryptography/ECDSAUpgradeable.sol";

library SignatureVerifierUpgradeable {
    /// @dev Prefix with 0x1900 to prevent the preimage from being a valid ethereum transaction.
    bytes2 private constant _PREIMAGE_PREFIX = 0x1900;

    /**
     * @dev Generates a hash for signing/verifying.
     * @param target The address the signature is for.
     * @param expires Time at which the signature expires.
     * @param request The original request that was sent.
     * @param result The `result` field of the response (not including the signature part).
     * @return Hashed data for signing and verifying.
     */
    function makeSignatureHash(
        address target,
        uint64 expires,
        bytes calldata request,
        bytes memory result
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _PREIMAGE_PREFIX,
                    target,
                    expires,
                    keccak256(request),
                    keccak256(result)
                )
            );
    }

    /**
     * @notice A valid non-expired response can still contain stale data
     * if the offchain data changes during the expiry duration before decoding the response.
     * @dev Verifies a signed message returned from a callback.
     * @param request The original request that was sent.
     * @param response An ABI encoded tuple of `(bytes result, uint64 expires, bytes sig)`, where `result` is the data to return
     *        to the caller, and `sig` is the (r,s,v) encoded message signature.
     * @return signer The address that signed this message.
     * @return result The `result` decoded from `response`.
     */
    function verify(bytes calldata request, bytes calldata response)
        internal
        view
        returns (address, bytes memory)
    {
        (bytes memory result, uint64 expires, bytes memory sig) = abi.decode(
            response,
            (bytes, uint64, bytes)
        );

        bytes32 r;
        bytes32 s;
        uint8 v;
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        /// @solidity memory-safe-assembly
        assembly {
            r := mload(add(sig, 0x20))
            s := mload(add(sig, 0x40))
            v := byte(0, mload(add(sig, 0x60)))
        }

        require(
            expires >= block.timestamp,
            "SignatureVerifier::verify: Signature expired"
        );

        bytes32 sigHash = makeSignatureHash(
            address(this),
            expires,
            request,
            result
        );

        address signer = ECDSAUpgradeable.recover(sigHash, sig);

        return (signer, result);
    }
}