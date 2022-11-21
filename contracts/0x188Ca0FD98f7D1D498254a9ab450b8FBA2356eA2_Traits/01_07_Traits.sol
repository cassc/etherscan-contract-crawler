// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./utils/Helpers.sol";
import "./Interfaces/ITraits.sol";
import "./Interfaces/IMetacity.sol";

contract Traits is Ownable, ITraits {

  using Strings for uint256;

  string public baseURI;

  string public description = 'OUR CITY NEVER SLEEPS. NOR DO YOU! EARN $CITY COINS, PAY TAXES, BEWARE OF RATS.';

  // struct to store each trait's data for metadata and rendering
  struct Trait {
    string name;
    uint256 power;
  }

  // mapping from trait type (index) to its name
  string[] public zenTraitTypes;

  // mapping from trait type (index) to its name
  string[] public ratTraitTypes;

  // list of probabilities for each trait type
  uint256[][256] public rarities;
  // list of aliases for Walker's Alias algorithm
  uint256[][256] public aliases;

  // storage of each zen traits name and power
  mapping(uint256 => mapping(uint256 => Trait)) public zenTraitData;
  // storage of each rat traits name and power
  mapping(uint256 => mapping(uint256 => Trait)) public ratTraitData;

  IMetacity public metacity;

  constructor() {}

  /** ADMIN */

  function setMetacity(address _metacity) external onlyOwner {
    metacity = IMetacity(_metacity);
  }

  function setBaseURI(string memory _baseURI) external onlyOwner {
    baseURI = _baseURI;
  }

  function setDescription(string memory _description) external onlyOwner {
    description = _description;
  }

  function setZenTraitTypes(string[] memory _zenTraitTypes) external onlyOwner {
    zenTraitTypes = _zenTraitTypes;
  }

  function setRatTraitTypes(string[] memory _ratTraitTypes) external onlyOwner {
    ratTraitTypes = _ratTraitTypes;
  }

  /**
   * administrative to upload the names and images associated with each trait
   * @param traitTypeIdx the trait type to upload the traits for (see traitTypes for a mapping)
   * @param traits the names and cid hash for each trait
   */
  function addZenTraits(uint256 traitTypeIdx, uint256[] calldata traitIds, Trait[] calldata traits) external onlyOwner {
    require(traitIds.length == traits.length, "Mismatched inputs");
    require(bytes(zenTraitTypes[traitTypeIdx]).length > 0, "Trait does not exists");
    for (uint i = 0; i < traits.length; i++) {
      zenTraitData[traitTypeIdx][traitIds[i]] = Trait(
        traits[i].name,
        traits[i].power
      );
    }
  }

  /**
   * administrative to upload the names and images associated with each trait
   * @param traitTypeIdx the trait type to upload the traits for (see traitTypes for a mapping)
   * @param traits the names and cid hash for each trait
   */
  function addRatTraits(uint256 traitTypeIdx, uint256[] calldata traitIds, Trait[] calldata traits) external onlyOwner {
    require(traitIds.length == traits.length, "Mismatched inputs");
    require(bytes(ratTraitTypes[traitTypeIdx]).length > 0, "Trait does not exists");
    for (uint i = 0; i < traits.length; i++) {
      ratTraitData[traitTypeIdx][traitIds[i]] = Trait(
        traits[i].name,
        traits[i].power
      );
    }
  }

  /**
   * administrative to upload the names and images associated with each trait
   * @param _rarities the trait type to upload the traits for (see traitTypes for a mapping)
   * @param _aliases the names and cid hash for each trait
   */
  function addRarities(uint256 rarityIdx, uint256[] calldata _rarities, uint256[] calldata _aliases) external onlyOwner {
    require(rarities.length == aliases.length, "Mismatched inputs");
    require(rarityIdx < zenTraitTypes.length + ratTraitTypes.length, "Trait does not exists");
    rarities[rarityIdx] = _rarities;
    aliases[rarityIdx] = _aliases;
  }

  // rarity on mint
  /**
   * uses A.J. Walker's Alias algorithm for O(1) rarity table lookup
   * ensuring O(1) instead of O(n) reduces mint cost by more than 50%
   * probability & alias tables are generated off-chain beforehand
   * @param seed portion of the 256 bit seed to remove trait correlation
   * @param rarityIdx the trait type to select a trait for 
   * @return the ID of the randomly selected trait
   */
  function selectTrait(uint16 seed, uint256 rarityIdx) internal view returns (uint256) {
    uint256 trait = uint256(seed) % uint256(rarities[rarityIdx].length);
    if (seed >> 8 < rarities[rarityIdx][trait]) return trait;
    return aliases[rarityIdx][trait];
  }

  /**
   * selects the species and all of its traits based on the seed value
   * @param seed a pseudorandom 256 bit number to derive traits from
   * @param _isZen a boolean for metacity / rat
   * @return t -  a struct of randomly selected traits
   */
  function selectTraits(uint256 seed, bool _isZen) public view override returns (uint256[] memory) {
    uint256[] memory t = new uint256[](_isZen ? zenTraitTypes.length : ratTraitTypes.length);
    if (_isZen) {
      for (uint i = 0; i < zenTraitTypes.length; i++) {
        seed >>= 16;
        t[i] = selectTrait(uint16(seed & 0xFFFF), uint256(i));
      }
    } else {
      for (uint i = 0; i < ratTraitTypes.length; i++) {
        seed >>= 16;
        t[i] = selectTrait(uint16(seed & 0xFFFF), uint256(i + zenTraitTypes.length));
      }
    }
    return t;
  }

  function level(uint256 tokenId) public view override returns (uint256) {
    uint256[] memory _tokenTraits = metacity.getTokenTraits(tokenId);
    bool _isZen = metacity.isZen(tokenId);
    uint256 _level = 0;
    for (uint i = 0; i < _tokenTraits.length; i++) {
      _level += _isZen ? zenTraitData[uint256(i)][uint256(_tokenTraits[uint256(i)])].power : ratTraitData[uint256(i)][uint256(_tokenTraits[uint256(i)])].power;
    }
    return _level;
  }

  /**
   * generates an attribute for the attributes array in the ERC721 metadata standard
   * @param traitType the trait type to reference as the metadata key
   * @param value the token's trait associated with the key
   * @return a JSON dictionary for the single attribute
   */
  function attributeForTypeAndValue(string memory traitType, string memory value) internal pure returns (string memory) {
    return string(abi.encodePacked(
      '{"trait_type":"',
      traitType,
      '","value":"',
      value,
      '"}'
    ));
  }

  /**
   * generates an array composed of all the individual traits and values
   * @param tokenId the ID of the token to compose the metadata for
   * @return a JSON array of all of the attributes for given token ID
   */
  function compileAttributes(uint256 tokenId) public view returns (string memory) {
    uint256[] memory _tokenTraits = metacity.getTokenTraits(tokenId);
    string memory traits;
    bool _isZen = metacity.isZen(tokenId);
    for (uint i = 0; i < _tokenTraits.length; i++) {
      if (_isZen) {
        traits = string(abi.encodePacked(
          traits,
          attributeForTypeAndValue(zenTraitTypes[i], zenTraitData[uint256(i)][uint256(_tokenTraits[uint256(i)])].name),
          ','
        ));
      } else {
        traits = string(abi.encodePacked(
          traits,
          attributeForTypeAndValue(ratTraitTypes[i], ratTraitData[uint256(i)][uint256(_tokenTraits[uint256(i)])].name),
          ','
        ));
      }
    }
    return string(abi.encodePacked(
      '[',
      traits,
      '{"trait_type":"Type","value":',
      _isZen ? '"Zen"' : '"Rat"',
      '},{"trait_type":"Level","value":"',
      level(tokenId).toString(),
      '"}]'
    ));
  }

  /**
   * generates a base64 encoded metadata response without referencing off-chain content
   * @param tokenId the ID of the token to generate the metadata for
   * @return a base64 encoded JSON dictionary of the token's metadata and SVG
   */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    bool _isZen = metacity.isZen(tokenId);

    string memory metadata = string(abi.encodePacked(
      '{"name": "',
      _isZen ? 'Zen #' : 'Rat #',
      tokenId.toString(),
      '", "description": "',
      description,
      '",',
      '"image": "',
      baseURI,
      tokenId.toString(),
      '",',
      '"attributes":',
      compileAttributes(tokenId),
      "}"
    ));

    return string(abi.encodePacked(
      "data:application/json;base64,",
      Helpers.base64(bytes(metadata))
    ));
  }
}