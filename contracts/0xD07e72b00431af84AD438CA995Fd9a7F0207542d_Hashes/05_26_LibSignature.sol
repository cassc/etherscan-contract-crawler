// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

// solhint-disable max-line-length
/**
 * @notice A library for validating signatures.
 * @dev Much of this file was taken from the LibSignature implementation found at:
 *      https://github.com/0xProject/protocol/blob/development/contracts/zero-ex/contracts/src/features/libs/LibSignature.sol
 */
// solhint-enable max-line-length
library LibSignature {
    // Exclusive upper limit on ECDSA signatures 'R' values. The valid range is
    // given by fig (282) of the yellow paper.
    uint256 private constant ECDSA_SIGNATURE_R_LIMIT =
        uint256(0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141);

    // Exclusive upper limit on ECDSA signatures 'S' values. The valid range is
    // given by fig (283) of the yellow paper.
    uint256 private constant ECDSA_SIGNATURE_S_LIMIT = ECDSA_SIGNATURE_R_LIMIT / 2 + 1;

    /**
     * @dev Retrieve the signer of a signature. Throws if the signature can't be
     *      validated.
     * @param _hash The hash that was signed.
     * @param _signature The signature.
     * @return The recovered signer address.
     */
    function getSignerOfHash(bytes32 _hash, bytes memory _signature) internal pure returns (address) {
        require(_signature.length == 65, "LibSignature: Signature length must be 65 bytes.");

        // Get the v, r, and s values from the signature.
        uint8 v = uint8(_signature[0]);
        bytes32 r;
        bytes32 s;
        assembly {
            r := mload(add(_signature, 0x21))
            s := mload(add(_signature, 0x41))
        }

        // Enforce the signature malleability restrictions.
        validateSignatureMalleabilityLimits(v, r, s);

        // Recover the signature without pre-hashing.
        address recovered = ecrecover(_hash, v, r, s);

        // `recovered` can be null if the signature values are out of range.
        require(recovered != address(0), "LibSignature: Bad signature data.");
        return recovered;
    }

    /**
     * @notice Validates the malleability limits of an ECDSA signature.
     *
     *         Context:
     *
     *         EIP-2 still allows signature malleability for ecrecover(). Remove
     *         this possibility and make the signature unique. Appendix F in the
     *         Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf),
     *         defines the valid range for r in (282): 0 < r < secp256k1n, the
     *         valid range for s in (283): 0 < s < secp256k1n ÷ 2 + 1, and for v
     *         in (284): v ∈ {27, 28}. Most signatures from current libraries
     *         generate a unique signature with an s-value in the lower half order.
     *
     *         If your library generates malleable signatures, such as s-values
     *         in the upper range, calculate a new s-value with
     *         0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1
     *         and flip v from 27 to 28 or vice versa. If your library also
     *         generates signatures with 0/1 for v instead 27/28, add 27 to v to
     *         accept these malleable signatures as well.
     *
     * @param _v The v value of the signature.
     * @param _r The r value of the signature.
     * @param _s The s value of the signature.
     */
    function validateSignatureMalleabilityLimits(
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) private pure {
        // Ensure the r, s, and v are within malleability limits. Appendix F of
        // the Yellow Paper stipulates that all three values should be checked.
        require(uint256(_r) < ECDSA_SIGNATURE_R_LIMIT, "LibSignature: r parameter of signature is invalid.");
        require(uint256(_s) < ECDSA_SIGNATURE_S_LIMIT, "LibSignature: s parameter of signature is invalid.");
        require(_v == 27 || _v == 28, "LibSignature: v parameter of signature is invalid.");
    }
}