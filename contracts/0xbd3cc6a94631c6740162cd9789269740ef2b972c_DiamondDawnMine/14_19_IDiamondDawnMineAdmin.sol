// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../objects/Diamond.sol";
import "../objects/System.sol";

interface IDiamondDawnMineAdmin {
    function eruption(Certificate[] calldata diamonds) external;

    function lostShipment(uint tokenId, Certificate calldata diamond) external;

    function setManifest(Stage stage_, string calldata manifest) external;

    function setBaseTokenURI(string calldata baseTokenURI) external;
}