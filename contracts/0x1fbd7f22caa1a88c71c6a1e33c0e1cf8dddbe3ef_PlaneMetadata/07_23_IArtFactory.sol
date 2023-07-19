// File: contracts/IArtFactory.sol


// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IArtData.sol";
import "./IPlaneFactory.sol";
import "./Structs.sol";

interface IArtFactory {

    function setArtDataAddr(address artDataAddr) external;

//    function setPlaneAddr(address planeAddr) external;

    function setPlaneFactoryAddr(address planeFactoryAddr) external ;


//    function makeAttributeParts(BaseAttributes memory atts) external view returns (string[15] memory);

    function calcAttributes(string memory seed, uint256 tokenId) external view returns (BaseAttributes memory);

}