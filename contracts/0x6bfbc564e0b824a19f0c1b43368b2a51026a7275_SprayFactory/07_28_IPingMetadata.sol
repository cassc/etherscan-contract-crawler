// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IValidatable.sol";
import "./PingAtts.sol";

interface IPingMetadata is IValidatable {

//    function setRevealed(bool revealed) external;
    function genMetadata(uint256 tokenId, PingAtts calldata atts) external view returns (string memory);

}