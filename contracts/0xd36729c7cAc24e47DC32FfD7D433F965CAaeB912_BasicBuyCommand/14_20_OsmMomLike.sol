//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface OsmMomLike {
    function osms(bytes32) external view returns (address);
}