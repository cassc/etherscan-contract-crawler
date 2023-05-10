// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library AccusationsErrors {
    error NoTransactionInAccusedProposal();
    error HeightDeltaShouldBeOne(uint256 bClaimsHeight, uint256 pClaimsHeight);
    error PClaimsHeightsDoNotMatch(uint256 pClaims0Height, uint256 pClaims1Height);
    error ChainIdDoesNotMatch(
        uint256 bClaimsChainId,
        uint256 pClaimsChainId,
        uint256 snapshotsChainId
    );
    error SignersDoNotMatch(address signer1, address signer2);
    error SignerNotValidValidator(address signer);
    error UTXODoesnotMatch(bytes32 proofAgainstStateRootKey, bytes32 proofOfInclusionTxHashKey);
    error PClaimsRoundsDoNotMatch(uint32 pClaims0Round, uint32 pClaims1Round);
    error PClaimsChainIdsDoNotMatch(uint256 pClaims0ChainId, uint256 pClaims1ChainId);
    error InvalidChainId(uint256 pClaimsChainId, uint256 expectedChainId);
    error MerkleProofKeyDoesNotMatchConsumedDepositKey(
        bytes32 proofOfInclusionTxHashKey,
        bytes32 proofAgainstStateRootKey
    );
    error MerkleProofKeyDoesNotMatchUTXOIDBeingSpent(
        bytes32 utxoId,
        bytes32 proofAgainstStateRootKey
    );
    error SignatureVerificationFailed();
    error PClaimsAreEqual();
    error SignatureLengthMustBe65Bytes(uint256 signatureLength);
    error InvalidSignatureVersion(uint8 signatureVersion);
    error ExpiredAccusation(uint256 accusationHeight, uint256 latestSnapshotHeight, uint256 epoch);
    error InvalidMasterPublicKey(bytes32 signature);
}