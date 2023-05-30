// SPDX-License-Identifier: CC-BY-4.0

pragma solidity >= 0.8.0;

abstract contract IArcadeBackend {
    function tokenURI(uint tokenId) virtual external view returns (string memory);
    function verifyPoints(uint minPoints, uint maxPoints, uint tokenId) virtual external view;
    function insertCoin(uint tokenId, uint variant) virtual external;
    
    function interact(uint tokenId, uint[6] memory intActions, string[6] memory stringActions) external {
    }

    function restart(uint tokenId) external {
    }
}