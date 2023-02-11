/*
   ___  ____  __   __   ____    _______ _____   ___________  ____
  / _ \/ __ \/ /  / /  / __/   / ___/ // / _ | / __/ __/ _ \/ __/
 / , _/ /_/ / /__/ /___\ \    / /__/ _  / __ |_\ \/ _// , _/\ \  
/_/|_|\____/____/____/___/    \___/_//_/_/ |_/___/___/_/|_/___/  
                                                               
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// Définit les différentes bibliothèques que l'on va utiliser, là où les fonctions sont inscrites


contract RCT is ERC721, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  string private baseUri;

  uint256 public maxSupply = 133;

  constructor() ERC721("Rolls Chasers", "RC") {}


 //On définit quelques bases nescessaire au bon fonctionnement du contrat ERC721

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }


 // On définit la fonction mint ainsi que deux fonctions de mint qui lui permetteront de fonctionner plus facilement

  function mint(uint256 _mintAmount, address _receiver)
    public
    mintCompliance(_mintAmount)
    onlyOwner
  {
    _mintLoop(_receiver, _mintAmount);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }


 // On définit les fonctions qui permettent au créateur de récupérer les NFTs du contrat, peu importe où ils se trouvent, de deux manières différentes.

  function withdrawNft(uint256 tokenId, address receipter) external onlyOwner {
    _transfer(ownerOf(tokenId), receipter, tokenId);
  }

  function massWithdrawNfts(uint256[] memory tokenIds, address receipter) external onlyOwner {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      _transfer(ownerOf(tokenIds[i]), receipter, tokenIds[i]);
    }
  }


 // On définit la fonction setBaseURI qui permet au créateur du contrat de changer les métadatas, ainsi que deux autres fonctions qui veillent au bon fonctionnement de la transition

  function setBaseURI(string memory _baseUri) external onlyOwner {
    baseUri = _baseUri;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory currentBaseURI = baseUri;
    return
      bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))
        : "";
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseUri;
  }


 // On définit la fonction airdrop qui permet au créateur du contrat d'airdrop plusieurs tokens à plusieurs addresses

  function airdrop(uint256[] memory _tokenIds, address[] memory _receivers) public onlyOwner mintCompliance(_tokenIds.length) {
    require(_tokenIds.length == _receivers.length, "Invalid input array");

    for (uint256 i = 0; i < _tokenIds.length; i++) {
        require(_exists(_tokenIds[i]) == false, "Token already exist");
        _safeMint(_receivers[i], _tokenIds[i]);
        supply.increment();
    }
  }

}
 /*
    _____  _____    
   / __/ |/ / _ \   
  / _//    / // /   
 /___/_/|_/____/                  
 ·−· · −· −·· · −−··  ···− −−− ··− ···  · −·  ·− ···− ·−· ·· ·−··  ··−−− −−−−− ··−−− ···−−                                                 
 */