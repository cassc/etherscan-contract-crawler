// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

/* Signature Verification

How to Sign and Verify
# Signing
1. Create message to sign
2. Hash the message
3. Sign the hash (off chain, keep your private key secret)

# Verify
1. Recreate hash from the original message
2. Recover signer from signature and hash
3. Compare recovered signer to claimed signer
*/
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract VerifySignature {
    function getMessageHash(
        address _to,
        uint256 _blockNumber,
        bytes32 _blockHash,
        string memory _ipfsHash,
        uint256 _price
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _to,
                    _blockNumber,
                    _blockHash,
                    _ipfsHash,
                    _price
                )
            );
    }

    function verifySig(
        address _to,
        uint256 _blockNumber,
        bytes32 _blockHash,
        string memory _ipfsHash,
        uint256 _price,
        address _signer,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(
            _to,
            _blockNumber,
            _blockHash,
            _ipfsHash,
            _price
        );
        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(
            messageHash
        );
        return ECDSA.recover(ethSignedMessageHash, signature) == _signer;
    }
}