// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**************************************************
 *
 * Unifriends NFT
 * https://unifriends.io
 * Developed By: @sbmitchell.eth
 *
 **************************************************/

import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";

library UnifriendsRenderer {
    struct Traits {
        string wearable;
        string skin;
        string item;
        string horn;
        string hair;
        string eyes;
        string background;
    }

    struct Unifriend {
        uint256 strength;
        uint256 speed;
        uint256 intelligence;
        string name;
        string description;
        bool isLegendary;
        Traits trait;
    }

    function toJSONProperty(string memory key, string memory value)
        public
        pure
        returns (string memory)
    {
        return string(abi.encodePacked('"', key, '" : "', value, '"'));
    }

    function getLegendary(uint256 tokenId)
        internal
        pure
        returns (Unifriend memory)
    {
        Traits memory trait;

        if (tokenId == 0) {
            return
                Unifriend({
                    strength: 92,
                    speed: 92,
                    intelligence: 98,
                    name: "Dr. X",
                    description: "Dr. X is pure evil. The antithesis of the genesis unicorns and Unifriends. The meticulous planning with unparalleled genius make Dr. X a complex and difficult adversary for the Unifriends.",
                    isLegendary: true,
                    trait: trait
                });
        } else if (tokenId == 1) {
            return
                Unifriend({
                    strength: 90,
                    speed: 99,
                    intelligence: 91,
                    name: "Cyber Pegasus",
                    description: "They got a second chance at life. From not being able to walk or fly they have beccome the fastest wings in the entire metaverse.",
                    isLegendary: true,
                    trait: trait
                });
        } else if (tokenId == 2) {
            return
                Unifriend({
                    strength: 94,
                    speed: 93,
                    intelligence: 95,
                    name: "Uni-Force General",
                    description: "A strategic and battle-hardened unifriend. The General protects the metaverse and ensures stability.",
                    isLegendary: true,
                    trait: trait
                });
        } else if (tokenId == 3) {
            return
                Unifriend({
                    strength: 94,
                    speed: 93,
                    intelligence: 97,
                    name: "King Bastion",
                    description: "King Bastion is the oldest and wisest unifriend in the galaxy. Always in gold he shines and rules the metaverse.",
                    isLegendary: true,
                    trait: trait
                });
        } else if (tokenId == 4) {
            return
                Unifriend({
                    strength: 92,
                    speed: 93,
                    intelligence: 96,
                    name: "Queen Bastion",
                    description: "Queen Bastion is the smartest unifriend in the metaverse. Her unique kinetic aura keeps the metaverse at peace.",
                    isLegendary: true,
                    trait: trait
                });
        } else if (tokenId == 5) {
            return
                Unifriend({
                    strength: 94,
                    speed: 93,
                    intelligence: 92,
                    name: "Mutated Uni",
                    description: "This unifriend was engulfed by toxic slime during an epic battle. They emerged out of a cocoon as a mutated unicorn.",
                    isLegendary: true,
                    trait: trait
                });
        } else if (tokenId == 6) {
            return
                Unifriend({
                    strength: 98,
                    speed: 96,
                    intelligence: 95,
                    name: "Shadow Uni",
                    description: "The darkest unicorn in the metaverse. A black hole dweller, isolated, but free.",
                    isLegendary: true,
                    trait: trait
                });
        } else if (tokenId == 7) {
            return
                Unifriend({
                    strength: 93,
                    speed: 93,
                    intelligence: 93,
                    name: "Uni Bot",
                    description: "He is mech robot of the metaverse. Cunning intellect and perfect posture.",
                    isLegendary: true,
                    trait: trait
                });
        } else if (tokenId == 8) {
            return
                Unifriend({
                    strength: 95,
                    speed: 93,
                    intelligence: 92,
                    name: "Experiment 73",
                    description: "An escapee from Dr. X's lab. They are one of the strongest and most devious inhabitors of he metaverse.",
                    isLegendary: true,
                    trait: trait
                });
        } else if (tokenId == 9) {
            return
                Unifriend({
                    strength: 93,
                    speed: 97,
                    intelligence: 94,
                    name: "Spurr",
                    description: "The loner that's never around. Her name is Spurr, she is fast, witted and always secretly up to no good.",
                    isLegendary: true,
                    trait: trait
                });
        }
    }

    function getUnifriendProperties(uint256 tokenId, uint256 randomness)
        internal
        pure
        returns (Unifriend memory)
    {
        // 10 Legendaries
        if (tokenId < 10) {
            return getLegendary(tokenId);
        } else {
            Traits memory trait;

            string[356] memory GROUPS = [
                // WEARABLES - 44
                // Common 4x
                // 28
                "Bandana",
                "Bandana",
                "Bandana",
                "Bandana",
                "Dog Collar Red",
                "Dog Collar Red",
                "Dog Collar Red",
                "Dog Collar Blue",
                "Dog Collar Blue",
                "Dog Collar Blue",
                "Neon Collar Pink",
                "Neon Collar Pink",
                "Neon Collar Pink",
                "Glass Collar",
                "Glass Collar",
                "Glass Collar",
                "Chain Collar",
                "Chain Collar",
                "Chain Collar",
                "Spiked Chain Collar",
                "Spiked Chain Collar",
                "Spiked Chain Collar",
                "Tshirt Red",
                "Tshirt Red",
                "Tshirt Red",
                "Vynil Bandana",
                "Vynil Bandana",
                "Vynil Bandana",
                // Rare 2x
                // 12
                "Tactical Vest",
                "Tactical Vest",
                "Gold Collar",
                "Gold Collar",
                "Tshirt Blue",
                "Tshirt Blue",
                "Chalk Collar",
                "Chalk Collar",
                "Neon Collar Green",
                "Neon Collar Green",
                "Spiked Collar Purple",
                "Spiked Collar Purple",
                // Super Rare 1x
                // 4
                "Headphones",
                "Headphones Red",
                "Cyberpunk Collar",
                "Tactical Vest Red",
                // ITEMS - 55
                // Common 4x
                // 40
                "Fishing Rod",
                "Fishing Rod",
                "Fishing Rod",
                "Fishing Rod",
                "Mug",
                "Mug",
                "Mug",
                "Mug",
                "Dumbell",
                "Dumbell",
                "Dumbell",
                "Dumbell",
                "Camera",
                "Camera",
                "Camera",
                "Camera",
                "Keyboard",
                "Keyboard",
                "Keyboard",
                "Keyboard",
                "Football",
                "Football",
                "Football",
                "Football",
                "Pencil and Paper",
                "Pencil and Paper",
                "Pencil and Paper",
                "Pencil and Paper",
                "Phone",
                "Phone",
                "Phone",
                "Phone",
                "Soccer Ball",
                "Soccer Ball",
                "Soccer Ball",
                "Soccer Ball",
                "Tablet",
                "Tablet",
                "Tablet",
                "Tablet",
                // Rare 2x
                // 12
                "Popcorn",
                "Popcorn",
                "Test Tube",
                "Test Tube",
                "Glizzy",
                "Glizzy",
                "Laptop",
                "Laptop",
                "Selfie Stick",
                "Selfie Stick",
                "Spray Can",
                "Spray Can",
                // Super Rare 1x
                // 3
                "Drone",
                "Controller",
                "Sword",
                // SKINS - 71
                // Common 3x
                // 48
                "Concrete Black Skin",
                "Concrete Black Skin",
                "Concrete Black Skin",
                "Black Skin",
                "Black Skin",
                "Black Skin",
                "Brown Skin",
                "Brown Skin",
                "Brown Skin",
                "Gold Skin",
                "Gold Skin",
                "Gold Skin",
                "Dino Red Skin",
                "Dino Red Skin",
                "Dino Red Skin",
                "Purple Skin",
                "Purple Skin",
                "Purple Skin",
                "Yellow Skin",
                "Yellow Skin",
                "Yellow Skin",
                "White Skin",
                "White Skin",
                "White Skin",
                "Vortex Skin",
                "Vortex Skin",
                "Vortex Skin",
                "Pastel Yellow Skin",
                "Pastel Yellow Skin",
                "Pastel Yellow Skin",
                "Pastel Blue Skin",
                "Pastel Blue Skin",
                "Pastel Blue Skin",
                "Pastel Green Skin",
                "Pastel Green Skin",
                "Pastel Green Skin",
                "Pastel Red Skin",
                "Pastel Red Skin",
                "Pastel Red Skin",
                "Vynil Orange Skin",
                "Vynil Orange Skin",
                "Vynil Orange Skin",
                "Vynil Mint Skin",
                "Vynil Mint Skin",
                "Vynil Mint Skin",
                "Chalk Light Pink Skin",
                "Chalk Light Pink Skin",
                "Chalk Light Pink Skin",
                // Rare 2x
                // 18
                "Plasma Skin",
                "Plasma Skin",
                "Blue Titanium Skin",
                "Blue Titanium Skin",
                "Robot Skin",
                "Robot Skin",
                "Dino Green Skin",
                "Dino Green Skin",
                "Silver Skin",
                "Silver Skin",
                "Kaiju Skin",
                "Kaiju Skin",
                "Moon Rock Skin",
                "Moon Rock Skin",
                "Chalk Light Blue Skin",
                "Chalk Light Blue Skin",
                "Pastel Pink Skin",
                "Pastel Pink Skin",
                // Super Rare 1x
                // 5
                "Glass Skeleton Skin",
                "Zebra Skin",
                "Camo Skin",
                "Poison Frog Skin",
                "Martian Skin",
                // HORNS - 58
                // Common 4x
                // 36
                "Spring Horn",
                "Spring Horn",
                "Spring Horn",
                "Spring Horn",
                "White Horn",
                "White Horn",
                "White Horn",
                "White Horn",
                "Broken Horn",
                "Broken Horn",
                "Broken Horn",
                "Broken Horn",
                "Chain Horn",
                "Chain Horn",
                "Chain Horn",
                "Chain Horn",
                "Lollipop Horn",
                "Lollipop Horn",
                "Lollipop Horn",
                "Lollipop Horn",
                "Drill Horn",
                "Drill Horn",
                "Drill Horn",
                "Drill Horn",
                "Slime Horn",
                "Slime Horn",
                "Slime Horn",
                "Slime Horn",
                "Chalk Horn",
                "Chalk Horn",
                "Chalk Horn",
                "Chalk Horn",
                "Striped Metallic Horn",
                "Striped Metallic Horn",
                "Striped Metallic Horn",
                "Striped Metallic Horn",
                // Rare 2x
                // 16
                "Gold Horn",
                "Gold Horn",
                "Cucumber Horn",
                "Cucumber Horn",
                "Carrot Horn",
                "Carrot Horn",
                "Candy Cane Horn",
                "Candy Cane Horn",
                "Tesla Horn",
                "Tesla Horn",
                "Pencil Horn",
                "Pencil Horn",
                "Donut Horn",
                "Donut Horn",
                "Rainbow Horn",
                "Rainbow Horn",
                // Super Rare 1x
                // 6
                "Antler Horn",
                "Cyberpunk Horn",
                "Ethereum Horn",
                "Mech Horn",
                "Tri Horn",
                "Invisible Horn",
                // HAIR - 49
                // Common 4x
                // 36
                "Black Hair",
                "Black Hair",
                "Black Hair",
                "Black Hair",
                "White Hair",
                "White Hair",
                "White Hair",
                "White Hair",
                "Blue Hair",
                "Blue Hair",
                "Blue Hair",
                "Blue Hair",
                "Green Hair",
                "Green Hair",
                "Green Hair",
                "Green Hair",
                "Burgundy Hair",
                "Burgundy Hair",
                "Burgundy Hair",
                "Burgundy Hair",
                "Red Hair",
                "Red Hair",
                "Red Hair",
                "Red Hair",
                "Pastel Pink Hair",
                "Pastel Pink Hair",
                "Pastel Pink Hair",
                "Pastel Pink Hair",
                "Plastic Hair",
                "Plastic Hair",
                "Plastic Hair",
                "Plastic Hair",
                "Silver Hair",
                "Silver Hair",
                "Silver Hair",
                "Silver Hair",
                // Rare 2x
                // 10
                "Glass Hair",
                "Glass Hair",
                "Chalk Blue Hair",
                "Chalk Blue Hair",
                "Chalk Pink Hair",
                "Chalk Pink Hair",
                "Punk Hair",
                "Punk Hair",
                "Solid Gold Hair",
                "Solid Gold Hair",
                // Super Rare 1x
                // 3
                "Flames Hair",
                "Glowing Hair",
                "Funky Hair",
                // EYES - 35
                // Common 4x
                // 24
                "Standard Eyes",
                "Standard Eyes",
                "Standard Eyes",
                "Standard Eyes",
                "Chalk Eyes",
                "Chalk Eyes",
                "Chalk Eyes",
                "Chalk Eyes",
                "Metallic Eyes",
                "Metallic Eyes",
                "Metallic Eyes",
                "Metallic Eyes",
                "Glowing Eyes",
                "Glowing Eyes",
                "Glowing Eyes",
                "Glowing Eyes",
                "Black Eyes",
                "Black Eyes",
                "Black Eyes",
                "Black Eyes",
                "Gold Eyes",
                "Gold Eyes",
                "Gold Eyes",
                "Gold Eyes",
                // Rare 2x
                // 8
                "Sunglasses",
                "Sunglasses",
                "Blue Laser Eyes",
                "Blue Laser Eyes",
                "Futuristic Shades",
                "Futuristic Shades",
                "Robot Eyes",
                "Robot Eyes",
                // Super Rare 1x
                // 3
                "VR Headset",
                "Night Vision",
                "Pink Laser Eyes",
                // BACKGROUNDS - 44
                // Common 3x
                // 27
                "Purple",
                "Purple",
                "Purple",
                "Blue",
                "Blue",
                "Blue",
                "Red",
                "Red",
                "Red",
                "Yellow",
                "Yellow",
                "Yellow",
                "Dark",
                "Dark",
                "Dark",
                "Sky",
                "Sky",
                "Sky",
                "Chalk",
                "Chalk",
                "Chalk",
                "Green Pattern",
                "Green Pattern",
                "Green Pattern",
                "Blue Pattern",
                "Blue Pattern",
                "Blue Pattern",
                // Rare 2x
                // 14
                "Forest",
                "Forest",
                "Glacier",
                "Glacier",
                "Spring",
                "Spring",
                "Void",
                "Void",
                "Marsh",
                "Marsh",
                "Rainbow",
                "Rainbow",
                "Red Pattern",
                "Red Pattern",
                // Super Rare 1x
                // 3
                "Volcano",
                "Cyberpunk",
                "Space"
            ];

            uint256 cursor = 44;

            // 19 Wearables
            trait.wearable = GROUPS[
                ((randomness % 100000000) / 1000000) % cursor
            ];

            // 20 Items
            trait.item = GROUPS[
                (cursor + (((randomness % 10000000000) / 100000000) % 55))
            ];

            cursor += 55;

            // 29 Skins
            trait.skin = GROUPS[
                (cursor + (((randomness % 1000000000000) / 10000000000) % 71))
            ];

            cursor += 71;

            // 22 Horns
            trait.horn = GROUPS[
                (cursor +
                    (((randomness % 100000000000000) / 1000000000000) % 58))
            ];

            cursor += 58;

            // 17 Hairs
            trait.hair = GROUPS[
                (cursor +
                    (((randomness % 10000000000000000) / 100000000000000) % 49))
            ];

            cursor += 49;

            // 13 Eyes
            trait.eyes = GROUPS[
                (cursor +
                    (((randomness % 1000000000000000000) / 10000000000000000) %
                        35))
            ];

            cursor += 35;

            // 19 Backgrounds
            trait.background = GROUPS[
                (cursor +
                    (((randomness % 100000000000000000000) /
                        1000000000000000000) % 44))
            ];

            uint256 strength = 41 + (randomness % 50);
            uint256 speed = 41 + (((randomness % 10000) / 100) % 50);
            uint256 intelligence = 41 + (((randomness % 1000000) / 10000) % 50);

            return
                Unifriend({
                    strength: strength,
                    speed: speed,
                    intelligence: intelligence,
                    name: string(
                        abi.encodePacked(
                            "Genesis Unicorn: #",
                            Strings.toString(tokenId)
                        )
                    ),
                    description: string(
                        abi.encodePacked(
                            "The Unifriends metaverse began with the genesis unicorns. **#",
                            Strings.toString(tokenId),
                            "** is very special and one-of-a-kind. The unicorns have unparalleled purity and grace.",
                            "<br>Your unicorn has **",
                            Strings.toString(strength),
                            "** strength, **",
                            Strings.toString(speed),
                            "** speed, and **",
                            Strings.toString(intelligence),
                            "** intelligence."
                        )
                    ),
                    isLegendary: false,
                    trait: trait
                });
        }
    }

    function toProperties(Unifriend memory instance)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '{ "trait_type": "Legendary", "value": "',
                    instance.isLegendary ? "true" : "false",
                    '"}',
                    ', { "trait_type": "Strength", "display_type": "number", "value": "',
                    Strings.toString(instance.strength),
                    '"}',
                    ', { "trait_type": "Speed", "display_type": "number", "value": "',
                    Strings.toString(instance.speed),
                    '"}',
                    ', { "trait_type": "Intelligence", "display_type": "number", "value": "',
                    Strings.toString(instance.intelligence),
                    '"}'
                )
            );
    }

    function toTraits(Unifriend memory instance)
        internal
        pure
        returns (string memory)
    {
        if (instance.isLegendary) {
            return "";
        }

        return
            string(
                abi.encodePacked(
                    ', { "trait_type": "Wearable", "value": "',
                    instance.trait.wearable,
                    '"}',
                    ', { "trait_type": "Item", "value": "',
                    instance.trait.item,
                    '"}',
                    ', { "trait_type": "Horn", "value": "',
                    instance.trait.horn,
                    '"}',
                    ', { "trait_type": "Skin", "value": "',
                    instance.trait.skin,
                    '"}',
                    ', { "trait_type": "Hair", "value": "',
                    instance.trait.hair,
                    '"}',
                    ', { "trait_type": "Eyes", "value": "',
                    instance.trait.eyes,
                    '"}',
                    ', { "trait_type": "Background", "value": "',
                    instance.trait.background,
                    '"}'
                )
            );
    }

    function base64TokenURI(
        uint256 tokenId,
        string memory _baseURI,
        string memory _animationURI,
        uint256 _randomness
    ) public pure returns (string memory) {
        Unifriend memory instance = getUnifriendProperties(
            tokenId,
            _randomness
        );

        // Base64 encoding
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                "{",
                                toJSONProperty("name", instance.name),
                                ",",
                                toJSONProperty(
                                    "description",
                                    instance.description
                                ),
                                ",",
                                string(
                                    abi.encodePacked(
                                        '"attributes": ',
                                        string(
                                            abi.encodePacked(
                                                "[",
                                                string(
                                                    abi.encodePacked(
                                                        toProperties(instance),
                                                        toTraits(instance)
                                                    )
                                                ),
                                                "]"
                                            )
                                        )
                                    )
                                ),
                                ",",
                                toJSONProperty(
                                    "image",
                                    string(
                                        abi.encodePacked(
                                            _baseURI,
                                            Strings.toString(tokenId)
                                        )
                                    )
                                ),
                                ",",
                                toJSONProperty(
                                    "external_url",
                                    string(
                                        abi.encodePacked(
                                            _animationURI,
                                            Strings.toString(tokenId)
                                        )
                                    )
                                ),
                                ",",
                                toJSONProperty(
                                    "animation_url",
                                    string(
                                        abi.encodePacked(
                                            _animationURI,
                                            Strings.toString(tokenId)
                                        )
                                    )
                                ),
                                "}"
                            )
                        )
                    )
                )
            );
    }
}