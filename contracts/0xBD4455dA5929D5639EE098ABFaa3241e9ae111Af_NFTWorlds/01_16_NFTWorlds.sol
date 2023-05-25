// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Compile with optimizer on, otherwise exceeds size limit.

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTWorlds is ERC721Enumerable, Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using ECDSA for bytes32;

  /**
   * @dev Mint Related
   * */

  string public ipfsGateway = "https://ipfs.nftworlds.com/ipfs/";
  bool public mintEnabled = false;
  uint public totalMinted = 0;
  uint public mintSupplyCount;
  uint private ownerMintReserveCount;
  uint private ownerMintCount;
  uint private maxMintPerAddress;
  uint private whitelistExpirationTimestamp;
  mapping(address => uint16) private addressMintCount;

  uint public whitelistAddressCount = 0;
  uint public whitelistMintCount = 0;
  uint private maxWhitelistCount = 0;
  mapping(address => bool) private whitelist;

  /**
   * @dev World Data
   */

  string[] densityStrings = ["Very High", "High", "Medium", "Low", "Very Low"];

  string[] biomeStrings = ["Forest","River","Swamp","Birch Forest","Savanna Plateau","Savanna","Beach","Desert","Plains","Desert Hills","Sunflower Glade","Gravel Strewn Mountains","Mountains","Wooded Mountains","Ocean","Deep Ocean","Swampy Hills","Evergreen Forest","Cursed Forest","Cold Ocean","Warm Ocean","Frozen Ocean","Stone Shore","Desert Lakes","Forest Of Flowers","Jungle","Badlands","Wooded Badlands Plateau","Evergreen Forest Mountains","Giant Evergreen Forest","Badlands Plateau","Dark Forest Hills","Snowy Tundra","Snowy Evergreen Forest","Frozen River","Snowy Beach","Snowy Mountains","Mushroom Shoreside Glades","Mushroom Glades","Frozen Fields","Bamboo Jungle","Destroyed Savanna","Eroded Badlands"];

  string[] featureStrings = ["Ore Mine","Dark Trench","Ore Rich","Ancient Forest","Drought","Scarce Freshwater","Ironheart","Multi-Climate","Wild Cows","Snow","Mountains","Monsoons","Abundant Freshwater","Woodlands","Owls","Wild Horses","Monolith","Heavy Rains","Haunted","Salmon","Sunken City","Oil Fields","Dolphins","Sunken Ship","Town","Reefs","Deforestation","Deep Caverns","Aquatic Life Haven","Ancient Ocean","Sea Monsters","Buried Jems","Giant Squid","Cold Snaps","Icebergs","Witch's Hut","Heat Waves","Avalanches","Poisonous Bogs","Deep Water","Oasis","Jungle Ruins","Rains","Overgrowth","Wildflower Fields","Fishing Grounds","Fungus Patch","Vultures","Giant Spider Nests","Underground City","Calm Waters","Tropical Fish","Mushrooms","Large Lake","Pyramid","Rich Oil Veins","Cave Of Ancients","Island Volcano","Paydirt","Whales","Undersea Temple","City Beneath The Waves","Pirate's Grave","Wildlife Haven","Wild Bears","Rotting Earth","Blizzards","Cursed Wildlife","Lightning Strikes","Abundant Jewels","Dark Summoners","Never-Ending Winter","Bandit Camp","Vast Ocean","Shroom People","Holy River","Bird's Haven","Shapeshifters","Spawning Grounds","Fairies","Distorted Reality","Penguin Colonies","Heavenly Lights","Igloos","Arctic Pirates","Sunken Treasure","Witch Tales","Giant Ice Squid","Gold Veins","Polar Bears","Quicksand","Cats","Deadlands","Albino Llamas","Buried Treasure","Mermaids","Long Nights","Exile Camp","Octopus Colony","Chilled Caves","Dense Jungle","Spore Clouds","Will-O-Wisp's","Unending Clouds","Pandas","Hidden City Of Gold","Buried Idols","Thunder Storms","Abominable Snowmen","Floods","Centaurs","Walking Mushrooms","Scorched","Thunderstorms","Peaceful","Ancient Tunnel Network","Friendly Spirits","Giant Eagles","Catacombs","Temple Of Origin","World's Peak","Uninhabitable","Ancient Whales","Enchanted Earth","Kelp Overgrowth","Message In A Bottle","Ice Giants","Crypt Of Wisps","Underworld Passage","Eskimo Settlers","Dragons","Gold Rush","Fountain Of Aging","Haunted Manor","Holy","Kraken"];

  struct WorldData {
    uint24[5] geographyData; // landAreaKm2, waterAreaKm2, highestPointFromSeaLevelM, lowestPointFromSeaLevelM, annualRainfallMM,
    uint16[9] resourceData; // lumberPercent, coalPercent, oilPercent, dirtSoilPercent, commonMetalsPercent, rareMetalsPercent, gemstonesPercent, freshWaterPercent, saltWaterPercent,
    uint8[3] densities; // wildlifeDensity, aquaticLifeDensity, foliageDensity
    uint8[] biomes;
    uint8[] features;
  }

  mapping(uint => int32) private tokenSeeds;
  mapping(uint => string) public tokenMetadataIPFSHashes;
  mapping(string => uint) private ipfsHashTokenIds;
  mapping(uint => WorldData) private tokenWorldData;

  /**
   * @dev Contract Methods
   */

  constructor(
    uint _mintSupplyCount,
    uint _ownerMintReserveCount,
    uint _whitelistExpirationTimestamp,
    uint _maxWhitelistCount,
    uint _maxMintPerAddress
  ) ERC721("NFT Worlds", "NFT Worlds") {
    mintSupplyCount = _mintSupplyCount;
    ownerMintReserveCount = _ownerMintReserveCount;
    whitelistExpirationTimestamp = _whitelistExpirationTimestamp;
    maxWhitelistCount = _maxWhitelistCount;
    maxMintPerAddress = _maxMintPerAddress;
  }

  /************
   * Metadata *
   ************/

  function tokenURI(uint _tokenId) override public view returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    return string(abi.encodePacked(ipfsGateway, tokenMetadataIPFSHashes[_tokenId]));
  }

  function emergencySetIPFSGateway(string memory _ipfsGateway) external onlyOwner {
     ipfsGateway = _ipfsGateway;
  }

  function updateMetadataIPFSHash(uint _tokenId, string calldata _tokenMetadataIPFSHash) tokenExists(_tokenId) external {
    require(_msgSender() == ownerOf(_tokenId), "You are not the owner of this token.");
    require(ipfsHashTokenIds[_tokenMetadataIPFSHash] == 0, "This IPFS hash has already been assigned.");

    tokenMetadataIPFSHashes[_tokenId] = _tokenMetadataIPFSHash;
    ipfsHashTokenIds[_tokenMetadataIPFSHash] = _tokenId;
  }

  function getSeed(uint _tokenId) tokenExists(_tokenId) external view returns (int32) {
    require(_msgSender() == ownerOf(_tokenId), "You are not the owner of this token.");

    return tokenSeeds[_tokenId];
  }

  function getGeography(uint _tokenId) tokenExists(_tokenId) external view returns (uint24[5] memory) {
    return tokenWorldData[_tokenId].geographyData;
  }

  function getResources(uint _tokenId) tokenExists(_tokenId) external view returns (uint16[9] memory) {
    return tokenWorldData[_tokenId].resourceData;
  }

  function getDensities(uint _tokenId) tokenExists(_tokenId) external view returns (string[3] memory) {
    uint totalDensities = 3;
    string[3] memory _densitiesStrings = ["", "", ""];

    for (uint i = 0; i < totalDensities; i++) {
        string memory _densityString = densityStrings[tokenWorldData[_tokenId].densities[i]];
        _densitiesStrings[i] = _densityString;
    }

    return _densitiesStrings;
  }

  function getBiomes(uint _tokenId) tokenExists(_tokenId) external view returns (string[] memory) {
    uint totalBiomes = tokenWorldData[_tokenId].biomes.length;
    string[] memory _biomes = new string[](totalBiomes);

    for (uint i = 0; i < totalBiomes; i++) {
        string memory _biomeString = biomeStrings[tokenWorldData[_tokenId].biomes[i]];
        _biomes[i] = _biomeString;
    }

    return _biomes;
  }

  function getFeatures(uint _tokenId) tokenExists(_tokenId) external view returns (string[] memory) {
    uint totalFeatures = tokenWorldData[_tokenId].features.length;
    string[] memory _features = new string[](totalFeatures);

    for (uint i = 0; i < totalFeatures; i++) {
        string memory _featureString = featureStrings[tokenWorldData[_tokenId].features[i]];
        _features[i] = _featureString;
    }

    return _features;
  }

  modifier tokenExists(uint _tokenId) {
    require(_exists(_tokenId), "This token does not exist.");
    _;
  }

  /********
   * Mint *
   ********/

  struct MintData {
    uint _tokenId;
    int32 _seed;
    WorldData _worldData;
    string _tokenMetadataIPFSHash;
  }

  function mintWorld(
    MintData calldata _mintData,
    bytes calldata _signature // prevent alteration of intended mint data
  ) external nonReentrant {
    require(verifyOwnerSignature(keccak256(abi.encode(_mintData)), _signature), "Invalid Signature");

    require(_mintData._tokenId > 0 && _mintData._tokenId <= mintSupplyCount, "Invalid token id.");
    require(mintEnabled, "Minting unavailable");
    require(totalMinted < mintSupplyCount, "All tokens minted");

    require(_mintData._worldData.biomes.length > 0, "No biomes");
    require(_mintData._worldData.features.length > 0, "No features");
    require(bytes(_mintData._tokenMetadataIPFSHash).length > 0, "No ipfs");

    if (_msgSender() != owner()) {
        require(
          addressMintCount[_msgSender()] < maxMintPerAddress,
          "You cannot mint more."
        );

        require(
          totalMinted + (ownerMintReserveCount - ownerMintCount) < mintSupplyCount,
          "Available tokens minted"
        );

        // make sure remaining mints are enough to cover remaining whitelist.
        require(
          (
            block.timestamp > whitelistExpirationTimestamp ||
            whitelist[_msgSender()] ||
            (
              totalMinted +
              (ownerMintReserveCount - ownerMintCount) +
              ((whitelistAddressCount - whitelistMintCount) * 2)
              < mintSupplyCount
            )
          ),
          "Only whitelist tokens available"
        );
    } else {
        require(ownerMintCount < ownerMintReserveCount, "Owner mint limit");
    }

    tokenWorldData[_mintData._tokenId] = _mintData._worldData;

    tokenMetadataIPFSHashes[_mintData._tokenId] = _mintData._tokenMetadataIPFSHash;
    ipfsHashTokenIds[_mintData._tokenMetadataIPFSHash] = _mintData._tokenId;
    tokenSeeds[_mintData._tokenId] = _mintData._seed;

    addressMintCount[_msgSender()]++;
    totalMinted++;

    if (whitelist[_msgSender()]) {
      whitelistMintCount++;
    }

    if (_msgSender() == owner()) {
        ownerMintCount++;
    }

    _safeMint(_msgSender(), _mintData._tokenId);
  }

  function setMintEnabled(bool _enabled) external onlyOwner {
    mintEnabled = _enabled;
  }

  /*************
   * Whitelist *
   *************/

  function joinWhitelist(bytes calldata _signature) public {
    require(verifyOwnerSignature(keccak256(abi.encode(_msgSender())), _signature), "Invalid Signature");
    require(!mintEnabled, "Whitelist is not available");
    require(whitelistAddressCount < maxWhitelistCount, "Whitelist is full");
    require(!whitelist[_msgSender()], "Your address is already whitelisted");

    whitelistAddressCount++;

    whitelist[_msgSender()] = true;
  }

  /************
   * Security *
   ************/

  function verifyOwnerSignature(bytes32 hash, bytes memory signature) private view returns(bool) {
    return hash.toEthSignedMessageHash().recover(signature) == owner();
  }
}