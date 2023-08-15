// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import {IGnarSeederV2} from "./IGNARSeederV2.sol";

interface IGnarDecorator {
    function backgrounds(uint256 index) external view returns (string memory);

    function bodies(uint256 index) external view returns (string memory);

    function accessories(uint256 index) external view returns (string memory);

    function heads(uint256 index) external view returns (string memory);

    function glasses(uint256 index) external view returns (string memory);

    function addManyBackgrounds(string[] calldata _backgrounds) external;

    function addManyBodies(string[] calldata _bodies) external;

    function addManyAccessories(string[] calldata _accessories) external;

    function addManyHeads(string[] calldata _heads) external;

    function addManyGlasses(string[] calldata _glasses) external;
}