// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './utils/NiftysMetadataERC721A.sol';
import './royalties/NiftysContractWideRoyalties.sol';
import './operatorFilter/DefaultOperatorFilterer.sol';
import './721ALib/ERC721A.sol';
import './721ALib/extensions/ERC721ABurnable.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

error MaxIssuanceSet();
error MaxIssuanceReached();
error NonceAlreadyUsed();
error MintAuthorizationExpired();
error ArrayLengthMismatch();
error Unauthorized();

abstract contract NiftysERC721A is
    ERC721A,
    ERC721ABurnable,
    NiftysMetadataERC721A,
    NiftysContractWideRoyalties,
    DefaultOperatorFilterer
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
    ) ERC721A(name, symbol) DefaultOperatorFilterer(owner) {
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

    function burn(uint256 tokenId) public override {
        if (_msgSender() != ownerOf(tokenId)) revert TransferFromIncorrectOwner();
        _burn(tokenId);
    }

    function burnFrom(uint256 tokenId) public {
        _burn(tokenId, true);
    }

    function getContractHash() public view returns (bytes32) {
        return keccak256(abi.encode(block.chainid, address(this)));
    }

    function hashMintData(
        address to,
        uint256 quantity,
        bytes32 nonce,
        uint256 expires
    ) public view returns (bytes32) {
        return keccak256(abi.encode(getContractHash(), abi.encode(to, quantity, nonce, expires)));
    }

    function validateSignature(
        address to,
        uint256 quantity,
        bytes32 nonce,
        uint256 expires,
        bytes memory sig
    ) internal view returns (bool) {
        address signer = hashMintData(to, quantity, nonce, expires)
            .toEthSignedMessageHash()
            .recover(sig);
        return hasRole(SIGNER, signer);
    }

    function mint(address to, uint256 quantity) external isMinter whenNotPaused {
        _mint(to, quantity);
    }

    function mintBatch(address[] calldata tos, uint256[] calldata quantities)
        external
        isMinter
        whenNotPaused
    {
        if (tos.length != quantities.length) revert ArrayLengthMismatch();

        unchecked {
            for (uint256 i = 0; i < tos.length; i++) {
                _mint(tos[i], quantities[i]);
            }
        }
    }

    function authorizedMint(
        address to,
        uint256 quantity,
        bytes32 nonce,
        uint256 expires,
        bytes memory sig
    ) external whenNotPaused {
        if (validateSignature(to, quantity, nonce, expires, sig) == false) revert Unauthorized();
        if (expires < block.timestamp) revert MintAuthorizationExpired();
        if (nonces[nonce]) revert NonceAlreadyUsed();

        nonces[nonce] = true;
        _mint(to, quantity);
    }

    // Overides

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _mint(address to, uint256 quantity) internal virtual override {
        unchecked {
            uint256 totalIssuance = _totalMinted() + quantity;

            if (maxIssuance > 0 && totalIssuance > maxIssuance) revert MaxIssuanceReached();
        }

        super._mint(to, quantity);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A, IERC721A, NiftysMetadataERC721A)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _baseURI()
        internal
        view
        virtual
        override(ERC721A, NiftysMetadataERC721A)
        returns (string memory)
    {
        return super._baseURI();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC721A, NiftysContractWideRoyalties, NiftysAccessControl)
        returns (bool)
    {
        return
            interfaceId == type(NiftysContractWideRoyalties).interfaceId ||
            interfaceId == type(NiftysMetadataERC721A).interfaceId ||
            interfaceId == type(NiftysAccessControl).interfaceId ||
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f ||
            interfaceId == 0x2a55205a;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}