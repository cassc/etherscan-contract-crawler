// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Strings.sol';


contract OwnableDelegateProxy{}
contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

contract YSSGenesis is ERC721A, Ownable, ReentrancyGuard, ProxyRegistry {

  using Strings for uint256;

  string public baseURI = '';
  string public baseExtension = '.json';
  string public secretImage;
  
  uint256 public maxSupply = 20000;

  bool public revealed;
  bool public airdrop;
  

  address immutable proxyRegistryAddress = 0xF57B2c51dED3A29e6891aba85459d600256Cf317;


  constructor()
  ERC721A("Yeti Secret Society", "YSS")
  ReentrancyGuard() 
  {

  }

  function airdropMint(address receiver, uint256 amount) external onlyOwner nonReentrant{
    require(maxSupply >= amount + _totalMinted(), "Supply limit");
    _safeMint(receiver, amount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return secretImage;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), baseExtension))
        : '';
  }

  function setRevealed() public onlyOwner {
    revealed = !revealed;
  }

  function setSecretImage(string memory _secretImage) public onlyOwner {
    secretImage = _secretImage;
  }

  function setBaseURI(string memory _tokenBaseURI) public onlyOwner {
    baseURI = _tokenBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function isApprovedForAll(address owner, address operator) override public view returns (bool) {
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true; 
        }
        
        return super.isApprovedForAll(owner, operator);
}

    function withdraw() public onlyOwner nonReentrant{
    (bool success, ) = payable(owner()).call{value: address(this).balance}('');
    require(success, 'withdraw failed');
    }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
}