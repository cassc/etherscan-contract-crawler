// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {SafeMath} from  "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ItemsToUpgrade {

    using SafeMath for uint32;

    uint32 constant ITEM_1 = 10;
    uint32 constant ITEM_2 = 5;
    uint32 constant ITEM_3 = 3;
    uint32 constant ITEM_4 = 2;

    function getItemsToUpgrade(string[] memory _rarity, string memory _age) internal pure returns (uint32 item_1, uint32 item_2, uint32 item_3, uint32 item_4) {
        if ( keccak256(abi.encodePacked(_age)) == keccak256(abi.encodePacked("Adult")) ) {
            item_1 = 0;
            item_2 = 0;
            item_3 = 0;
            item_4 = 0;
        } else {
            uint32 sum = 0;

            for (uint i = 0; i < _rarity.length; i++) {
                sum += getRarityMultiplier(_rarity[i]);
            }

            uint32 age = getAgeMultiplier(_age);

            item_1 = sum * ITEM_1 * age;
            item_2 = sum * ITEM_2 * age;
            item_3 = sum * ITEM_3 * age;
            item_4 = sum * ITEM_4 * age;
        }
    }

    function getRarityMultiplier(string memory _rare) private pure returns (uint32) {
        if ( keccak256(abi.encodePacked(_rare)) == keccak256(abi.encodePacked("Common")) ) {
            return 2;
        } else if ( keccak256(abi.encodePacked(_rare)) == keccak256(abi.encodePacked("Uncommon")) ) {
            return 4;
        } else if ( keccak256(abi.encodePacked(_rare)) == keccak256(abi.encodePacked("Rare")) ) {
            return 8;
        } else if ( keccak256(abi.encodePacked(_rare)) == keccak256(abi.encodePacked("Epic")) ) {
            return 16;
        } else { // Legendary
            return 32;
        }
    }

    function getAgeMultiplier(string memory _age) private pure returns (uint32) {
        if ( keccak256(abi.encodePacked(_age)) == keccak256(abi.encodePacked("Child")) ) {
            return 1;
        } else { // Teenager
            return 3;
        }
    }
}