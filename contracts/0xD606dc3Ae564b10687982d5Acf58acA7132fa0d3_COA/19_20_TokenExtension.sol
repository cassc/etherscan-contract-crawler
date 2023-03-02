// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./SCOA.sol";
import "./Errors.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";

contract TokenExtension is ERC1155 {
    using Strings for uint256;
    using Strings for address;

    enum TokenType {
        INVALID,
        IDENTITY,
        DELETED_IDENTITY,
        CERTIFICATE,
        DELETED_CERTIFICATE
    }

    mapping(bytes32 => bool) public usedSignatures; // signature => used
    mapping(uint256 => SCOA.Identity) public identity; // tokenId => Identity
    mapping(uint256 => SCOA.Certificate) public certificate; // tokenId => Certificate
    mapping(uint256 => TokenType) public tokenType; // tokenId => TokenType

    uint256 private _tokenId; // current tokenId

    /**
     * @dev Modifier to check if the identity exists
     */
    modifier identityExists(uint256 tokenId_) {
        // check if the identity exists
        if (tokenType[tokenId_] != TokenType.IDENTITY) {
            revert IdentityDoesNotExist(tokenId_);
        }
        _;
    }

    /**
     * @dev Modifier to check if the certificate exists
     */
    modifier certificateExists(uint256 tokenId_) {
        // check if the certificate exists
        if (tokenType[tokenId_] != TokenType.CERTIFICATE) {
            revert CertificateDoesNotExist(tokenId_);
        }
        _;
    }

    constructor() ERC1155("COA") {}

    /**
     * @dev check if the certificate is valid
     * @param tokenId_ the certificate tokenId
     * @return true if the certificate is valid
     */
    function validCertificate(
        uint256 tokenId_
    ) external view certificateExists(tokenId_) returns (bool) {
        SCOA.Certificate memory cert = certificate[tokenId_];
        return tokenType[cert.identity] == TokenType.IDENTITY;
    }

    /**
     * @dev get the token uri
     * @param tokenId_ the token id
     * @return the token uri
     */
    function uri(uint256 tokenId_) public view virtual override returns (string memory) {
        TokenType tType = tokenType[tokenId_];
        if (tType == TokenType.INVALID) {
            revert TokenDoesNotExist(tokenId_);
        }
        // get the metadata based on tokenType
        string memory metadata = getMetadata(tType, tokenId_);
        // return the metadata
        return (string(abi.encodePacked("data:application/json;utf8,", metadata)));
    }

    /**
     * @dev get the metadata based on the token type
     * @param tokenType_ the token type
     * @param tokenId_ the token id
     */
    function getMetadata(
        TokenType tokenType_,
        uint256 tokenId_
    ) public view returns (string memory) {
        // check the token type
        if (tokenType_ == TokenType.IDENTITY) {
            // return the identity metadata
            return identityMetadata(tokenId_);
        } else if (tokenType_ == TokenType.CERTIFICATE) {
            // return the certificate metadata
            return certificateMetadata(tokenId_);
        } else if (tokenType_ == TokenType.DELETED_CERTIFICATE) {
            // return the deleted certificate metadata
            return deletedCertificateMetadata();
        }
        revert TokenDoesNotExist(tokenId_);
    }

    /**
     * @dev get the identity metadata
     * @param tokenId_ the token id
     * @return the identity metadata
     */
    function identityMetadata(uint256 tokenId_) public view returns (string memory) {
        // get the identity
        SCOA.Identity memory id = identity[tokenId_];
        // return the metadata
        return
            string(
                abi.encodePacked(
                    '{"name": "Valence Identity",',
                    '"description": "Registered identity","attributes":[',
                    '{"trait_type": "owner", "value": "',
                    id.owner.toHexString(),
                    '"},{"trait_type": "AuthorityId", "value": "',
                    id.authority.toHexString(),
                    '"},{"trait_type": "Namespace", "value": "',
                    id.alicePTR.namespace.toHexString(),
                    '"},{"trait_type": "Curve", "value": "',
                    uint256(id.alicePTR.curve).toString(),
                    '"},{"trait_type": "Index", "value": "',
                    _bytesToHex(abi.encodePacked(id.alicePTR.index)),
                    '"}'
                    "]}"
                )
            );
    }

    /**
     * @dev get the certificate metadata
     * @param tokenId_ the token id
     * @return the certificate metadata
     */
    function certificateMetadata(uint256 tokenId_) public view returns (string memory) {
        // get the certificate
        SCOA.Certificate memory cert = certificate[tokenId_];
        // return the metadata
        return
            string(
                abi.encodePacked(
                    '{"name": "Valence Certificate", "description": "These are certificates made by a registered identity","attributes":[',
                    '{"trait_type": "Creator", "value": "',
                    cert.identity.toString(),
                    '"},{"trait_type": "Namespace", "value": "',
                    cert.alicePTR.namespace.toHexString(),
                    '"},{"trait_type": "Curve", "value": "',
                    uint256(cert.alicePTR.curve).toString(),
                    '"},{"trait_type": "Index", "value": "',
                    _bytesToHex(abi.encodePacked(cert.alicePTR.index)),
                    '"}',
                    "]}"
                )
            );
    }

    /**
     * @dev get the latest token id
     * @return the latest token id
     */
    function getLatestID() public view returns (uint256) {
        return _tokenId;
    }

    /**
     * @dev get the deleted certificate metadata
     * @return the deleted certificate metadata
     */
    function deletedCertificateMetadata() public pure returns (string memory) {
        // return the metadata
        return
            string(
                abi.encodePacked(
                    '{"name": "Valence Certificate", "description": "These are certificates made by a registered identity","attributes":[',
                    '{"trait_type": "Deleted", "value": "True"}',
                    "]}"
                )
            );
    }

    /**
     * @dev mint a new identity token
     * @param to_ the address to mint the token to
     * @param identity_ the identity to mint
     */
    function _mintIdentity(address to_, SCOA.Identity calldata identity_) internal {
        // get next tokenId
        uint256 tokenId = _newTokenId();
        // set the identity
        identity[tokenId] = identity_;
        // set the tokenType
        tokenType[tokenId] = TokenType.IDENTITY;
        // mint the token
        _mint(to_, tokenId, 1, "");
    }

    /**
     * @dev mint a new certificate token
     * @param to_ the address to mint the token to
     * @param certificate_ the certificate to mint
     */
    function _mintCertificate(address to_, SCOA.Certificate calldata certificate_) internal {
        // get next tokenId
        uint256 tokenId = _newTokenId();
        // set the certificate
        certificate[tokenId] = certificate_;
        // set the tokenType
        tokenType[tokenId] = TokenType.CERTIFICATE;
        // mint the
        _mint(to_, tokenId, 1, "");
    }

    /**
     * @dev clone a certificate token
     * @param to_ the address to mint the token to
     * @param tokenId_ the token id to clone
     */
    function _cloneCertificate(
        address to_,
        uint256 tokenId_,
        uint256 amount_
    ) internal certificateExists(tokenId_) {
        // mint the token
        _mint(to_, tokenId_, amount_, "");
    }

    /**
     * @dev update an identity
     * @param tokenId_ the token id to update
     * @param identity_ the new identity
     */
    function _updateIdentity(
        uint256 tokenId_,
        SCOA.Identity calldata identity_
    ) internal identityExists(tokenId_) {
        SCOA.Identity memory oldIdentity = identity[tokenId_];
        if (oldIdentity.owner != identity_.owner || oldIdentity.authority != identity_.authority) {
            revert UpdatedIdentityMismatch(
                identity_.owner,
                oldIdentity.owner,
                identity_.authority,
                oldIdentity.authority
            );
        }
        // update the identity
        identity[tokenId_] = identity_;
    }

    /**
     * @dev update a certificate
     * @param tokenId_ the token id to update
     * @param certificate_ the new certificate
     */
    function _updateCertificate(
        uint256 tokenId_,
        SCOA.Certificate calldata certificate_
    ) internal certificateExists(tokenId_) {
        SCOA.Certificate memory oldCertificate = certificate[tokenId_];
        if (oldCertificate.identity != certificate_.identity) {
            revert UpdatedCertificateIdentityMismatch(
                certificate_.identity,
                oldCertificate.identity
            );
        }
        // update the certificate
        certificate[tokenId_] = certificate_;
    }

    /**
     * @dev delete an identity
     * @param tokenId_ the token id to delete
     */
    function _deleteIdentity(uint256 tokenId_) internal identityExists(tokenId_) {
        // set tokenType to deleted
        tokenType[tokenId_] = TokenType.DELETED_IDENTITY;
        // burn the token
        _burn(identity[tokenId_].owner, tokenId_, 1);
        // delete the identity
        delete identity[tokenId_];
    }

    /**
     * @dev delete a certificate
     * @param tokenId_ the token id to delete
     */
    function _deleteCertificate(uint256 tokenId_) internal certificateExists(tokenId_) {
        // set tokenType to deleted. User should call burn to remove the token
        tokenType[tokenId_] = TokenType.DELETED_CERTIFICATE;
    }

    /**
     * @dev burn a certificate
     * @param tokenId_ the token id to burn
     * @param amount_ the amount to burn
     */
    function _burnCertificates(
        address certificateOwner,
        uint256 tokenId_,
        uint256 amount_
    ) internal {
        // check the tokenType
        if (
            tokenType[tokenId_] != TokenType.CERTIFICATE &&
            tokenType[tokenId_] != TokenType.DELETED_CERTIFICATE
        ) {
            revert CannotOnlyBurnCertificate(tokenId_);
        }
        // burn the token
        _burn(certificateOwner, tokenId_, amount_);
    }

    /**
     * @dev get the next tokenId
     * @return the next tokenId
     */
    function _newTokenId() internal returns (uint256) {
        // increment the tokenId
        _tokenId++;
        // return the tokenId
        return _tokenId;
    }

    /**
     * @dev before token transfer hook to prevent transferring identity tokens
     */
    function _beforeTokenTransfer(
        address /*operator*/,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory /*amounts*/,
        bytes memory /*data*/
    ) internal virtual override {
        for (uint256 i = 0; i < ids.length; i++) {
            if (from == address(0) || to == address(0)) {
                continue;
            }
            if (tokenType[ids[i]] == TokenType.IDENTITY) {
                revert CannotTransferIdentity(ids[i]);
            }
        }
    }

    /**
     * @dev turn bytes into hex string
     * @param buffer the bytes to convert
     * @return the hex string
     */
    function _bytesToHex(bytes memory buffer) internal pure returns (string memory) {
        bytes memory converted = new bytes(buffer.length * 2);
        bytes memory _base = "0123456789abcdef";
        for (uint256 i = 0; i < buffer.length; i++) {
            converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
            converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
        }
        return string(abi.encodePacked("0x", converted));
    }
}