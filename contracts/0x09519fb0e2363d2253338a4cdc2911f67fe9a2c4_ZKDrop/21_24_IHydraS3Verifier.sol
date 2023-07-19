// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract IHydraS3Verifier {
  error InvalidProof();
  error CallToVerifyProofFailed();
  error InvalidSismoIdentifier(bytes32 userId, uint8 authType);
  error OnlyOneAuthAndOneClaimIsSupported();

  error InvalidVersion(bytes32 version);
  error RegistryRootNotAvailable(uint256 inputRoot);
  error DestinationMismatch(address destinationFromProof, address expectedDestination);
  error CommitmentMapperPubKeyMismatch(
    bytes32 expectedX,
    bytes32 expectedY,
    bytes32 inputX,
    bytes32 inputY
  );

  error ClaimTypeMismatch(uint256 claimTypeFromProof, uint256 expectedClaimType);
  error RequestIdentifierMismatch(
    uint256 requestIdentifierFromProof,
    uint256 expectedRequestIdentifier
  );
  error InvalidExtraData(uint256 extraDataFromProof, uint256 expectedExtraData);
  error ClaimValueMismatch();
  error DestinationVerificationNotEnabled();
  error SourceVerificationNotEnabled();
  error AccountsTreeValueMismatch(
    uint256 accountsTreeValueFromProof,
    uint256 expectedAccountsTreeValue
  );
  error VaultNamespaceMismatch(uint256 vaultNamespaceFromProof, uint256 expectedVaultNamespace);
  error UserIdMismatch(uint256 userIdFromProof, uint256 expectedUserId);
}