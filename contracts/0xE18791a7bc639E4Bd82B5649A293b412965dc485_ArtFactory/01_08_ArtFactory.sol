// File: contracts/ArtFactory.sol


// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IArtData.sol";
import "./IPlaneFactory.sol";
import "./IArtFactory.sol";
import "./Structs.sol";

contract ArtFactory is IArtFactory, Ownable{
    using Strings for uint8;
    using Strings for uint;
    
    //plane static data
    IArtData artData;
    //plane calculator
    IPlaneFactory planeFactory;

    constructor() {
    }

    function setArtDataAddr(address artDataAddr) external virtual override onlyOwner {
        artData = IArtData(artDataAddr);
    }

    function setPlaneFactoryAddr(address planeFactoryAddr) external virtual override onlyOwner {
        planeFactory = IPlaneFactory(planeFactoryAddr);
    }

    function tokenHash(string memory seed, string memory attName ) internal pure returns (uint256){
        return uint256(keccak256(abi.encodePacked(seed, attName)));
    }
    
    function randomX(string memory seed, string memory attName, uint256 numValues) internal pure returns (uint8) {
        uint256 hash = tokenHash(seed, attName);
        return uint8( hash %  numValues );
    }

    // rawValue is a number from 0 to 99
    function selectByRarity(uint8 rawValue, uint8[] memory rarities) internal pure returns(uint8) {
        uint8 i;
        for(i = 0; i < rarities.length; i++) {
            if(rawValue < rarities[i]) {
                break;
            }
        }
        return i;
    }

    function calcAttributes(string memory seed) external view virtual override returns (BaseAttributes memory){
        require(address(artData) != address(0), "No artData address");
        require(address(planeFactory) != address(0), "No planeFactory address");

        BaseAttributes memory baseAtts;
        baseAtts.proximity = selectByRarity(randomX(seed, 'proximity', 100), artData.getProximityRarities());
        baseAtts.skyCol = selectByRarity(randomX(seed, 'skyCol', 100), artData.getSkyRarities());
        baseAtts.numPlanes = randomX(seed, 'numPlanes', artData.getMaxNumPlanes()) + 1;
        baseAtts.extraParams = new uint8[](uint8(type(EP).max)+1);
        baseAtts.extraParams[uint(EP.NumAngles)] = randomX(seed, 'numAngles', artData.getNumAngles()) + 1;
        baseAtts.palette = selectByRarity(randomX(seed, 'palette', 100), artData.getColorPaletteRarities());

        uint numPalettes = artData.getPaletteSize(baseAtts.palette);
        baseAtts.planeAttributes = new PlaneAttributes[](baseAtts.numPlanes);
        for(uint i=0; i < baseAtts.numPlanes; i++) {
            baseAtts.planeAttributes[i] = planeFactory.buildPlane(seed, i, artData, numPalettes, baseAtts.extraParams[uint(EP.NumAngles)]);
        }

        return baseAtts;
    }

}