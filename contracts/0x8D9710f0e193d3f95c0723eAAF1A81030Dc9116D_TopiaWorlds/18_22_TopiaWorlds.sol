// SPDX-License-Identifier: MIT
//
// ...............   ...............   ...............  .....   ...............
// :==============.  ===============  :==============:  -====  .==============-
// :==============.  ===============  :==============:  -====  .==============-
// :==============.  ===============  :==============:  -====  .==============-
// :==============.  ===============  :==============:  -====  .==============-
// .::::-====-::::.  ===============  :====-:::::::::.  -====  .====-::::-====-
//      :====.       ===============  :====:            -====  .====:    .====-
//      :====.       ===============  :====:            -====  .====:    .====-
//
// Learn more at https://topia.gg or Twitter @TOPIAgg

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./modules/Upgradeable/Upgradeable.sol";
import "./Storage.sol";

contract TopiaWorlds is DefaultOperatorFilterer, ERC721, Upgradeable {
  using ECDSA for bytes32;
  using Strings for uint256;

  event WorldUpdated(uint256 indexed tokenId, string ipfsHash);

  constructor(address _nftw, address _updateApprover) ERC721("TOPIA Worlds", "TOPIA Worlds") {
    Storage.layout().nftw = INFTW(_nftw);
    Storage.layout().updateApprover = _updateApprover;
  }

  /**
   * Airdrop Functions
   */

  function airdrop(uint256[] calldata _tokenIds, address[] calldata _recipients) external onlyOwner {
    require(_tokenIds.length == _recipients.length, "_tokenIds and _recipients length mismatch");

    for (uint256 i = 0; i < _tokenIds.length; i++) {
      require(_tokenIds[i] > 0 && _tokenIds[i] <= 10000, "Invalid token id");
      _mint(_recipients[i], _tokenIds[i]);
    }
  }

  function airdropDevelopedWorld(uint256[] calldata _tokenIds, address[] calldata _recipients, string[] calldata _ipfsHashes) external onlyOwner {
    require(_tokenIds.length == _recipients.length, "_tokenIds and _recipients length mismatch");
    require(_recipients.length == _ipfsHashes.length, "_recipients and _ipfsHashes length mismatch");

    for (uint256 i = 0; i < _tokenIds.length; i++) {
      require(_tokenIds[i] > 0 && _tokenIds[i] <= 10000, "Invalid token id");
      _mint(_recipients[i], _tokenIds[i]);
      Storage.layout().ipfsHashes[_tokenIds[i]] = _ipfsHashes[i];
    }
  }

  /**
   * Metadata Functions
   */

  function setTokenBaseURI(string memory _baseURI) external onlyOwner checkForUpgrade {
    Storage.layout().tokenBaseURI = _baseURI;
  }

  function setIPFSBaseUri(string memory _baseURI) external onlyOwner checkForUpgrade {
    Storage.layout().ipfsBaseURI = _baseURI;
  }

  function setUpdateApprover(address _updateApprover) external onlyOwner checkForUpgrade {
    Storage.layout().updateApprover = _updateApprover;
  }

  function updateWorld(uint256 _tokenId, string calldata _ipfsHash, uint256 _nonce, bytes calldata _updateApproverSignature) external tokenExists(_tokenId) checkForUpgrade {
    require(_msgSender() == ownerOf(_tokenId), "You are not the owner of this token.");
    require(!Storage.layout().usedUpdateNonces[_nonce], "Update already performed.");
    require(
      keccak256(
        abi.encode(
          _tokenId,
          _ipfsHash,
          _nonce,
          msg.sender
        )
      )
      .toEthSignedMessageHash()
      .recover(_updateApproverSignature) == Storage.layout().updateApprover,
      "Invalid signature, update not approved."
    );

    Storage.layout().ipfsHashes[_tokenId] = _ipfsHash;
    Storage.layout().usedUpdateNonces[_nonce] = true;

    emit WorldUpdated(_tokenId, _ipfsHash);
  }

  function resetWorld(uint256 _tokenId) external tokenExists(_tokenId) checkForUpgrade {
    require(_msgSender() == ownerOf(_tokenId), "You are not the owner of this token.");
    Storage.layout().ipfsHashes[_tokenId] = "";
  }

  function tokenURI(uint256 _tokenId) public view override tokenExists(_tokenId) returns (string memory) {
    if (bytes(Storage.layout().ipfsHashes[_tokenId]).length > 0) {
      return string(abi.encodePacked(Storage.layout().ipfsBaseURI, Storage.layout().ipfsHashes[_tokenId]));
    } else {
      return string(abi.encodePacked(Storage.layout().tokenBaseURI, _tokenId.toString()));
    }
  }

  /**
   * Legacy On-Chain Data (NFT Worlds)
   */

  function getWorldGeography(uint _tokenId) external view tokenExists(_tokenId) returns (uint24[5] memory) {
    return Storage.layout().nftw.getGeography(_tokenId);
  }

  function getWorldResources(uint _tokenId) external view tokenExists(_tokenId) returns (uint16[9] memory) {
    return Storage.layout().nftw.getResources(_tokenId);
  }

  function getWorldDensities(uint _tokenId) external view tokenExists(_tokenId) returns (string[3] memory) {
    return Storage.layout().nftw.getDensities(_tokenId);
  }

  function getWorldBiomes(uint _tokenId) external view tokenExists(_tokenId) returns (string[] memory) {
    return Storage.layout().nftw.getBiomes(_tokenId);
  }

  function getWorldFeatures(uint _tokenId) external view tokenExists(_tokenId) returns (string[] memory) {
    return Storage.layout().nftw.getFeatures(_tokenId);
  }

  /**
   * Hooks, Overrides
   */

  function setApprovalForAll(address operator, bool approved) public override checkForUpgrade onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public override checkForUpgrade onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public override checkForUpgrade onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public override checkForUpgrade onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override checkForUpgrade onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  /**
   * Modifiers
   */

  modifier tokenExists(uint256 _tokenId) {
    require(_exists(_tokenId), "Token id does not exist.");
    _;
  }
}