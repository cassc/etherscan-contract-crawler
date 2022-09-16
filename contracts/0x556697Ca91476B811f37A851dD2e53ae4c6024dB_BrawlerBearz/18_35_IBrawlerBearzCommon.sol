//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBrawlerBearzCommon {
    struct CustomMetadata {
        string name;
        string lore;
        uint256 background;
        uint256 head;
        uint256 weapon;
        uint256 armor;
        uint256 faceArmor;
        uint256 eyewear;
        uint256 misc;
        uint256 xp;
        bool isUnlocked;
        uint256 faction;
    }

    struct Traits {
        uint256 strength;
        uint256 endurance;
        uint256 intelligence;
        uint256 luck;
        uint256 xp;
        uint256 level;
        string skin;
        string head;
        string eyes;
        string outfit;
        string mouth;
        string background;
        string weapon;
        string armor;
        string eyewear;
        string faceArmor;
        string misc;
        string locked;
        string faction;
    }

    struct Bear {
        string name;
        string description;
        string dna;
        Traits traits;
        CustomMetadata dynamic;
    }
}