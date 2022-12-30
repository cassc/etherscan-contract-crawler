// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;
import "./librairies/Base64.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

import "hardhat/console.sol";

contract ContractCyberPP is ERC721 {
   
  struct CharacterAttributes {
    uint characterIndex;
    string name;
    string clansName;
    string imageURI;        
    uint stars;
    uint points;
  }

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  CharacterAttributes[] defaultCharacters;

  mapping(uint256 => CharacterAttributes) public nftHolderAttributes;

  mapping(address => uint256) public nftHolders;

  constructor(
    string[] memory characterNames,
    string[] memory characterClansNames,
    string[] memory characterImageURIs,
    uint[] memory characterStars,
    uint[] memory characterPoints
    ) 
    ERC721("CYBERPP_PPCARDS_S3", "CYBERPP_PPCARDS_S3")
   {
    for(uint i = 0; i < characterNames.length; i += 1) {
      defaultCharacters.push(CharacterAttributes({
        characterIndex: i,
        name: characterNames[i],
        clansName: characterClansNames[i],
        imageURI: characterImageURIs[i],
        stars: characterStars[i],
        points: characterPoints[i]
      }));
      CharacterAttributes memory c = defaultCharacters[i];
      console.log("initializing %s w/ Stars %s, Points %s", c.name, c.stars, c.points);
      console.log("url %s", c.imageURI);
      console.log("clansName %s", c.clansName);
    }
    _tokenIds.increment();
  }



  function initMintCharacterNFT(uint _characterIndex) external {
    uint256 newItemId = _tokenIds.current();
  
    
    nftHolderAttributes[newItemId] = CharacterAttributes({
      characterIndex: _characterIndex,
      name: defaultCharacters[_characterIndex].name,
      clansName: defaultCharacters[_characterIndex].clansName,
      imageURI: defaultCharacters[_characterIndex].imageURI,
      stars: defaultCharacters[_characterIndex].stars,
      points: defaultCharacters[_characterIndex].points
    });
    
    require(newItemId <= 10, "La limite d'exemplaire est atteinte. ");
    console.log("------------------------------------------");
    
    _safeMint(msg.sender, newItemId); 
    console.log("Minted NFT w/ tokenId %s and characterIndex %s", newItemId, _characterIndex);
    
    nftHolders[msg.sender] = newItemId;
    
    _tokenIds.increment();
  }

  function mintCharacterNFTClansNumber(uint _characterIndex) external {
    uint256 newItemId = _tokenIds.current();
    
    nftHolderAttributes[newItemId] = CharacterAttributes({
      characterIndex: _characterIndex,
      name: defaultCharacters[_characterIndex].name,
      clansName: defaultCharacters[_characterIndex].clansName,
      imageURI: defaultCharacters[_characterIndex].imageURI,
      stars: defaultCharacters[_characterIndex].stars,
      points: defaultCharacters[_characterIndex].points
    });
    

    require(newItemId <= 10, "La limite d'exemplaire est atteinte. ");
 
    _safeMint(msg.sender, newItemId); 

    console.log("Minted NFT w/ tokenId %s and characterIndex %s", newItemId, _characterIndex);
    
    nftHolders[msg.sender] = newItemId;
    _tokenIds.increment();
  }

  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    CharacterAttributes memory charAttributes = nftHolderAttributes[_tokenId];
    console.log("------------------------------------------");
    console.log(charAttributes.clansName);

    string memory strStars = Strings.toString(charAttributes.stars);
    string memory strPoints = Strings.toString(charAttributes.points);
   
    string memory json = Base64.encode(
      abi.encodePacked(
        '{"name": "',
        charAttributes.name,
        '", "description": "CYBERPP PPCARDS S3 # www.psykotikpanda.com", "tokenId":"',
        Strings.toString(_tokenId),
        '", "image": "',
        charAttributes.imageURI,
        '", "clan":"cyberpp", "defense":"',strPoints,'", "attaque":"',strStars,'", "attributes": [ { "trait_type": "tokenId", "value": "',Strings.toString(_tokenId),'"}, { "trait_type": "defense", "value": "',strPoints,'"},  { "trait_type": "attaque", "value": "',strStars,'"} ]}'
      )
    );
    string memory output = string(
      abi.encodePacked("data:application/json;base64,", json)
    );
    return output;
  }


  function getCurrentTokenId () public view {
    console.log("current _tokenId : ", _tokenIds.current());
  }



 

}