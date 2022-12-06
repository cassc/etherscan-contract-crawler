// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;
import "./librairies/Base64.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "hardhat/console.sol";

contract NftPowerCards is ERC721 {
  struct CharacterAttributes {
    uint characterIndex;
    string name;
    string clansName;
    string imageURI;        
    uint stars;
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
    uint[] memory characterStars
    ) 
    ERC721("PPCARD SEASON3 POWER", "PPCARD-SEASON3-POWER")
   {
    for(uint i = 0; i < characterNames.length; i += 1) {
      defaultCharacters.push(CharacterAttributes({
        characterIndex: i,
        name: characterNames[i],
        clansName: characterClansNames[i],
        imageURI: characterImageURIs[i],
        stars: characterStars[i]
      }));
      CharacterAttributes memory c = defaultCharacters[i];
      console.log("initializing %s w/ Stars %s", c.name, c.stars);
      console.log("url %s ", c.imageURI);
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
      stars: defaultCharacters[_characterIndex].stars
    });

    _safeMint(msg.sender, newItemId); 
    console.log("Minted NFT w/ tokenId %s and characterIndex %s", newItemId, _characterIndex);
    
    nftHolders[msg.sender] = newItemId;
    
    _tokenIds.increment();
  }


  function mintCharacterNFTClansNumber(uint _randomCharacterIndex) external {
    uint256 newItemId = _tokenIds.current();
    nftHolderAttributes[newItemId] = CharacterAttributes({
      characterIndex: _randomCharacterIndex,
      name: defaultCharacters[_randomCharacterIndex].name,
      clansName: defaultCharacters[_randomCharacterIndex].clansName,
      imageURI: defaultCharacters[_randomCharacterIndex].imageURI,
      stars: defaultCharacters[_randomCharacterIndex].stars
    });
    _safeMint(msg.sender, newItemId); 

    console.log("Minted NFT w/ tokenId %s and characterIndex %s", newItemId, _randomCharacterIndex);
    
    nftHolders[msg.sender] = newItemId;
    _tokenIds.increment();
  }



  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    CharacterAttributes memory charAttributes = nftHolderAttributes[_tokenId];
    console.log("------------------------------------------");
    console.log(charAttributes.clansName);

    string memory strStars = Strings.toString(charAttributes.stars);

    string memory json = Base64.encode(
      abi.encodePacked(
        '{"name": "',
        charAttributes.name,
        '",  "description": "PPCARD SEASON3 POWER #',
        Strings.toString(_tokenId),
        ' ',charAttributes.clansName,'", "image": "',
        charAttributes.imageURI,
        '", "attributes": [ { "trait_type": "attaque", "value": "',strStars,'"} , { "trait_type": "maxAttaque", "value": "3" }, { "trait_type": "clan", "value": "POWER" } ]}'
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