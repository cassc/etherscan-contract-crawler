// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract SignedRedeemer {
    using ECDSA for bytes32;

    address public signer;

    constructor(address signer_) {
        signer = signer_;
    }

    /**
     * @notice Uses ECDSA to validate the provided signature was signed by the known address.
     */
    /**
     * @dev For a given unique ordered array of tokenIds,
     * a valid signature is a message keccack256(abi.encode(owner, tokenIds)) signed by the known address.
     */
    /// @param signature Signed message
    /// @param tokenIds ordered unique array of tokenIds encoded in the signed message
    /// @param to token owner encoded in the signed message
    function validateSignature(
        bytes memory signature,
        uint256[] calldata tokenIds, // must be in numeric order
        address to
    ) public view returns (bool) {
        bytes memory message = abi.encode(to, tokenIds);
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(keccak256(message));
        address recovered = messageHash.recover(signature);
        return signer == recovered;
    }

    function _setSigner(address signer_) internal {
        signer = signer_;
    }
}