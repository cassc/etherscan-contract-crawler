// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Structs.sol";
import "./IArtData.sol";

interface IMetadataTraits {

    function getTraits(BaseAttributes memory atts, IArtData artData) external view returns (string memory);

}