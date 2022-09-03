// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ItemsStructure {
    
    struct Item {
        string Name;
        string Rarity;
        uint256 Probability;  
    }

    function shuffleArray(Item[] memory _items, uint256 id) private view returns (Item[] memory) {

        for (uint256 i = 0; i < _items.length; i++) {
            uint256 n = i + uint256(keccak256(abi.encodePacked(block.timestamp - id))) % (_items.length - i);
            Item memory temp = _items[n];
            _items[n] = _items[i];
            _items[i] = temp;
        }

        Item[] memory result;
        result = _items;    

        return result;
    }

    function getItem(Item[] memory _items, uint256 id) internal view returns (Item memory) {
        require(_items.length > 0, "ItemsStructure: the number of items must be greater than 0");
        require(id > 0, "ItemsStructure: id must be greater than 0");

        _items = shuffleArray(_items, id);

        uint256 sum = 0;

        for(uint i = 0; i < _items.length; i++) {
            sum += _items[i].Probability;
        }

        uint256 random = createRandom(sum, id);

        uint256 tmp = 0;
        uint k = 0;
        
        for(uint256 j = 0; j < _items.length; j++) {
            if( (random >= tmp) && (random <= tmp + _items[j].Probability) ) {
                k = j;
                break;
            } else {
                tmp += _items[j].Probability;
            }
        }

        return _items[k];
    }

    function createRandom(uint256 sum, uint256 id) private view returns (uint256) {
        return uint256(blockhash(block.number - id)) % sum + 1;
    }
}

contract LegendaryPose is ItemsStructure {

    Item[] private _legendaryPoses;

    constructor() {
        _legendaryPoses.push(Item("Explorer", "Legendary", 10));
        _legendaryPoses.push(Item("Sportsman", "Legendary", 10));
        _legendaryPoses.push(Item("Hipster", "Legendary", 10));
        _legendaryPoses.push(Item("Aviator", "Legendary", 10));
    }

    function getLegendaryPose(uint256 id) internal view returns (Item memory) {
        return getItem(_legendaryPoses, id);
    }
}