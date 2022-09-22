// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './utils/NiftysAccessControl.sol';
import './utils/NiftysMetadataERC721.sol';
import './royalties/NiftysContractWideRoyalties.sol';

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';

import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

error MaxIssuanceSet();
error MaxIssuanceReached();
error NonceAlreadyUsed();
error MintAuthorizationExpired();
error ArrayLengthMismatch();
error Unauthorized();

abstract contract NiftysERC721 is
    ERC721,
    NiftysMetadataERC721,
    NiftysContractWideRoyalties,
    NiftysAccessControl
{
    using ECDSA for bytes32;

    uint256 public maxIssuance;

    mapping(bytes32 => bool) public nonces;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        string memory contractURI,
        address royaltyrecipient,
        uint24 royaltyvalue,
        address owner
    ) ERC721(name, symbol) NiftysAccessControl(owner) {
        _setBaseURI(baseTokenURI);
        _setContractURI(contractURI);
        _setRoyalties(royaltyrecipient, royaltyvalue);
    }

    function setMaxIssuance(uint256 _maxIssuance) external isAdmin {
        if (maxIssuance > 0) revert MaxIssuanceSet();
        maxIssuance = _maxIssuance;
    }

    function setRoyalties(address recipient, uint24 value) external isAdmin {
        _setRoyalties(recipient, value);
    }

    function setContractURI(string memory contractURI) external isAdmin {
        _setContractURI(contractURI);
    }

    function setBaseURI(string memory uri) external isAdmin {
        _setBaseURI(uri);
    }

    function setTokenURI(uint256 tokenId, string memory tokenURI_) external isAdmin {
        _setTokenURI(tokenId, tokenURI_);
    }

    function burn(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            'ERC721Burnable: caller is not owner nor approved'
        );
        _burn(tokenId);
    }

    function getContractHash() public view returns (bytes32) {
        return keccak256(abi.encode(block.chainid, address(this)));
    }

    function hashMintData(
        address to,
        uint256 id,
        bytes32 nonce,
        uint256 expires
    ) public view returns (bytes32) {
        return keccak256(abi.encode(getContractHash(), abi.encode(to, id, nonce, expires)));
    }

    function validateSignature(
        address to,
        uint256 id,
        bytes32 nonce,
        uint256 expires,
        bytes memory sig
    ) internal view returns (bool) {
        address signer = hashMintData(to, id, nonce, expires).toEthSignedMessageHash().recover(sig);
        return hasRole(SIGNER, signer);
    }

    function mint(address to, uint256 id) external isMinter whenNotPaused {
        _mint(to, id);
    }

    function mintBatch(address[] calldata tos, uint256[] calldata ids)
        external
        isMinter
        whenNotPaused
    {
        _mintBatch(tos, ids);
    }

    function _mintBatch(address[] calldata tos, uint256[] calldata ids) internal {
        if (tos.length != ids.length) revert ArrayLengthMismatch();

        unchecked {
            for (uint256 i = 0; i < tos.length; i++) {
                _mint(tos[i], ids[i]);
            }
        }
    }

    function authorizedMint(
        address to,
        uint256 id,
        bytes32 nonce,
        uint256 expires,
        bytes memory sig
    ) external whenNotPaused {
        if (validateSignature(to, id, nonce, expires, sig) == false) revert Unauthorized();
        if (expires < block.timestamp) revert MintAuthorizationExpired();
        if (nonces[nonce]) revert NonceAlreadyUsed();

        nonces[nonce] = true;
        _mint(to, id);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, NiftysMetadataERC721)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _baseURI()
        internal
        view
        virtual
        override(ERC721, NiftysMetadataERC721)
        returns (string memory)
    {
        return super._baseURI();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, NiftysContractWideRoyalties, NiftysAccessControl)
        returns (bool)
    {
        return
            interfaceId == type(NiftysContractWideRoyalties).interfaceId ||
            interfaceId == type(NiftysMetadataERC721).interfaceId ||
            interfaceId == type(NiftysAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}