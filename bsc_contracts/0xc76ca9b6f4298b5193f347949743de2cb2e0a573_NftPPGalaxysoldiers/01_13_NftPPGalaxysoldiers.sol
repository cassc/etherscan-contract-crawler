// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;
import "./librairies/Base64.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "hardhat/console.sol";

contract NftPPGalaxysoldiers is ERC721 {
  struct CharacterAttributes {
    uint characterIndex;
    string name;
    string clansName;
    string imageURI;        
    uint stars;
    uint points;
    uint maxCollectionId;
    uint collectionId;
    uint clansNumber;
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
    uint[] memory characterPoints,
    uint[] memory characterMaxCollectionId,
    uint[] memory characterCollectionIds,
    uint[] memory characterClansNumbers
    ) 
    ERC721("PPTK SEASON 3", "PPTK-CLANSWAR-GALAXYSOLDIERS")
   {
    for(uint i = 0; i < characterNames.length; i += 1) {
      defaultCharacters.push(CharacterAttributes({
        characterIndex: i,
        name: characterNames[i],
        clansName: characterClansNames[i],
        imageURI: characterImageURIs[i],
        stars: characterStars[i],
        points: characterPoints[i],
        maxCollectionId: characterMaxCollectionId[i],
        collectionId: characterCollectionIds[i],
        clansNumber: characterClansNumbers[i]
      }));
      CharacterAttributes memory c = defaultCharacters[i];
      console.log("initializing %s w/ Stars %s, Points %s", c.name, c.stars, c.points);
      console.log("url %s, collectionId %s, collectionId %s", c.imageURI, c.maxCollectionId, c.collectionId);
      console.log("clansName %s, clansNumber %s", c.clansName, c.clansNumber);
    }
    _tokenIds.increment();
  }



  function initMintCharacterNFT(uint _characterIndex) external {
    uint256 newItemId = _tokenIds.current();
  
    defaultCharacters[_characterIndex].collectionId = defaultCharacters[_characterIndex].collectionId+1;
    
    CharacterAttributes memory c = defaultCharacters[_characterIndex];
    
    nftHolderAttributes[newItemId] = CharacterAttributes({
      characterIndex: _characterIndex,
      name: defaultCharacters[_characterIndex].name,
      clansName: defaultCharacters[_characterIndex].clansName,
      imageURI: defaultCharacters[_characterIndex].imageURI,
      stars: defaultCharacters[_characterIndex].stars,
      points: defaultCharacters[_characterIndex].points,
      maxCollectionId: defaultCharacters[_characterIndex].maxCollectionId,
      collectionId: defaultCharacters[_characterIndex].collectionId,
      clansNumber: defaultCharacters[_characterIndex].clansNumber
    });
    string memory strMaxCollectionId = Strings.toString(c.maxCollectionId);
    string memory strCollectionId = Strings.toString(c.collectionId);
    require(c.collectionId <= c.maxCollectionId, "La limite d'exemplaire est atteinte. ");
    console.log("------------------------------------------");
    console.log("The limit of %s is not exceeded", strMaxCollectionId);
    console.log("Token Number : %s", strCollectionId);
    console.log("------------------------------------------");

    _safeMint(msg.sender, newItemId); 
    console.log("Minted NFT w/ tokenId %s and characterIndex %s", newItemId, _characterIndex);
    
    nftHolders[msg.sender] = newItemId;
    
    _tokenIds.increment();
  }


  function mintCharacterNFTClansNumber(uint _characterIndex, uint _incrementedCollectionId) external {
    uint256 newItemId = _tokenIds.current();
    defaultCharacters[_characterIndex].collectionId = _incrementedCollectionId;
    CharacterAttributes memory c = defaultCharacters[_characterIndex];
    nftHolderAttributes[newItemId] = CharacterAttributes({
      characterIndex: _characterIndex,
      name: defaultCharacters[_characterIndex].name,
      clansName: defaultCharacters[_characterIndex].clansName,
      imageURI: defaultCharacters[_characterIndex].imageURI,
      stars: defaultCharacters[_characterIndex].stars,
      points: defaultCharacters[_characterIndex].points,
      maxCollectionId: defaultCharacters[_characterIndex].maxCollectionId,
      collectionId: defaultCharacters[_characterIndex].collectionId,
      clansNumber: defaultCharacters[_characterIndex].clansNumber
    });
    string memory strMaxCollectionId = Strings.toString(c.maxCollectionId);
    string memory strCollectionId = Strings.toString(c.collectionId);

    require(c.collectionId <= c.maxCollectionId, "La limite d'exemplaire est atteinte. ");

    console.log("------------------------------------------");
    console.log("The limit of %s is not exceeded", strMaxCollectionId);
    console.log("Token Number : %s", strCollectionId);
    console.log("------------------------------------------");

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
    string memory strMaxCollectionId = Strings.toString(charAttributes.maxCollectionId);
    string memory strCollectionId = Strings.toString(charAttributes.collectionId);
    string memory strClansNumber = Strings.toString(charAttributes.clansNumber);

    string memory json = Base64.encode(
      abi.encodePacked(
        '{"name": "',
        charAttributes.name,
        '", "description": "PPTK Clans War ! Collection ',charAttributes.clansName,' : NFT tokenId #',
        Strings.toString(_tokenId),
        ' ',charAttributes.clansName,'", "image": "',
        charAttributes.imageURI,
        '", "attributes": [ { "trait_type": "Points", "value": ',strPoints,'}, { "trait_type": "Stars", "value": ',strStars,'}, { "trait_type": "maxCollectionId", "value": ',strMaxCollectionId,'}, { "trait_type": "collectionId", "value": ',strCollectionId,'}, { "trait_type": "clansNumber", "value": ',strClansNumber,'} ]}'
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