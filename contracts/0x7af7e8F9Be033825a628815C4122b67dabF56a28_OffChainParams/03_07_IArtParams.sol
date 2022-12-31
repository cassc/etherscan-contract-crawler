// File: contracts/IArtParams.sol


// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./IArtData.sol";
import "./Structs.sol";

interface IParams {
    
    function getParmsSequence(BaseAttributes calldata atts, bool isSample, IArtData.ArtProps calldata artProps) external pure returns(string memory);

}