// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IMetadataTraits.sol";
import "./Structs.sol";

contract MetadataTraits is IMetadataTraits, Ownable {
    using Strings for uint8;
    using Strings for uint;

    string[] public _flockType = ['Free', 'Duet', 'Triplet', 'Quadruplet', 'Quintuplet', 'Sextuplet', 'Septuplet'
            , 'Free 2', 'Duet+', 'Triplet+', 'Quadruplet+', 'Quintuplet+', 'Sextuplet+', 'Septuplet+'
            , '', '' ]; //not used
    string[] public _migrationType = ['Free', 'Southbound', 'Westbound', 'Northbound', 'Eastbound' ];
    string[] public _planeType = ['Jets', 'Single Props', 'Twin Props', 'Choppers','Parachutes', 'Ospreys', 'LFGs',
            'Chinooks', 'Crypto', 'Aliens'
    ];

    string[] public _planePaintType = ['None', 'Solid'];

    function setTypeNames(string[] memory typeNames) external virtual onlyOwner {
        _planeType = typeNames;
    }

    function setTypeName(uint idx, string memory name) external virtual onlyOwner {
        require (idx < _planeType.length, "ioob");
        _planeType[idx] = name;
    }

    function setPlanePaintTypeNames(string[] memory names) external virtual onlyOwner {
        _planePaintType = names;
    }

    function getTraits(BaseAttributes memory atts, IArtData artData) external virtual override view returns (string memory)
    {
        return string.concat(
            '[',
            composeAttributeString("Sky Color", artData.getSkyName(atts.skyCol)),
            ', ',
            composeAttributeString("Proximity", artData.getProximityName(atts.proximity)),
            ', ',
            composeAttributeString("Num Planes", atts.numPlanes.toString()),
            ', ',
            composeAttributeString("Lattice", atts.extraParams[uint(EP.NumAngles)].toString()),
            ', ',
            composeAttributeString("Trails Palette", artData.getColorPaletteName(atts.palette)),
            getPlanePaletteStr(atts, artData),
            getDynamicAttributesStr(atts, artData),
            ']');
    }

    struct CalcInformation {
        uint256 biggestFlockSize;
        uint8[] angleCounts;
        uint256 numTrailColors;
        uint256 numAngles;
        uint8[] planeTypeCounts;
        bytes directionBitCounts;
        bytes trailColorBitCounts;
        bytes speedBitCounts;
        uint256[] colorsByAngle;
        uint256[] speedsByAngle;
        uint8 mostCommonDirection;
        bool matchingSpeed;
    }

    function getDynamicAttributesStr(BaseAttributes memory art, IArtData artData)
        internal
        view
        virtual
        returns (string memory)
    {

        CalcInformation memory c;

        c.numAngles = art.extraParams[uint(EP.NumAngles)];
        c.angleCounts = new uint8[](c.numAngles);
        c.numTrailColors = artData.getPaletteSize(art.palette);
        c.planeTypeCounts = new uint8[](artData.getNumTypes());
        //array of single bytes. each byte being enough to store a bit for each of the 7 planes
        c.directionBitCounts = new bytes(c.numAngles);
        c.trailColorBitCounts = new bytes(c.numTrailColors);
        c.speedBitCounts = new bytes(artData.getNumSpeeds());
        c.colorsByAngle = new uint256[](c.numAngles);
        c.speedsByAngle = new uint256[](c.numAngles);

        for(uint8 i=0; i < art.numPlanes; i++) {
            PlaneAttributes memory planeAtts = art.planeAttributes[i];
            //keep count of how many planes you've seen with same angle
            c.angleCounts[planeAtts.angle] += 1;
            uint trailColIdx = planeAtts.trailCol % c.numTrailColors;
            //tally each plane type in this artwork
            c.planeTypeCounts[planeAtts.planeType] += 1;
            // implementation for figuring out if all planes sharing same direction also share same color
            c.trailColorBitCounts[trailColIdx] |= ( bytes1(0x01) << i);
            c.directionBitCounts[planeAtts.angle] |= ( bytes1(0x01) << i);
            c.speedBitCounts[planeAtts.speed] |= ( bytes1(0x01) << i);
            c.colorsByAngle[planeAtts.angle] = planeAtts.trailCol;
            c.speedsByAngle[planeAtts.angle] = planeAtts.speed;
        }

        c.biggestFlockSize = 1;
        for (uint8 i = 0; i < c.angleCounts.length; i++) {
            uint8 numInFlock = c.angleCounts[i];
            if ( numInFlock > c.biggestFlockSize) {
                c.mostCommonDirection = i;
                c.biggestFlockSize = numInFlock;
            }
        }

        c.matchingSpeed = isMatchingSpeed(c);

        string memory attsString;
        attsString = appendFlockTypeString(attsString, c, artData);
        attsString = appendMigrationTypeString(attsString, c, artData);
        attsString = appendMatchingTrailsStr(attsString, c);
        attsString = appendMatchingSpeedString(attsString, c);
        attsString = appendPlaneTypeCountsStr(attsString, c);

        return attsString;
    }

    function isMatchingSpeed(CalcInformation memory c) internal view virtual returns (bool) {
        uint256 speedForDirection = c.speedsByAngle[c.mostCommonDirection];
        return c.biggestFlockSize > 1 && (c.speedBitCounts[speedForDirection] == c.directionBitCounts[c.mostCommonDirection]);
    }

    function appendMatchingSpeedString(string memory attsString, CalcInformation memory c)
        internal view virtual returns (string memory)
    {
        return string.concat( attsString, ', ',
            composeAttributeString(
                'Matching Speed',
                c.matchingSpeed
                ? "Yes" : "No"
            ));
    }

    function appendFlockTypeString(string memory attsString, CalcInformation memory c, IArtData artData)
        internal view virtual returns (string memory)
    {
        return string.concat( attsString, ', ',
            composeAttributeString('Flock Type',
            _flockType[uint8((c.biggestFlockSize-1) + (c.matchingSpeed ? artData.getMaxNumPlanes() : 0))]
            ));
    }

    function appendMigrationTypeString(string memory attsString, CalcInformation memory c, IArtData /*artData*/)
        internal view virtual returns (string memory)
    {
        // 4 possible directions, x angles.  so to get the general direction, divide by angles and multiply by 4
        // add 1 because first space is occupied by "free"
        uint8 migrationType = (uint8) (
            (c.biggestFlockSize == 1) ?
            0 : ((c.mostCommonDirection * 4) / c.numAngles ) + 1);

        return string.concat( attsString, ', ',
            composeAttributeString(
                'Migration Type',
                _migrationType[migrationType]
            ));

    }

    function appendMatchingTrailsStr(
        string memory attsString,
        CalcInformation memory c
    )
        internal
        pure
        virtual
        returns(string memory)
    {
        //this is matching trails for only the most common direction
        // by comparing the bit pattern (plane ids) for that direction with the bit pattern for a color seen for that direction
        uint256 colorForDirection = c.colorsByAngle[c.mostCommonDirection];

        return string.concat( attsString, ', ',
            composeAttributeString(
                'Matching Trails',
                c.biggestFlockSize > 1 && (c.trailColorBitCounts[colorForDirection] == c.directionBitCounts[c.mostCommonDirection])
                ? "Yes" : "No"
            ));
    }

    function appendPlaneTypeCountsStr(
        string memory attsString,
        CalcInformation memory c
    )
    internal
    view
    virtual
    returns(string memory)
    {
        for (uint8 i = 0; i < c.planeTypeCounts.length; i++) {
            if(c.planeTypeCounts[i] > 0) {
                attsString = string.concat( attsString, ', ',
                    composeAttributeString(
                        _planeType[i],
                        c.planeTypeCounts[i].toString()
                    ));
            }
        }

        return attsString;
    }

    function getPlanePaletteStr(BaseAttributes memory atts, IArtData artData)
    internal
    view
    virtual
    returns(string memory)
    {
        if (atts.extraParams[uint(EP.PaintType)] > 0) {
            return string.concat( ', ',
                composeAttributeString(
                'Plane Palette',
                artData.getColorPaletteName(atts.extraParams[uint(EP.PaletteIdx)])
            ));
        }
        else {
            return '';
        }
    }

    function composeAttributeString(string memory trait, string memory value) internal pure returns (string memory) {
        return string.concat(
            '{ "trait_type": "', trait,
            '", "value": "', value,
            '" }'
        );

    }

}