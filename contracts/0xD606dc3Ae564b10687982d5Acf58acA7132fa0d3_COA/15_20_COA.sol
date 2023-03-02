// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./SCOA.sol";
import "./TokenExtension.sol";
import "./AccessExtension.sol";

contract COA is TokenExtension, AccessExtension {
    /**
     * @dev Modifier to check if the sender is the owner of the identity or has the delete role.
     */
    modifier isOwnerOrAuthorized(uint256 tokenId_) {
        // check if the sender has correct permissions
        if (
            identity[tokenId_].owner != msg.sender &&
            identity[certificate[tokenId_].identity].owner != msg.sender &&
            !hasRole(UPDATE_DELETE_ROLE, msg.sender)
        ) {
            revert NotAuthorized(msg.sender, tokenId_); // revert if the sender is not authorized
        }
        _;
    }

    /**
     * @dev Modifier to check if the sender is the owner of the identity or has the delete role.
     */
    modifier isCertificateOwnerOrAuthorized(address from_, uint256 tokenId_) {
        // check if the sender has correct permissions
        if (
            from_ != msg.sender &&
            identity[certificate[tokenId_].identity].owner != msg.sender &&
            !hasRole(UPDATE_DELETE_ROLE, msg.sender)
        ) {
            revert NotAuthorized(msg.sender, tokenId_); // revert if the sender is not authorized
        }
        _;
    }

    modifier isUnique(bytes calldata signature_) {
        bytes32 sigHash = keccak256(signature_);
        // check if the signature hash is unique
        if (usedSignatures[sigHash]) {
            revert SignatureNotUnique(signature_); // revert if the signature is not unique
        }
        usedSignatures[sigHash] = true;
        _;
    }

    constructor() {}

    /**
     * @dev Creates a new identity.
     * @param identity_ The identity to mint, struct containing the address of the owner, AlicePTR, and address of authority.
     * @param signature_ The signature of the identity from signer with CREATE_ROLE.
     */
    function createIdentity(
        SCOA.Identity calldata identity_,
        bytes calldata signature_
    ) public isUnique(signature_) {
        // verify that the signature is valid
        _checkSignature(identity_, signature_);
        // mint the identity to its owner
        _mintIdentity(identity_.owner, identity_);
    }

    /**
     * @dev Creates multiple new identities.
     * @param identity_ The identities to mint.
     * @param signature_ The signatures of the identities from signer with CREATE_ROLE.
     */
    function createIdentity(
        SCOA.Identity[] calldata identity_,
        bytes[] calldata signature_
    ) external {
        // loop through the array of identities to create
        if (identity_.length != signature_.length) {
            revert MismatchedInputLengths();
        }
        for (uint256 i = 0; i < identity_.length; i++) {
            // create each identity
            createIdentity(identity_[i], signature_[i]);
        }
    }

    /**
     * @dev Create a certificate.
     * @param certificate_ The certificate to mint.
     * @param signature_ The signature of the certificate from signer with CREATE_ROLE.
     */
    function createCertificate(
        address to_,
        SCOA.Certificate calldata certificate_,
        bytes calldata signature_
    ) public isUnique(signature_) identityExists(certificate_.identity) {
        address authority = identity[certificate_.identity].owner;
        _checkSignature(to_, certificate_, authority, signature_);
        // mint the certificate
        _mintCertificate(to_, certificate_);
    }

    /**
     * @dev Create multiple certificates.
     * @param certificate_ The certificates to mint.
     * @param signature_ The signatures of the certificates from signer with CREATE_ROLE.
     */
    function createCertificate(
        address[] calldata to_,
        SCOA.Certificate[] calldata certificate_,
        bytes[] calldata signature_
    ) external {
        // loop through the array of certificates to create
        if (to_.length != certificate_.length || certificate_.length != signature_.length) {
            revert MismatchedInputLengths();
        }
        for (uint256 i = 0; i < certificate_.length; i++) {
            // create each certificate
            createCertificate(to_[i], certificate_[i], signature_[i]);
        }
    }

    /**
     * @dev clone a certificate.
     * @param to_ The address to clone the certificate to.
     * @param tokenId_ The token id of the certificate to clone.
     */
    function cloneCertificate(address to_, uint256 tokenId_) public isOwnerOrAuthorized(tokenId_) {
        // clone the certificate
        _cloneCertificate(to_, tokenId_, 1);
    }

    /**
     * @dev clone a certificate.
     * @param to_ The address to clone the certificate to.
     * @param tokenId_ The token id of the certificate to clone.
     */
    function cloneCertificate(
        address to_,
        uint256 tokenId_,
        uint256 amount
    ) public isOwnerOrAuthorized(tokenId_) {
        // clone the certificate
        _cloneCertificate(to_, tokenId_, amount);
    }

    /**
     * @dev clone multiple certificates.
     * @param to_ The addresses to clone the certificates to.
     * @param tokenId_ The token ids of the certificates to clone.
     */
    function cloneCertificate(address[] calldata to_, uint256[] calldata tokenId_) external {
        if (to_.length != tokenId_.length) {
            revert MismatchedInputLengths();
        }
        // loop through the array of certificates to clone
        for (uint256 i = 0; i < tokenId_.length; i++) {
            // clone each certificate
            cloneCertificate(to_[i], tokenId_[i]);
        }
    }

    /**
     * @dev read an identity.
     * @param tokenId_ The token id of the identity to read.
     */
    function readIdentity(
        uint256 tokenId_
    ) public view identityExists(tokenId_) returns (SCOA.Identity memory) {
        // return the identity
        return identity[tokenId_];
    }

    /**
     * @dev read multiple identities.
     * @param tokenId_ The token ids of the identities to read.
     */
    function readIdentity(
        uint256[] calldata tokenId_
    ) external view returns (SCOA.Identity[] memory) {
        // create an array of identities
        SCOA.Identity[] memory ids = new SCOA.Identity[](tokenId_.length);
        // loop through the array of token ids
        for (uint256 i = 0; i < tokenId_.length; i++) {
            // read each identity and add it to the array of identities
            ids[i] = readIdentity(tokenId_[i]);
        }
        // return the array of identities
        return ids;
    }

    /**
     * @dev read a certificate.
     * @param tokenId_ The token id of the certificate to read.
     */
    function readCertificate(
        uint256 tokenId_
    ) public view certificateExists(tokenId_) returns (SCOA.Certificate memory) {
        // return the certificate
        return certificate[tokenId_];
    }

    /**
     * @dev read multiple certificates.
     * @param tokenId_ The token ids of the certificates to read.
     */
    function readCertificate(
        uint256[] calldata tokenId_
    ) external view returns (SCOA.Certificate[] memory) {
        // create an array of certificates
        SCOA.Certificate[] memory certs = new SCOA.Certificate[](tokenId_.length);
        // loop through the array of token ids
        for (uint256 i = 0; i < tokenId_.length; i++) {
            // read each certificate and add it to the array of certificates
            certs[i] = readCertificate(tokenId_[i]);
        }
        // return the array of certificates
        return certs;
    }

    /**
     * @dev update an identity.
     * @param tokenId_ The token id of the identity to update.
     * @param identity_ The new identity.
     */
    function updateIdentity(
        uint256 tokenId_,
        SCOA.Identity calldata identity_
    ) public isOwnerOrAuthorized(tokenId_) {
        // update the identity
        _updateIdentity(tokenId_, identity_);
    }

    /**
     * @dev update multiple identities.
     * @param tokenId_ The token ids of the identities to update.
     * @param identity_ The new identities.
     */
    function updateIdentity(
        uint256[] calldata tokenId_,
        SCOA.Identity[] calldata identity_
    ) external {
        // loop through the array of token ids
        for (uint256 i = 0; i < tokenId_.length; i++) {
            // update each identity
            updateIdentity(tokenId_[i], identity_[i]);
        }
    }

    /**
     * @dev update a certificate.
     * @param tokenId_ The token id of the certificate to update.
     * @param certificate_ The new certificate.
     */
    function updateCertificate(
        uint256 tokenId_,
        SCOA.Certificate calldata certificate_
    ) public isOwnerOrAuthorized(tokenId_) {
        // update the certificate
        _updateCertificate(tokenId_, certificate_);
    }

    /**
     * @dev update multiple certificates.
     * @param tokenId_ The token ids of the certificates to update.
     * @param certificate_ The new certificates.
     */
    function updateCertificate(
        uint256[] calldata tokenId_,
        SCOA.Certificate[] calldata certificate_
    ) external {
        // loop through the array of token ids
        for (uint256 i = 0; i < tokenId_.length; i++) {
            // update each certificate
            updateCertificate(tokenId_[i], certificate_[i]);
        }
    }

    /**
     * @dev delete an identity.
     * @param tokenId_ The token id of the identity to delete.
     */
    function deleteIdentity(uint256 tokenId_) public isOwnerOrAuthorized(tokenId_) {
        // delete the identity
        _deleteIdentity(tokenId_);
    }

    /**
     * @dev delete multiple identities.
     * @param tokenId_ The token ids of the identities to delete.
     */
    function deleteIdentity(uint256[] calldata tokenId_) external {
        // loop through the array of token ids
        for (uint256 i = 0; i < tokenId_.length; i++) {
            // delete each identity
            deleteIdentity(tokenId_[i]);
        }
    }

    /**
     * @dev delete a certificate.
     * @param tokenId_ The token id of the certificate to delete.
     */
    function deleteCertificate(uint256 tokenId_) public isOwnerOrAuthorized(tokenId_) {
        // delete the certificate
        _deleteCertificate(tokenId_);
    }

    /**
     * @dev delete multiple certificates.
     * @param tokenId_ The token ids of the certificates to delete.
     */
    function deleteCertificate(uint256[] calldata tokenId_) external {
        // loop through the array of token ids
        for (uint256 i = 0; i < tokenId_.length; i++) {
            // delete each certificate
            deleteCertificate(tokenId_[i]);
        }
    }

    /**
     * @dev burn certificate token.
     * @param tokenId_ The token id of the certificate to burn.
     * @param amount_ The amount of the certificate to burn.
     */
    function burnCertificate(
        address from_,
        uint256 tokenId_,
        uint256 amount_
    ) public isCertificateOwnerOrAuthorized(from_, tokenId_) {
        // burn the certificate
        _burnCertificates(from_, tokenId_, amount_);
    }

    /**
     * @dev burn multiple certificate tokens.
     * @param tokenId_ The token ids of the certificates to burn.
     * @param amount_ The amounts of the certificates to burn.
     */
    function burnCertificate(
        address[] calldata from_,
        uint256[] calldata tokenId_,
        uint256[] calldata amount_
    ) external {
        // loop through the array of token ids
        for (uint256 i = 0; i < tokenId_.length; i++) {
            // burn each certificate
            burnCertificate(from_[i], tokenId_[i], amount_[i]);
        }
    }

    /**
     * @dev supportInterface function to support ERC1155 & AccessControl interface.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId); // return the interface ID
    }
}