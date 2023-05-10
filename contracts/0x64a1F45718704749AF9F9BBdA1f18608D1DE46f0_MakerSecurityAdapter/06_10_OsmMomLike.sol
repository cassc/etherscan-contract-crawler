// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface OsmMomLike {
    function osms(bytes32) external view returns (address);
}