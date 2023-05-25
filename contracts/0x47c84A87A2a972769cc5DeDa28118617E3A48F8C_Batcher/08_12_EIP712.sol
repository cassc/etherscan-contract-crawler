// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @title EIP712
/// @author 0xAd1
/// @notice Used to verify signatures
contract EIP712 {
    /// @notice Verifies a signature against alleged signer of the signature
    /// @param signature Signature to verify
    /// @param authority Signer of the signature
    /// @return True if the signature is signed by authority
    function verifySignatureAgainstAuthority(
        address recipient,
        bytes memory signature,
        address authority
    ) internal view returns (bool) {
        bytes32 eip712DomainHash = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("Batcher")),
                keccak256(bytes("1")),
                1,
                address(this)
            )
        );

        bytes32 hashStruct = keccak256(
            abi.encode(keccak256("deposit(address owner)"), recipient)
        );

        bytes32 hash = keccak256(
            abi.encodePacked("\x19\x01", eip712DomainHash, hashStruct)
        );

        address signer = ECDSA.recover(hash, signature);
        require(signer == authority, "ECDSA: Invalid authority");
        require(signer != address(0), "ECDSA: invalid signature");
        return true;
    }
}