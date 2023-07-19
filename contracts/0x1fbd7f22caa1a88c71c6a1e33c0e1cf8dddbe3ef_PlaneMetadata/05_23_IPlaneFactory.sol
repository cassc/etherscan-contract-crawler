// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Structs.sol";
import "./IArtData.sol";

interface IPlaneFactory {
    function buildPlane(string memory seed, uint planeInstId, IArtData artData, uint numTrailColors, uint numAnglesForArt) external view returns (PlaneAttributes memory);
}