// SPDX-License-Identifier: MIT

pragma solidity >=0.8.15 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

interface PoxPoxOMGv1Interface{
  function ownerOf(uint256 _tokenId) external view returns (address);
  function totalSupply() external view returns (uint256);
}

contract PoxPoxOmg is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  PoxPoxOMGv1Interface PoxPoxOMGv1 = PoxPoxOMGv1Interface(0x8859dC9E8A388AD56f3e53570793d0f1f8aab16F);

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;

  uint256 public constant maxSupply  = 3721;
  uint256 public constant startTokenId = 1;  
  uint256 public constant price = 0.0 ether;

  bool public paused = true;
  bool public revealed = false;
  

  bool public reinfected = false;

  constructor(
    string memory _hiddenMetadataUri
  ) ERC721A("PoxPoxOMGv2", "POX") {
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return startTokenId;
  }

  function tokenURI(uint256 _tokenId) public view virtual override(ERC721A, IERC721Metadata) returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }


  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }


  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public onlyOwner nonReentrant {

    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);

  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

/*
  victims could infect others now 
*/
  function infectionActived() public onlyOwner {
    if(!reinfected) {
      uint256 _totalSupply = PoxPoxOMGv1.totalSupply();
      for (uint256 i = 1; i <= _totalSupply; ++i) {
        address owner_addr = PoxPoxOMGv1.ownerOf(i);
        _safeMint(owner_addr, 1);
      }      
      reinfected = true;
    }
  }

}