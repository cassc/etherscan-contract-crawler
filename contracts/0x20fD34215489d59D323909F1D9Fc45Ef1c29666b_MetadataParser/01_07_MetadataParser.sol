//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface storageI {
    function get(uint _id) external view returns (uint);
}

interface namesI {
    function names(uint _id) external view returns (string memory);
}

interface jobsI {
    function minted(uint _id) external view returns (bool);
}

contract MetadataParser is AccessControl {
    using Strings for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // // mainet
    address public jobsAddr = 0x878ADc4eF1948180434005D6f2Eb91f0AF3E0d15; 
    address public namesAddr = 0x1FFE4026573cEad0F49355b9D1B276a78F79924F;  
    address public storageAddr = 0x277E820Ff978326831CFF29F431bcd7DeF93511F; 

    struct TraitType {
      string trait_type;
      uint8 index;
    }

    struct Trait {
      string trait_type;
      uint256 trait_index;
      string value;
    }

    struct Metadata {
      string name;
      string description;
      string external_url;
      string image_base_uri;
      string image_extension;
      string image_base_full_uri_1;
      string image_base_full_uri_2;
      string image_full_extension;
    }

    TraitType[] public traits;
    mapping(uint256 => mapping(uint256 => string)) public traitValues;    // trait_type => index => value
    Metadata public metadata;
    storageI private storageContract;
    namesI   private namesContract;
    jobsI    private jobsContract;
    bool private showJobMinted = true;

    // 8 bits per trait
    // 255 = 1111 1111
    uint256 constant TRAIT_MASK = 255;

// constructor

    constructor() {
	    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
	    _grantRole(MINTER_ROLE, msg.sender);

      storageContract = storageI(storageAddr);
      namesContract = namesI(namesAddr);
      jobsContract = jobsI(jobsAddr);

      Metadata memory _metadata = Metadata({
        name : "Regular",
        description : "An extra-ordinary collection by @p0pps",
        external_url : "https:://regular.world/regular/",
        image_base_uri : "ipfs://QmPPeD8vEWmJkqz4pVqkMiJxzrXTZnkR5kqPF7tXBzQron/",
        image_extension : ".jpg",
        image_base_full_uri_1 : "ipfs://QmWnXeqt4goxe7FiUaBsRrg4C75byJLSixzYKPZyD77Wm1/",
        image_base_full_uri_2 : "ipfs://QmNfweKw3p1T2BGqenUnuKefsFzfkd9uGgCN2UUVC2xtk5/",
        image_full_extension : ".png"
      });
      setMetadata(_metadata);
    }

function testName(uint tokenId) public view returns (string memory) {
  return namesContract.names(tokenId);
}

function testJobs(uint tokenId) public view returns (bool) {
  return jobsContract.minted(tokenId);
}

function testTraits(uint tokenId) public view returns (uint) {
  return storageContract.get(tokenId);
}

// Setting traits

    // Set all high level trait types
    function writeTraitTypes(string[] memory trait_types) public onlyRole(MINTER_ROLE)  {
      for (uint8 index = 0; index < trait_types.length; index++) {
        traits.push(TraitType(trait_types[index], index));
      }
    }

    function setTraitType(uint8 trait_type_idx, string memory trait_type) public onlyRole(MINTER_ROLE) {
      traits[trait_type_idx] = TraitType(trait_type, trait_type_idx);
    }

    function setTrait(uint8 trait_type, uint8 trait_idx, string memory value) public onlyRole(MINTER_ROLE) {
      traitValues[trait_type][trait_idx] = value;
    }

    // Set all possible values for each trait type
    function writeTraitData(uint8 trait_type, uint8 start, uint256 length, string[] memory trait_values) public onlyRole(MINTER_ROLE) {
      for (uint8 index = 0; index < length; index++) {
        setTrait(trait_type, start+index, trait_values[index]);
      }
    }

// Global Admin

    function setMetadata(Metadata memory _metadata) public onlyRole(MINTER_ROLE) {
      metadata = _metadata;
    }

    function setDescription(string memory description) public onlyRole(MINTER_ROLE) {
      metadata.description = description;
    }

    function setExternalUrl(string memory external_url) public onlyRole(MINTER_ROLE) {
      metadata.external_url = external_url;
    }

    function setImage(string memory image_base_uri, string memory image_extension) public onlyRole(MINTER_ROLE) {
      metadata.image_base_uri = image_base_uri;
      metadata.image_extension = image_extension;
    }

    function setFullImage(string memory _uri, string memory full_image_extension, uint _batch) public onlyRole(MINTER_ROLE) {
      require(_batch == 1 || _batch == 2, "only two batches");
      if (_batch == 1)
        metadata.image_base_full_uri_1 = _uri;
      else
        metadata.image_base_full_uri_2 = _uri;
      metadata.image_full_extension = full_image_extension;
    }

    function setStorageAddr(address _addr) public onlyRole(MINTER_ROLE) {
      storageContract = storageI(_addr);
    }

    function setNamesAddr(address _addr) public onlyRole(MINTER_ROLE) {
      namesContract = namesI(_addr);
    }

    function setShowJobMinted(bool _value) public onlyRole(MINTER_ROLE) {
      showJobMinted = _value;
    }
    
// View
    function traitsById(uint tokenId) public view returns (Trait[] memory) {
      uint256 dna = storageContract.get(tokenId);
      uint256 trait_count = traits.length;
      Trait[] memory tValues = new Trait[](trait_count);
      for (uint256 i = 0; i < trait_count; i++) {
        uint256 bitMask = TRAIT_MASK << (8 * i);
        uint256 trait_index = (dna & bitMask) >> (8 * i);
        string memory value = traitValues[ traits[i].index ][trait_index];
        tValues[i] = Trait(traits[i].trait_type, trait_index, value);
      }
      return tValues;
    }

    function dnaToTraits(uint256 dna) public view returns (Trait[] memory) {
      uint256 trait_count = traits.length;
      Trait[] memory tValues = new Trait[](trait_count);
      for (uint256 i = 0; i < trait_count; i++) {
        uint256 bitMask = TRAIT_MASK << (8 * i);
        uint256 trait_index = (dna & bitMask) >> (8 * i);
        string memory value = traitValues[ traits[i].index ][trait_index];
        tValues[i] = Trait(traits[i].trait_type, trait_index, value);
      }
      return tValues;
    }

    function getAttributesJson(uint tokenId, uint256 dna) internal view returns (string memory) {
      Trait[] memory _traits = dnaToTraits(dna);
      uint8 trait_count = uint8(traits.length);
      string memory attributes = '[\n';
      for (uint8 i = 0; i < trait_count; i++) {
        if (keccak256(abi.encodePacked(_traits[i].value)) != keccak256(abi.encodePacked("None"))){
          attributes = string(abi.encodePacked(attributes,
            '\t{ "trait_type" : "', _traits[i].trait_type, '", "value": "', _traits[i].value,'" }', ',','\n'
          ));
        }
      }
      if (!jobsContract.minted(tokenId) && showJobMinted) {
        attributes = string( abi.encodePacked(attributes,
          '{ "trait_type": "Job", "value" : "Not Minted" },\n'
        ));
      }
      attributes = string( abi.encodePacked(attributes,
          '{}\n'
        ));
      return string(abi.encodePacked(attributes, ']'));
    }

    function getMetadataJson(uint256 tokenId) public view returns (string memory){
      uint256 dna = storageContract.get(tokenId);
      string memory attributes = getAttributesJson(tokenId, dna);
      string memory customName = namesContract.names(tokenId);
      string memory name = bytes(customName).length > 0 ? 
          string(abi.encodePacked("#",tokenId.toString(),", ", capitalize(customName))) : string(abi.encodePacked(metadata.name, " #",tokenId.toString()));
      string memory _fulluri = tokenId < 5000 ? metadata.image_base_full_uri_1 : metadata.image_base_full_uri_2;
      _fulluri = string(abi.encodePacked(_fulluri, tokenId.toString(), metadata.image_full_extension));

      string memory meta = string(
        abi.encodePacked(
          '{\n"name": "', name,
          '",\n"description": "', metadata.description,
          '",\n"attributes":', attributes,
          ',\n"external_url": "', metadata.external_url, tokenId.toString(),'"',
          ',\n"image": "', metadata.image_base_uri, tokenId.toString(), metadata.image_extension,'"',
          ',\n"image-full": "', _fulluri
        )
      );
      return string( abi.encodePacked(meta,'"\n}'));
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
      string memory json = Base64.encode(bytes(getMetadataJson(tokenId)));
      string memory output = string(
        abi.encodePacked("data:application/json;base64,", json)
      );
      return output;
    }

    function capitalize(string memory str) internal pure returns (string memory){
        bytes memory bStr = bytes(str);
        bytes memory bCapitalized = new bytes(bStr.length);
        bCapitalized[0] = bytes1(uint8(bStr[0]) - 32);
        for (uint i = 1; i < bStr.length; i++) {
            if ((uint8(bStr[i]) != 32) && (uint8(bStr[i-1]) == 32)) 
                bCapitalized[i] = bytes1(uint8(bStr[i]) - 32);
            else 
                bCapitalized[i] = bStr[i];
        }
        return string(bCapitalized);
    }

}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}