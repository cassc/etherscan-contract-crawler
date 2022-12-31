// File: contracts/OffChainParams.sol


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IArtParams.sol";
import "./Structs.sol";

contract OffChainParams is IParams, Ownable {

    using Strings for uint8;
    using Strings for uint256;

    function getParmsSequence(BaseAttributes calldata atts, bool isSample, IArtData.ArtProps calldata artProps)
        public
        pure
        virtual
        override
        returns(string memory)
    {
        string memory lines = "[[";
        for(uint i=0; i<atts.planeAttributes.length; i++) {
            lines = planeParams(lines, atts.planeAttributes[i], (i < atts.planeAttributes.length-1) );
        }

        return string.concat(
            lines,
            "],", atts.skyCol.toString(),
            ",", atts.palette.toString(),
            ",", atts.proximity.toString(),
            ",", artProps.numOfX.toString(),
            ",", artProps.numOfY.toString(),
            ",", atts.extraParams[uint(EP.NumAngles)].toString(),
            ",", artProps.numTypes.toString(),

            ",", (isSample ? "true" : "false"),
            "]"
        );

    }

    function planeParams(string memory lines, PlaneAttributes memory planeAtt, bool last) internal pure returns (string memory){
        return string.concat(
            lines,
            "[",
            planeAtt.locX.toString(),",",
            planeAtt.locY.toString(),",",
            planeAtt.angle.toString(),",",
            planeAtt.trailCol.toString(),",",
            planeAtt.level.toString(),",",
            planeAtt.speed.toString(),",",
            planeAtt.planeType.toString(),
            last ?
            "]," : "]"
        );
    }


}