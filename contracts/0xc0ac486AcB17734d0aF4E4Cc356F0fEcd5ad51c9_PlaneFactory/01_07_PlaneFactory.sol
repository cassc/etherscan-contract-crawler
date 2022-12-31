// File: contracts/PlaneFactory.sol


// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IPlaneFactory.sol";
import "./IArtData.sol";
import "./Structs.sol";

contract PlaneFactory is IPlaneFactory, Ownable {

    function tokenHash(string memory seed, uint256 planeUid, string memory attName ) internal pure returns (uint256){
        return uint256(keccak256(abi.encodePacked(seed, planeUid, attName)));
    }

    function randomX(string memory seed, uint256 planeInstId, string memory attName, uint maxNum) internal pure returns (uint8) {
        uint256 hash = tokenHash(seed, planeInstId, attName);
        return uint8( hash % maxNum);
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

    function buildPlane(string memory seed, uint planeInstId, IArtData artData, uint numTrailColors, uint numAnglesForArt) public view virtual override returns (PlaneAttributes memory){
        PlaneAttributes memory planeAtts;

        planeAtts.locX = randomX(seed, planeInstId, 'locX', artData.getNumOfX());
        planeAtts.locY = randomX(seed, planeInstId, 'locY', artData.getNumOfY());
        planeAtts.angle = randomX(seed, planeInstId, 'angle', numAnglesForArt);
        planeAtts.trailCol = randomX(seed, planeInstId, 'trailCol', numTrailColors);
        planeAtts.level = selectByRarity(randomX(seed, planeInstId, 'level', 100), artData.getLevelRarities());
        planeAtts.speed = selectByRarity(randomX(seed, planeInstId, 'speed', 100), artData.getSpeedRarities());
        planeAtts.planeType = selectByRarity(randomX(seed, planeInstId, 'planeType', 100), artData.getPlaneTypeRarities());

        return planeAtts;
    }

}