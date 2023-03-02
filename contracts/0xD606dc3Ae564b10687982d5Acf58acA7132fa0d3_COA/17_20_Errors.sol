// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error SignatureNotUnique(bytes signature); // error for when the signature is not unique
error InvalidIdentityOwner(address owner); // error for when the identity owner is invalid
error IdentityDoesNotExist(uint256 tokenId); // error for when the identity does not exist
error CertificateDoesNotExist(uint256 tokenId); // error for when the certificate does not exist
error InvalidSignature(bytes signature); // error for when the signature is invalid
error CannotTransferIdentity(uint256 tokenId); // error for when the identity cannot be transferred
error InvalidCertificateOwner(uint256 tokenId); // error for when the certificate owner is invalid
error NotAuthorized(address sender, uint256 tokenId); // error for when the sender is not authorized
error CannotCloneIdentity(uint256 tokenId); // error for when the identity cannot be cloned
error CannotOnlyBurnCertificate(uint256 tokenId_); // error for when the certificate cannot be burned
error TokenDoesNotExist(uint256 tokenId); // error for when the token does not exist
error UpdatedCertificateIdentityMismatch(uint256 newIdentity, uint256 oldIdentity); // error for when the certificate identity does not match
error UpdatedIdentityMismatch(
    address newOwner,
    address oldOwner,
    address newAuthority,
    address oldAuthority
); // error for when the identity does not match during an identity update
error MismatchedInputLengths(); // error for when the input lengths do not match