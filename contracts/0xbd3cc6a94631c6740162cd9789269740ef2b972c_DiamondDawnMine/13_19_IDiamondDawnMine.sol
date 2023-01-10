// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../objects/Mine.sol";
import "../objects/System.sol";

interface IDiamondDawnMine {
    event Forge(uint tokenId);
    event Mine(uint tokenId);
    event Cut(uint tokenId);
    event Polish(uint tokenId);
    event Ship(uint tokenId, uint16 physicalId, uint64 number);
    event Dawn(uint tokenId);

    function initialize(uint16 maxDiamond) external;

    function forge(uint tokenId) external;

    function mine(uint tokenId) external;

    function cut(uint tokenId) external;

    function polish(uint tokenId) external;

    function ship(uint tokenId) external;

    function dawn(uint tokenId) external;

    function lockMine() external;

    function getMetadata(uint tokenId) external view returns (string memory);

    function isReady(Stage stage) external view returns (bool);
}