// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import 'operator-filter-registry/src/DefaultOperatorFilterer.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract NFTypePixelcurve is ERC721AQueryable, ERC2981, Ownable, Pausable, DefaultOperatorFilterer {
   string private _name;
   string private _symbol;
   string private _contractUri;
   string public baseUri;
   string public LICENSE;
   bytes32 public merkleRoot;

   constructor(
      string memory __name,
      string memory __symbol,
      string memory __contractUri,
      string memory _baseUri,
      string memory _licenseUri,
      bytes32 _merkleRoot,
      address recipient,
      uint96 value
   ) ERC721A(_name, _symbol) {
      _name = __name;
      _symbol = __symbol;
      _contractUri = __contractUri;
      baseUri = _baseUri;
      LICENSE = _licenseUri;
      merkleRoot = _merkleRoot;
      _setDefaultRoyalty(recipient, value);
      _mint(0x71eB375e705Ce1f07e67738B21Ca32C5Ee9D6346, 1);
      _mint(0xe9D51EFe9276515DcE0cf1D58aB4C3A948FE85A7, 950);
      _mint(0x48D963295e39dE7163449670DdDfe577cdd59A72, 49);
   }

   /// @notice The name of the ERC721 token.
   function name() public view override(ERC721A, IERC721A) returns (string memory) {
      return _name;
   }

   /// @notice The symbol of the ERC721 token.
   function symbol() public view override(ERC721A, IERC721A) returns (string memory) {
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

   /// @notice Sets the URI for the license that governs the fonts under this collection.
   /// @param licenseUri The new license URI.
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

   /// @notice Sets the Merkle root for verifying font signatures.
   /// @param _merkleRoot The new Merkle root.
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
   function mintMany(address[] calldata to, uint256[] calldata value) external onlyOwner {
      require(to.length == value.length, 'Mismatched lengths');
      unchecked {
         for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i], value[i]);
         }
      }
   }

   /// @notice Generates a hash for a font signature associated with a given token ID.
   /// @param tokenId The ID of the token.
   /// @param fontSignature The signature of the font associated with the token.
   /// @return The generated font hash.
   function generateFontHash(
      uint256 tokenId,
      uint8[][] calldata fontSignature
   ) public pure returns (bytes32) {
      return keccak256(abi.encode(tokenId, fontSignature));
   }

   /// @notice Generates a set of font hashes for an array of token IDs and their corresponding font signatures.
   /// @param tokenIds An array of token IDs.
   /// @param fontSignatures An array of font signatures corresponding to the token IDs.
   /// @return An array of generated font hashes.
   function generateFontHashes(
      uint256[] calldata tokenIds,
      uint8[][][] calldata fontSignatures
   ) public pure returns (bytes32[] memory) {
      require(tokenIds.length == fontSignatures.length, 'Mismatched lengths');
      bytes32[] memory hashes = new bytes32[](tokenIds.length);
      unchecked {
         for (uint256 i = 0; i < tokenIds.length; i++) {
            hashes[i] = generateFontHash(tokenIds[i], fontSignatures[i]);
         }
      }
      return hashes;
   }

   /// @notice Verifies a font signature within the Merkle tree.
   /// @param tokenId The ID of the token.
   /// @param fontSignature The signature of the font associated with the token.
   /// @param proof The Merkle proof for verification.
   /// @return Whether the font signature is valid.
   function verifyFontSignatureInMerkle(
      uint256 tokenId,
      uint8[][] calldata fontSignature,
      bytes32[] calldata proof
   ) public view returns (bool) {
      bytes32 hash = generateFontHash(tokenId, fontSignature);
      return MerkleProof.verify(proof, merkleRoot, hash);
   }

   /// @notice Verifies an array of font hashes within the Merkle tree.
   /// @param fontHashes An array of font hashes to verify.
   /// @param proofs An array of corresponding Merkle proofs for verification.
   /// @return An array of boolean values indicating the validity of each font hash.
   function verifyFontHashesInMerkle(
      bytes32[] calldata fontHashes,
      bytes32[][] calldata proofs
   ) public view returns (bool[] memory) {
      require(fontHashes.length == proofs.length, 'Mismatched lengths');
      bool[] memory validities = new bool[](fontHashes.length);
      unchecked {
         for (uint256 i = 0; i < fontHashes.length; i++) {
            validities[i] = MerkleProof.verify(proofs[i], merkleRoot, fontHashes[i]);
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
   ) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) whenNotPaused {
      super.setApprovalForAll(operator, approved);
   }

   function approve(
      address operator,
      uint256 tokenId
   )
      public
      payable
      override(ERC721A, IERC721A)
      onlyAllowedOperatorApproval(operator)
      whenNotPaused
   {
      super.approve(operator, tokenId);
   }

   function transferFrom(
      address from,
      address to,
      uint256 tokenId
   ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) whenNotPaused {
      super.transferFrom(from, to, tokenId);
   }

   function safeTransferFrom(
      address from,
      address to,
      uint256 tokenId
   ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) whenNotPaused {
      super.safeTransferFrom(from, to, tokenId);
   }

   function safeTransferFrom(
      address from,
      address to,
      uint256 tokenId,
      bytes memory data
   ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) whenNotPaused {
      super.safeTransferFrom(from, to, tokenId, data);
   }

   /// @dev Supports `interfaceId`s for IERC165, IERC721, IERC721Metadata, IERC2981
   function supportsInterface(
      bytes4 interfaceId
   ) public view override(ERC721A, IERC721A, ERC2981) returns (bool) {
      return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
   }

   /// @dev Start tokenId at 1
   function _startTokenId() internal pure override(ERC721A) returns (uint256) {
      return 1;
   }
}