// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;
import "../interfaces/ISignatureVerifier.sol";

contract SignatureVerifier is ISignatureVerifier {
    error InvalidSigLength();

    /// @inheritdoc ISignatureVerifier
    function recoverSigner(
        uint256 destChainSlug_,
        uint256 packetId_,
        bytes32 root_,
        bytes calldata signature_
    ) external pure override returns (address signer) {
        bytes32 digest = keccak256(
            abi.encode(destChainSlug_, packetId_, root_)
        );
        digest = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", digest)
        );
        signer = _recoverSigner(digest, signature_);
    }

    /**
     * @notice returns the address of signer recovered from input signature
     */
    function _recoverSigner(
        bytes32 hash_,
        bytes memory signature_
    ) private pure returns (address signer) {
        (bytes32 sigR, bytes32 sigS, uint8 sigV) = _splitSignature(signature_);

        // recovered signer is checked for the valid roles later
        signer = ecrecover(hash_, sigV, sigR, sigS);
    }

    /**
     * @notice splits the signature into v, r and s.
     */
    function _splitSignature(
        bytes memory signature_
    ) private pure returns (bytes32 r, bytes32 s, uint8 v) {
        if (signature_.length != 65) revert InvalidSigLength();
        assembly {
            r := mload(add(signature_, 0x20))
            s := mload(add(signature_, 0x40))
            v := byte(0, mload(add(signature_, 0x60)))
        }
    }
}