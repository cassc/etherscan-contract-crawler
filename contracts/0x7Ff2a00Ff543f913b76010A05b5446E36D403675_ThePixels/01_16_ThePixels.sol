// SPDX-License-Identifier: MIT

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./ThePixelsDNAFactory.sol";
import "./IThePixelsMetadataProvider.sol";
import "./IThePixelsDNAUpdater.sol";

contract ThePixels is Ownable, ERC721Enumerable, ThePixelsDNAFactory {
  uint256 public maxPixels;
  uint256 constant public MAX_SPECIAL_PIXELS = 5;

  address public salesContractAddress;
  address public metadataProviderContractAddress;
  address public DNAUpdaterContractAddress;

  mapping (uint256 => bool) public foundDNAs;
  mapping (uint256 => bool) public mintedSpecialDNAs;
  mapping (uint256 => uint256) public pixelDNAs;
  mapping (uint256 => uint256) public pixelDNAExtensions;

  constructor (uint256 _maxPixels) ERC721("the pixels", "TPIX") {
    maxPixels = _maxPixels;
    _setTraitTable();
  }

  function setSalesContract(address _salesContractAddress) external onlyOwner {
    salesContractAddress = _salesContractAddress;
  }

  function setMetadataProviderContract(address _metadataProviderContractAddress) external onlyOwner {
    metadataProviderContractAddress = _metadataProviderContractAddress;
  }

  function setDNAUpdaterContract(address _DNAUpdaterContractAddress) external onlyOwner {
    DNAUpdaterContractAddress = _DNAUpdaterContractAddress;
  }

  function mintSpecialPixelDNA(uint256 index, uint256 _salt) external onlyOwner {
    require(index >= 0 && index < MAX_SPECIAL_PIXELS, "Invalid index");
    require(!mintedSpecialDNAs[index], "Already minted");
    uint256 totalSupply = totalSupply();
    uint256 winnerTokenIndex = _rnd(_salt, index) % totalSupply;
    address winnerAddress = ownerOf(winnerTokenIndex);
    pixelDNAs[totalSupply] = index;
    mintedSpecialDNAs[index] = true;
    _safeMint(winnerAddress, totalSupply);
  }

  function mint(address to, uint256 salt, uint256 _nonce) external {
    require(msg.sender == salesContractAddress, "Well, there is a reason only sale contract can do this.");
    uint256 totalSupply = totalSupply();
    require(totalSupply < maxPixels, "Hit the limit");
    _mintWithUniqueDNA(to, totalSupply, salt, _nonce);
  }

  function _mintWithUniqueDNA(address _to, uint256 _tokenId, uint256 _salt, uint256 _nonce) internal {
    uint256 uniqueDNA = _getUniqueDNA(_salt, _nonce);
    pixelDNAs[_tokenId] = uniqueDNA;
    _safeMint(_to, _tokenId);
  }

  function _getUniqueDNA(uint256 _salt, uint256 _nonce) internal returns (uint256) {
    uint256 generationAttempt = 0;
    while(true) {
      uint256 extendedDNA = getEncodedRandomDNA(_salt, _nonce + generationAttempt);
      if (foundDNAs[extendedDNA] == false) {
        foundDNAs[extendedDNA] = true;
        return extendedDNA;
      }
      generationAttempt++;
    }
  }

  function getEncodedRandomDNA(uint256 _salt, uint256 _nonce) internal view returns (uint256) {
    uint8[11] memory foundDNA = _getRandomDNA(_salt, _nonce);
    uint256 encodedDNA = 10 ** (foundDNA.length * 2 + 1);
    for(uint256 i=0; i<foundDNA.length; i++) {
      encodedDNA += foundDNA[i] * (10 ** ((foundDNA.length - i) * 2));
    }
    return encodedDNA;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
    require(metadataProviderContractAddress != address(0), "Invalid metadata provider address");

    return IThePixelsMetadataProvider(metadataProviderContractAddress)
      .getMetadata(
        _tokenId,
        pixelDNAs[_tokenId],
        pixelDNAExtensions[_tokenId]
      );
  }

  function tokensOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 index;
      for (index = 0; index < tokenCount; index++) {
        result[index] = tokenOfOwnerByIndex(_owner, index);
      }
      return result;
    }
  }

  function updateDNAExtension(uint256 _tokenId) external {
    require(DNAUpdaterContractAddress != address(0), "Invalid updater address");
    require(msg.sender == ownerOf(_tokenId), "You need to own the token to update");

    uint256 newDNAExtension = IThePixelsDNAUpdater(DNAUpdaterContractAddress).getUpdatedDNAExtension(
      msg.sender,
      _tokenId,
      pixelDNAs[_tokenId],
      pixelDNAExtensions[_tokenId]
    );
    pixelDNAExtensions[_tokenId] = newDNAExtension;
  }
}