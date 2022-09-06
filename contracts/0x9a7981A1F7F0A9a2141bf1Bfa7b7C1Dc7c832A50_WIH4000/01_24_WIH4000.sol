// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// NFT contract to inherit from.
import "./ERC721PresetMinterPauserAutoId.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Helper functions OpenZeppelin provides.
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./libraries/Base64.sol";


// import "hardhat/console.sol";

// Our contract inherits from ERC721, which is the standard NFT contract!
contract WIH4000 is ERC721PresetMinterPauserAutoId, Ownable {

  struct CharacterAttributes {
    string name;
    string description;
    string imageURI;
    string typeStr;    
  }

  CharacterAttributes[] defaultCharacters;

  mapping(uint256 => uint32) public nftTypes;
  mapping(uint32 => uint32) public nftCount;
  uint private totalCount;
  

  constructor()
    ERC721PresetMinterPauserAutoId("Wealth in Health NFT", "WIH", "")
  {
    totalCount = 4000;//total;

    defaultCharacters.push(CharacterAttributes({
      name: "WIH NFT",
      description: "The WIH NFT is a limited digital assets of comprehensive and complete of brain health check through medical equipment including 7T MRI and scientific medical test in The Wealth In Health(WIH) Brain Wellness Center(BWC).  Once you own the NFT, you can take brain health screening in BWC that uses a proprietary method developed in partnership with Harvard Medical School and Massachusetts General Hospital(MGH) with priority benifit of WIHmetaverse Bio & Healthcare Platform. [Description WebLink](https://drive.google.com/file/d/1ZB1iaDZ6sh2bd3kZrOjomu6dazFuJbdP/view) ",
      imageURI: "QmTH6yyBb2qhZHEmKVcC79dg4EGhgyRmBjJwrDG4zn3mTe",
      typeStr: "WIH NFT B-1"
    }));
    defaultCharacters.push(CharacterAttributes({
      name: "WIH NFT",
      description: "The WIH NFT is a limited digital assets of comprehensive and complete of brain health check through medical equipment including 7T MRI and scientific medical test in The Wealth In Health(WIH) Brain Wellness Center(BWC).  Once you own the NFT, you can take brain health screening in BWC that uses a proprietary method developed in partnership with Harvard Medical School and Massachusetts General Hospital(MGH) with priority benifit of WIHmetaverse Bio & Healthcare Platform. [Description WebLink](https://drive.google.com/file/d/1ZB1iaDZ6sh2bd3kZrOjomu6dazFuJbdP/view) ",
      imageURI: "QmfNMbNRDfKFhjt6aGsdSCqZuM9behGQqbQ6JL9khK9PTW",
      typeStr: "WIH NFT B-2"
    }));
    defaultCharacters.push(CharacterAttributes({
      name: "WIH NFT",
      description: "The WIH NFT is a limited digital assets of comprehensive and complete of brain health check through medical equipment including 7T MRI and scientific medical test in The Wealth In Health(WIH) Brain Wellness Center(BWC).  Once you own the NFT, you can take brain health screening in BWC that uses a proprietary method developed in partnership with Harvard Medical School and Massachusetts General Hospital(MGH) with priority benifit of WIHmetaverse Bio & Healthcare Platform. [Description WebLink](https://drive.google.com/file/d/1ZB1iaDZ6sh2bd3kZrOjomu6dazFuJbdP/view) ",
      imageURI: "Qmcy8Yd65Z3quWmU8dseFm82eRb4cNWNx7yn4CKBy1PT5Y",
      typeStr: "WIH NFT B-3"
    }));
    nftCount[0] = 0;
    nftCount[1] = 0;
    nftCount[2] = 0;    
  }
  function setMetaData(uint32 level, string memory name, string memory description, string memory uri, string memory typestr) external onlyOwner {
    require(level >= 0 && level <= 2, "Level Error");
    defaultCharacters[level].name = name;
    defaultCharacters[level].description = description;
    defaultCharacters[level].imageURI = uri;
    defaultCharacters[level].typeStr = typestr;
  }
  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
    
    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "', defaultCharacters[nftTypes[_tokenId]].name, ' #', Strings.toString(_tokenId),
            '", "description": "', defaultCharacters[nftTypes[_tokenId]].description, '", '
            '"image": "ipfs://', defaultCharacters[nftTypes[_tokenId]].imageURI, '",',
            '"external_url": "https://www.wihcoin.com",',
            '"attributes": [ ',
            '{ "trait_type": "Type", "value": "', defaultCharacters[nftTypes[_tokenId]].typeStr, '"}, { "trait_type": "Year", "value": "2022"}, { "trait_type": "Builder", "value": "Bigtone"}, { "trait_type": "Creator", "value": "Global Bio & Healthcare Platform"}]}'
          )
        )
      )
    );
    string memory output = string(abi.encodePacked("data:application/json;base64,", json));
    return output;
  }


  function mint(address to) public virtual override(ERC721PresetMinterPauserAutoId) {
    require(hasRole(MINTER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have minter role to mint");
    require(nftCount[0] + 1 <= 1000, "NFT Count error");    
    
    super.mint(to);
    nftTypes[totalSupply()] = 0;
    nftCount[0] = nftCount[0] + 1;
  }
  function mintNftTo(address _toAddr, uint32 level, uint32 count) external {
    require(count > 0, "Count Error");
    require(level >= 0 && level <= 2, "Level Error");
    require(hasRole(MINTER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have minter role to mint");
    require((level == 2 && nftCount[level] + count <= 2000) || (level != 2 && nftCount[level] + count <= 1000), "NFT Count error");    
    
    for (uint32 i = 0; i < count; i++) {      
      super.mint(_toAddr);
      nftTypes[totalSupply()] = level;      
    }
    nftCount[level] = nftCount[level] + count;
  }
  function mintNft(uint32 level, uint32 count) external {
    require(count > 0, "Count Error");
    require(level >= 0 && level <= 2, "Level Error");
    require(hasRole(MINTER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have minter role to mint");
    require((level == 2 && nftCount[level] + count <= 2000) || (level != 2 && nftCount[level] + count <= 1000), "NFT Count error");    
    
    for (uint32 i = 0; i < count; i++) {      
      super.mint(msg.sender);
      nftTypes[totalSupply()] = level;      
    }
    nftCount[level] = nftCount[level] + count;
  }
}