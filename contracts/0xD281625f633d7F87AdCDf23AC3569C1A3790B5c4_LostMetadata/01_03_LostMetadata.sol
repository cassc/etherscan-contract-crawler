// SPDX-License-Identifier: AGPL-3.0
// ©2022 Ponderware Ltd

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC20 {
    function balanceOf (address account) external view returns (uint256);
    function transfer (address recipient, uint256 amount) external returns (bool);
}

interface IMoonCatSVGS {
    function uint2str (uint value) external pure returns (string memory);
}

interface IStarkade {
    function BoostNames (uint index) external view returns (string memory);
    function Attributes (uint index) external view returns (string memory);
    function getTraitIndexes (uint tokenId) external view returns (uint16[15] memory attributes, uint8[5] memory boosts);
    function traitName (uint256 traitIndex) external view returns (string memory);
    function cityInfo (uint256 cityId) external view returns (string memory regionName, string memory cityName, string memory characteristic);
}

interface ITrainingGround {
    function getSkillCounts (address tokenAddress, uint256 tokenId) external view returns (uint256 taunts, uint256 styles, uint256 combos);
    function isTraining (address tokenAddress, uint256 tokenId) external view returns (bool training);
}

/*
 * @title STARKADE Lost Fighters Metadata
 * @author Ponderware Ltd
 * @dev Metadata assembly contract for Starkade Lost Fighters NFT
 * @license https://starkade.com/licences/nft/starkade-legion/
 */

contract LostMetadata {

    // https://starkade.com/licences/nft/starkade-legion/

    IMoonCatSVGS MoonCatSVGS = IMoonCatSVGS(0xB39C61fe6281324A23e079464f7E697F8Ba6968f);
    IStarkade immutable Starkade;
    ITrainingGround immutable TrainingGround;
    string BASE_IMAGE_URI = "https://starkade.com/api/legion/lost/";
    string public IPFS_Image_Cache_CID;

    /**
     * @dev Encode a key/value pair as a JSON trait property, where the value is a numeric item (doesn't need quotes)
     */
    function encodeBoostAttribute (string memory key, uint8 value) internal view returns (bytes memory) {
        return abi.encodePacked("{\"trait_type\":\"", key,"\",\"value\":",MoonCatSVGS.uint2str(value),
                                ",\"display_type\":\"boost_number\"}");
    }

    /**
     * @dev Encode a key/value pair as a JSON trait property, where the value is a number item (doesn't need quotes)
     */
    function encodeStatsAttribute (string memory key, uint256 value) internal view returns (bytes memory) {
        return abi.encodePacked("{\"trait_type\":\"", key,"\",\"value\":",MoonCatSVGS.uint2str(value),",\"display_type\":\"number\"}");
    }

    /**
     * @dev Encode a key/value pair as a JSON trait property, where the value is a number item (doesn't need quotes)
     */
    function encodeLevelAttribute (string memory key, uint256 value) internal view returns (bytes memory) {
        return abi.encodePacked("{\"trait_type\":\"", key,"\",\"value\":",MoonCatSVGS.uint2str(value),",\"max_value\":16}");
    }

    /**
     * @dev Encode a key/value pair as a JSON trait property, where the value is a string item (needs quotes around it)
     */
    function encodeStringAttribute (string memory key, string memory value) internal pure returns (bytes memory) {
        return abi.encodePacked("{\"trait_type\":\"", key,"\",\"value\":\"",value,"\"}");
    }

    /**
     * @dev Encode boosts as JSON attributes
     */
    function assembleBoosts (uint8[5] memory boosts) internal view returns (bytes memory) {
        uint256 total = uint256(boosts[0]) + uint256(boosts[1]) + uint256(boosts[2]) + uint256(boosts[3]) + uint256(boosts[4]);
        return abi.encodePacked(encodeBoostAttribute(Starkade.BoostNames(0), boosts[0]), ",",
                                encodeBoostAttribute(Starkade.BoostNames(1), boosts[1]), ",",
                                encodeBoostAttribute(Starkade.BoostNames(2), boosts[2]), ",",
                                encodeBoostAttribute(Starkade.BoostNames(3), boosts[3]), ",",
                                encodeBoostAttribute(Starkade.BoostNames(4), boosts[4]), ",",
                                encodeStringAttribute("Stats Total", MoonCatSVGS.uint2str(total)), ",");
    }

    /**
     * @dev Encode character details as JSON attributes
     */
    function assembleBaseAttributes (uint16[15] memory attributes) internal view returns (string memory, bytes memory) {
        bytes memory result = "";
        for (uint i = 0; i < 13; i++) {
            result = abi.encodePacked(result, encodeStringAttribute(Starkade.Attributes(i), Starkade.traitName(attributes[i])), ",");
        }

        (string memory regionName, string memory cityName, string memory characteristic) = Starkade.cityInfo(attributes[14]);

        return (regionName,
                abi.encodePacked(result, encodeStringAttribute(Starkade.Attributes(13), regionName), ","));
    }

    /**
     * @dev Get attributes from the Training Ground
     */
    function assembleTrainingAttributes (uint256 tokenId) internal view returns (bytes memory) {
        (uint256 taunts, uint256 styles, uint256 combos) = TrainingGround.getSkillCounts(address(Starkade), tokenId);
        
        return abi.encodePacked(encodeLevelAttribute("Taunts", taunts), ",",
                                encodeLevelAttribute("Fighting Styles", styles), ",", 
                                encodeLevelAttribute("Combos", combos), ",",
                                encodeStringAttribute("In Training", (TrainingGround.isTraining(address(Starkade), tokenId) ? "Yes" : "No")));
    }

    /**
     * @dev Generate metadata description string
     */
    function description (string memory region) internal pure returns (bytes memory) {
        return abi.encodePacked("A legend is found. Previously lost to the Otherdome, this fighter from ",region," is one of a set of unique characters from the STARKADE universe, inspired by the retro '80s artwork of Signalnoise.");
    }

    /**
     * @dev Assemble the imageURI for the given attributes
     */
    function imageURI (uint16[15] memory attributes) internal view returns (bytes memory) {
        bytes memory uri = bytes(BASE_IMAGE_URI);
        for (uint i = 1; i < 12; i++) {
            uri = abi.encodePacked(uri, MoonCatSVGS.uint2str(attributes[i]), "-");
        }
        return abi.encodePacked(uri, MoonCatSVGS.uint2str(attributes[12]), ".png");
    }

    /**
     * @dev Generate full BASE64-encoded JSON metadata for a STARKADE Lost Fighters character. Use static IPFS image if available.
     */
    function legionMetadata (uint256 tokenId) public view returns (string memory) {
        (uint16[15] memory attributes, uint8[5] memory boosts) = Starkade.getTraitIndexes(tokenId);
        string memory tokenIdString = MoonCatSVGS.uint2str(tokenId);
        (string memory regionName, bytes memory baseAttributes) = assembleBaseAttributes(attributes);
        bytes memory boostAttributes = assembleBoosts(boosts);
        bytes memory trainingAttributes = assembleTrainingAttributes(tokenId);
        bytes memory img;
        if (bytes(IPFS_Image_Cache_CID).length == 0) {
            img = imageURI(attributes);
        } else {
            img = abi.encodePacked("ipfs://", IPFS_Image_Cache_CID, "/", tokenIdString, ".png");
        }
        bytes memory json = abi.encodePacked("{\"attributes\":[",
                                             encodeStringAttribute("Arena", "Legion"), ",",
                                             baseAttributes,
                                             boostAttributes,
                                             trainingAttributes,
                                             "], \"name\":\"Lost Fighter #",tokenIdString,"\", \"description\":\"",description(regionName),"\",\"image\":\"",
                                             img,
                                             "\",\"external_url\": \"https://starkade.com/fighters/lost/",tokenIdString,"\"}");
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(json)));
    }


    address public owner;

    function setIPFSImageCache (string calldata cid) public onlyOwner {
        IPFS_Image_Cache_CID = cid;
    }

    /**
     * @dev Set the baseURI for the image generator (images can also be assembled on-chain in the main contract)
     */
    function setBaseImageURI (string calldata base_uri) public onlyOwner {
        BASE_IMAGE_URI = base_uri;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    constructor (address starkadeContractAddress, address trainingGroundAddress) {
        Starkade = IStarkade(starkadeContractAddress);
        TrainingGround = ITrainingGround(trainingGroundAddress);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner");
        _;
    }

    /* Rescuers */
    /**
    * @dev Rescue ETH sent directly to this contract.
    */
    function withdraw () public {
        payable(owner).transfer(address(this).balance);
    }
    /**
    * @dev Rescue ERC20 assets sent directly to this contract.
    */
    function withdrawForeignERC20(address tokenContract) public onlyOwner {
        IERC20 token = IERC20(tokenContract);
        token.transfer(owner, token.balanceOf(address(this)));
        }

    /**
     * @dev Rescue ERC721 assets sent directly to this contract.
     */
    function withdrawForeignERC721(address tokenContract, uint256 tokenId) public onlyOwner {
        IERC721(tokenContract).safeTransferFrom(address(this), owner, tokenId);
    }
}


/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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
            out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
            out := shl(8, out)
            out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
            out := shl(8, out)
            out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
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