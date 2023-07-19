// SPDX-License-Identifier: MIT

pragma solidity =0.8.15;

import '@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import 'hardhat/console.sol';

struct FractalProof {
    bytes proof;
    uint256 validUntil;
    uint256 approvedAt;
    string fractalId;
}

abstract contract CredentialVerifier {
    function check(
        address verifier,
        string memory expectedCredential,
        uint256 maxAge,
        FractalProof calldata proof
    ) private view {
        require(block.timestamp < proof.validUntil, 'Credential no longer valid');

        require(
            maxAge == 0 || block.timestamp < proof.approvedAt + maxAge,
            'Approval not recent enough'
        );

        string memory sender = Strings.toHexString(uint256(uint160(msg.sender)), 20);
        bytes32 message = ECDSA.toEthSignedMessageHash(
            abi.encodePacked(
                sender,
                ';',
                proof.fractalId,
                ';',
                Strings.toString(proof.approvedAt),
                ';',
                Strings.toString(proof.validUntil),
                ';',
                expectedCredential
            )
        );

        console.log(
            'message',
            string(
                abi.encodePacked(
                    sender,
                    ';',
                    proof.fractalId,
                    ';',
                    Strings.toString(proof.approvedAt),
                    ';',
                    Strings.toString(proof.validUntil),
                    ';',
                    expectedCredential
                )
            )
        );
        console.log('proof.proof', proof.proof.length);
        console.logBytes(proof.proof);

        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(
            message,
            proof.proof
        );
        if (error == ECDSA.RecoverError.NoError) console.log('recovered', recovered);

        require(
            SignatureChecker.isValidSignatureNow(verifier, message, proof.proof),
            "Signature doesn't match"
        );
    }

    modifier requiresCredential(
        address verifier,
        string memory expectedCredential,
        uint256 maxAge,
        FractalProof calldata proof
    ) {
        check(verifier, expectedCredential, maxAge, proof);
        _;
    }
}