// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract TEST is
    ERC721AUpgradeable,
    ERC2981Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    DefaultOperatorFiltererUpgradeable
{
    string private _name;
    string private _symbol;
    string private _contractUri;
    string public baseUri;
    string public LICENSE;
    bytes32 public merkleRoot;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory __name,
        string memory __symbol,
        string memory __contractUri,
        string memory _baseUri,
        string memory _licenseUri,
        bytes32 _merkleRoot,
        address recipient,
        uint96 value
    ) public initializerERC721A {
        _name = __name;
        _symbol = __symbol;
        _contractUri = __contractUri;
        baseUri = _baseUri;
        LICENSE = _licenseUri;
        merkleRoot = _merkleRoot;
        _setDefaultRoyalty(recipient, value);
        __ERC721A_init(_name, _symbol);
        __Ownable_init();
    }

    /// @notice The name of the ERC721 token.
    function name()
        public
        view
        override(ERC721AUpgradeable)
        returns (string memory)
    {
        return _name;
    }

    /// @notice The symbol of the ERC721 token.
    function symbol()
        public
        view
        override(ERC721AUpgradeable)
        returns (string memory)
    {
        return _symbol;
    }

    /// @notice Sets the name and symbol of the ERC721 token.
    /// @param newName The new name for the token.
    /// @param newSymbol The new symbol for the token.
    function setNameAndSymbol(
        string calldata newName,
        string calldata newSymbol
    ) external onlyOwner {
        _name = newName;
        _symbol = newSymbol;
    }

    /// @notice The token base URI.
    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    /// @notice Sets the base URI for the token metadata.
    /// @param newBaseUri The new base URI for the token metadata.
    function setBaseUri(string calldata newBaseUri) external onlyOwner {
        baseUri = newBaseUri;
    }

    function setLicenseUri(string calldata licenseUri) external onlyOwner {
        LICENSE = licenseUri;
    }

    /// @notice Sets the URI for the contract metadata.
    /// @param newContractUri The new contract URI for contract metadata.
    function setContractURI(string calldata newContractUri) external onlyOwner {
        _contractUri = newContractUri;
    }

    /// @notice Sets the contract URI for marketplace listings.
    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /// @notice Pauses the contract, preventing token transfers.
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract, allowing token transfers.
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Mints multiple tokens and assigns them to the specified addresses.
    /// @param to An array of addresses to which tokens will be minted.
    /// @param value An array of values representing the number of tokens to mint for each address.
    function mintMany(
        address[] calldata to,
        uint256[] calldata value
    ) external onlyOwner {
        require(to.length == value.length, "Mismatched lengths");
        unchecked {
            for (uint256 i = 0; i < to.length; i++) {
                _mint(to[i], value[i]);
            }
        }
    }

    function generateFontHash(
        uint256 tokenId,
        uint8[][] calldata fontSignature
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(tokenId, fontSignature));
    }

    function generateFontHashes(
        uint256[] calldata tokenIds,
        uint8[][][] calldata fontSignatures
    ) public pure returns (bytes32[] memory) {
        require(tokenIds.length == fontSignatures.length, "Mismatched lengths");
        bytes32[] memory hashes = new bytes32[](tokenIds.length);
        unchecked {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                hashes[i] = generateFontHash(tokenIds[i], fontSignatures[i]);
            }
        }
        return hashes;
    }

    function verifyFontSignatureInMerkle(
        uint256 tokenId,
        uint8[][] calldata fontSignature,
        bytes32[] calldata proof
    ) public view returns (bool) {
        bytes32 hash = generateFontHash(tokenId, fontSignature);
        return MerkleProof.verify(proof, merkleRoot, hash);
    }

    function verifyFontHashesInMerkle(
        bytes32[] calldata fontHashes,
        bytes32[][] calldata proofs
    ) public view returns (bool[] memory) {
        require(fontHashes.length == proofs.length, "Mismatched lengths");
        bool[] memory validities = new bool[](fontHashes.length);
        unchecked {
            for (uint256 i = 0; i < fontHashes.length; i++) {
                validities[i] = MerkleProof.verify(
                    proofs[i],
                    merkleRoot,
                    fontHashes[i]
                );
            }
        }
        return validities;
    }

    /// @notice Sets the royalty fee for the specified recipient.
    /// @param recipient The address of the royalty recipient.
    /// @param value The value of the royalty fee.
    function setRoyalties(address recipient, uint96 value) public onlyOwner {
        _setDefaultRoyalty(recipient, value);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    )
        public
        override(ERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
        whenNotPaused
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        payable
        override(ERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
        whenNotPaused
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override(ERC721AUpgradeable)
        onlyAllowedOperator(from)
        whenNotPaused
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override(ERC721AUpgradeable)
        onlyAllowedOperator(from)
        whenNotPaused
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        payable
        override(ERC721AUpgradeable)
        onlyAllowedOperator(from)
        whenNotPaused
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /// @dev Supports `interfaceId`s for IERC165, IERC721, IERC721Metadata, IERC2981
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721AUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return
            ERC721AUpgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    function _startTokenId()
        internal
        pure
        override(ERC721AUpgradeable)
        returns (uint256)
    {
        return 1;
    }
}