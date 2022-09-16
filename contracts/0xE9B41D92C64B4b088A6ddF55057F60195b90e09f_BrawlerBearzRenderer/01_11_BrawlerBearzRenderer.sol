// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";
import {IBrawlerBearzRenderer} from "./interfaces/IBrawlerBearzRenderer.sol";
import {IBrawlerBearzDynamicItems} from "./interfaces/IBrawlerBearzDynamicItems.sol";
import {Genes} from "./Genes.sol";

/*******************************************************************************
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@|(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@|,|@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&@@@@@@@@@@@|,*|&@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%,**%@@@@@@@@%|******%&@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&##*****|||**,(%%%%%**|%@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@***,#%%%%**#&@@@@@#**,|@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@*,(@@@@@@@@@@**,(&@@@@#**%@@@@@@||(%@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@%|,****&@((@&***&@@@@@@%||||||||#%&@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@&%#*****||||||**#%&@%%||||||||#@&%#(@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@&**,(&@@@@@%|||||*##&&&&##|||||(%@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@**,%@@@@@@@(|*|#%@@@@@@@@#||#%%@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@#||||#@@@@||*|%@@@@@@@@&|||%%&@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@#,,,,,,*|**||%|||||||###&@@@@@@@#|||#%@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@&#||*|||||%%%@%%%#|||%@@@@@@@@&(|(%&@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@&&%%(||||@@@@@@&|||||(%&((||(#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@%%(||||||||||#%#(|||||%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@&%#######%%@@**||(#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%##%%&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
********************************************************************************/

/**************************************************
 * @title BrawlerBearzRenderer
 * @author @ScottMitchell18
 **************************************************/

contract BrawlerBearzRenderer is IBrawlerBearzRenderer, Ownable {
    using Strings for uint256;
    using Genes for uint256;

    uint256 constant STR_BASIS = 100;
    uint256 constant END_BASIS = 100;
    uint256 constant INT_BASIS = 100;
    uint256 constant LCK_BASIS = 10;
    uint256 constant XP_BASIS = 2000;

    /// @notice Base URI for assets
    string public baseURI;

    /// @notice Animation URI for assets
    string public animationURI;

    /// @notice Vendor contract
    IBrawlerBearzDynamicItems public vendorContract;

    constructor(string memory _baseURI, string memory _animationURI) {
        baseURI = _baseURI;
        animationURI = _animationURI;
    }

    function toJSONProperty(string memory key, string memory value)
        public
        pure
        returns (string memory)
    {
        return string(abi.encodePacked('"', key, '" : "', value, '"'));
    }

    function toJSONNumberAttribute(string memory key, string memory value)
        public
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '{ "trait_type":"',
                    key,
                    '", "value": "',
                    value,
                    '", "display_type": "number"',
                    "}"
                )
            );
    }

    function toJSONAttribute(string memory key, string memory value)
        public
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '{ "trait_type":"',
                    key,
                    '", "value": "',
                    value,
                    '"}'
                )
            );
    }

    function toJSONAttributeList(string[] memory attributes)
        internal
        pure
        returns (string memory)
    {
        bytes memory attributeListBytes = "[";
        for (uint256 i = 0; i < attributes.length; i++) {
            attributeListBytes = abi.encodePacked(
                attributeListBytes,
                attributes[i],
                i != attributes.length - 1 ? "," : "]"
            );
        }
        return string(attributeListBytes);
    }

    function gaussianTrait(
        uint256 seed,
        uint256 numSampling,
        uint256 samplingBits
    ) internal pure returns (uint256 trait) {
        uint256 samplingMask = (1 << samplingBits) - 1;
        unchecked {
            for (uint256 i = 0; i < numSampling; i++) {
                trait += (seed >> (i * samplingBits)) & samplingMask;
            }
        }
    }

    function factionIdToName(uint256 factionId)
        internal
        pure
        returns (string memory)
    {
        if (factionId == 1) {
            return "IRONBEARZ";
        } else if (factionId == 2) {
            return "GEOSCAPEZ";
        } else if (factionId == 3) {
            return "PAWPUNKZ";
        } else if (factionId == 4) {
            return "TECHHEADZ";
        } else {
            return "NOMAD";
        }
    }

    function getHiddenProperties(uint256 tokenId)
        internal
        view
        returns (Bear memory)
    {
        Traits memory traits;
        CustomMetadata memory dynamic;
        return
            Bear({
                name: string(
                    abi.encodePacked("Brawler #", Strings.toString(tokenId))
                ),
                description: "Fight or die. This is the life of the brawlers...",
                dna: "hidden",
                traits: traits,
                dynamic: dynamic
            });
    }

    function getProperties(
        uint256 tokenId,
        uint256 seed,
        CustomMetadata memory md
    ) internal view returns (Bear memory) {
        uint256 chromosome = Genes.seedToChromosome(seed);

        Traits memory traits;
        CustomMetadata memory dynamic;

        // Faction
        traits.faction = factionIdToName(md.faction);
        dynamic.faction = md.faction;

        // Evolving
        traits.level = 1 + (md.xp > 0 ? sqrt(md.xp / XP_BASIS) : 0);
        traits.locked = md.isUnlocked ? "FALSE" : "TRUE";

        traits.strength =
            traits.level *
            (STR_BASIS +
                gaussianTrait(
                    (
                        uint256(
                            keccak256(abi.encode(seed, keccak256("strength")))
                        )
                    ),
                    5,
                    5
                ));

        traits.endurance =
            traits.level *
            (END_BASIS +
                gaussianTrait(
                    (
                        uint256(
                            keccak256(abi.encode(seed, keccak256("endurance")))
                        )
                    ),
                    5,
                    5
                ));

        traits.intelligence = (INT_BASIS +
            gaussianTrait(
                (
                    uint256(
                        keccak256(abi.encode(seed, keccak256("intelligence")))
                    )
                ),
                5,
                5
            ));

        traits.luck =
            (LCK_BASIS +
                gaussianTrait(
                    (uint256(keccak256(abi.encode(seed, keccak256("luck"))))),
                    3,
                    3
                )) %
            100;

        traits.xp = md.xp;

        // Base traits
        traits.skin = Genes.getSkinValue(chromosome);
        traits.head = Genes.getHeadValue(chromosome);
        traits.eyes = Genes.getEyesValue(chromosome);
        traits.outfit = Genes.getOutfitValue(chromosome);
        traits.mouth = Genes.getMouthValue(chromosome);
        traits.background = Genes.getBackgroundValue(chromosome);

        // Dynamic traits
        dynamic.background = 0; // Has default + dynamic background

        traits.weapon = "NONE";
        dynamic.weapon = 0;

        traits.armor = "NONE";
        dynamic.armor = 0;

        traits.faceArmor = "NONE";
        dynamic.faceArmor = 0;

        traits.eyewear = "NONE";
        dynamic.eyewear = 0;

        traits.misc = "NONE";
        dynamic.misc = 0;

        // Set dynamic background
        if (md.background > 0) {
            traits.background = vendorContract.getItemName(md.background);
            dynamic.background = md.background;
            chromosome <<= 8;
            chromosome |= md.background;
        } else {
            chromosome <<= 8;
            chromosome |= 0;
        }

        // Set dynamic weapon
        if (md.weapon > 0) {
            traits.weapon = vendorContract.getItemName(md.weapon);
            dynamic.weapon = md.weapon;
            chromosome <<= 8;
            chromosome |= md.weapon;
        } else {
            chromosome <<= 8;
            chromosome |= 0;
        }

        // Set dynamic armor
        if (md.armor > 0) {
            traits.armor = vendorContract.getItemName(md.armor);
            dynamic.armor = md.armor;
            chromosome <<= 8;
            chromosome |= md.armor;
        } else {
            chromosome <<= 8;
            chromosome |= 0;
        }

        // Set dynamic face armor
        if (md.faceArmor > 0) {
            traits.faceArmor = vendorContract.getItemName(md.faceArmor);
            dynamic.faceArmor = md.faceArmor;
            chromosome <<= 8;
            chromosome |= md.faceArmor;
        } else {
            chromosome <<= 8;
            chromosome |= 0;
        }

        // Set dynamic eyewear
        if (md.eyewear > 0) {
            traits.eyewear = vendorContract.getItemName(md.eyewear);
            dynamic.eyewear = md.eyewear;
            chromosome <<= 8;
            chromosome |= md.eyewear;
        } else {
            chromosome <<= 8;
            chromosome |= 0;
        }

        // Set dynamic misc
        if (md.misc > 0) {
            traits.misc = vendorContract.getItemName(md.misc);
            dynamic.misc = md.misc;
            chromosome <<= 8;
            chromosome |= md.misc;
        } else {
            chromosome <<= 8;
            chromosome |= 0;
        }

        // Set dynamic head
        if (md.head > 0) {
            traits.head = vendorContract.getItemName(md.head);
            dynamic.head = md.head;
            chromosome <<= 8;
            chromosome |= md.head;
        } else {
            chromosome <<= 8;
            chromosome |= 0;
        }

        return
            Bear({
                name: (bytes(md.name).length > 0)
                    ? md.name
                    : string(
                        abi.encodePacked("Brawler #", Strings.toString(tokenId))
                    ),
                description: (bytes(md.lore).length > 0) ? md.lore : "",
                dna: Strings.toString(chromosome),
                traits: traits,
                dynamic: dynamic
            });
    }

    // ========================================
    // NFT display helpers
    // ========================================

    /**
     * @notice Sets the base URI for the image asset
     * @param _baseURI A base uri
     */
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /**
     * @notice Sets the animation URI for the image asset
     * @param _animationURI A base uri
     */
    function setAnimationURI(string memory _animationURI) external onlyOwner {
        animationURI = _animationURI;
    }

    /**
     * @notice Returns a json list of dynamic properties
     * @param instance A bear instance
     */
    function toDynamicProperties(Bear memory instance)
        internal
        view
        returns (string memory)
    {
        string[] memory dynamic = new string[](15);

        dynamic[0] = toJSONAttribute(
            "Background Id",
            Strings.toString(instance.dynamic.background)
        );

        dynamic[1] = toJSONAttribute(
            "Background Name",
            vendorContract.getItemName(instance.dynamic.background)
        );

        dynamic[2] = toJSONAttribute(
            "Weapon Id",
            Strings.toString(instance.dynamic.weapon)
        );

        dynamic[3] = toJSONAttribute(
            "Weapon Name",
            vendorContract.getItemName(instance.dynamic.weapon)
        );

        dynamic[4] = toJSONAttribute(
            "Face Armor Id",
            Strings.toString(instance.dynamic.faceArmor)
        );

        dynamic[5] = toJSONAttribute(
            "Face Armor Name",
            vendorContract.getItemName(instance.dynamic.faceArmor)
        );

        dynamic[6] = toJSONAttribute(
            "Armor Id",
            Strings.toString(instance.dynamic.armor)
        );

        dynamic[7] = toJSONAttribute(
            "Armor Name",
            vendorContract.getItemName(instance.dynamic.armor)
        );

        dynamic[8] = toJSONAttribute(
            "Eyewear Id",
            Strings.toString(instance.dynamic.eyewear)
        );

        dynamic[9] = toJSONAttribute(
            "Eyewear Name",
            vendorContract.getItemName(instance.dynamic.eyewear)
        );

        dynamic[10] = toJSONAttribute(
            "Misc Id",
            Strings.toString(instance.dynamic.misc)
        );

        dynamic[11] = toJSONAttribute(
            "Misc Name",
            vendorContract.getItemName(instance.dynamic.misc)
        );

        dynamic[12] = toJSONAttribute(
            "Faction Id",
            Strings.toString(instance.dynamic.faction)
        );

        dynamic[13] = toJSONAttribute(
            "Head Id",
            Strings.toString(instance.dynamic.head)
        );

        dynamic[14] = toJSONAttribute(
            "Head Name",
            vendorContract.getItemName(instance.dynamic.head)
        );

        return toJSONAttributeList(dynamic);
    }

    /**
     * @notice Sets the bearz vendor item contract
     * @dev only owner call this function
     * @param _vendorContractAddress The new contract address
     */
    function setVendorContractAddress(address _vendorContractAddress)
        public
        onlyOwner
    {
        vendorContract = IBrawlerBearzDynamicItems(_vendorContractAddress);
    }

    /**
     * @notice Returns a json list of attribute properties
     * @param instance A bear instance
     */
    function toAttributesProperty(Bear memory instance)
        internal
        pure
        returns (string memory)
    {
        string[] memory attributes = new string[](19);

        attributes[0] = toJSONAttribute("Head", instance.traits.head);

        attributes[1] = toJSONAttribute("Skin", instance.traits.skin);

        attributes[2] = toJSONAttribute("Eyes", instance.traits.eyes);

        attributes[3] = toJSONAttribute("Outfit", instance.traits.outfit);

        attributes[4] = toJSONAttribute("Mouth", instance.traits.mouth);

        attributes[5] = toJSONAttribute(
            "Background",
            instance.traits.background
        );

        attributes[6] = toJSONAttribute("Armor", instance.traits.armor);

        attributes[7] = toJSONAttribute(
            "Face Armor",
            instance.traits.faceArmor
        );

        attributes[8] = toJSONAttribute("Eyewear", instance.traits.eyewear);

        attributes[9] = toJSONAttribute("Weapon", instance.traits.weapon);

        attributes[10] = toJSONAttribute("Miscellaneous", instance.traits.misc);

        attributes[11] = toJSONNumberAttribute(
            "XP",
            Strings.toString(instance.traits.xp)
        );

        attributes[12] = toJSONNumberAttribute(
            "Level",
            Strings.toString(instance.traits.level)
        );

        attributes[13] = toJSONNumberAttribute(
            "Strength",
            Strings.toString(instance.traits.strength)
        );

        attributes[14] = toJSONNumberAttribute(
            "Endurance",
            Strings.toString(instance.traits.endurance)
        );

        attributes[15] = toJSONNumberAttribute(
            "Intelligence",
            Strings.toString(instance.traits.intelligence)
        );

        attributes[16] = toJSONNumberAttribute(
            "Luck",
            Strings.toString(instance.traits.luck)
        );

        attributes[17] = toJSONAttribute("Is Locked", instance.traits.locked);

        attributes[18] = toJSONAttribute("Faction", instance.traits.faction);

        return toJSONAttributeList(attributes);
    }

    /**
     * @notice Returns hidden base64 json metadata
     * @param _tokenId The bear token id
     */
    function hiddenURI(uint256 _tokenId) public view returns (string memory) {
        Bear memory instance = getHiddenProperties(_tokenId);
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
                                toJSONProperty(
                                    "image",
                                    string(
                                        abi.encodePacked(baseURI, instance.dna)
                                    )
                                ),
                                ",",
                                toJSONProperty(
                                    "animation_url",
                                    string(
                                        abi.encodePacked(
                                            animationURI,
                                            instance.dna
                                        )
                                    )
                                ),
                                ",",
                                toJSONProperty(
                                    "external_url",
                                    string(
                                        abi.encodePacked(
                                            animationURI,
                                            instance.dna
                                        )
                                    )
                                ),
                                ",",
                                toJSONProperty(
                                    "tokenId",
                                    Strings.toString(_tokenId)
                                ),
                                ",",
                                toJSONProperty("dna", instance.dna),
                                "}"
                            )
                        )
                    )
                )
            );
    }

    /// @notice Returns the dna for a given token, seed, and metadata
    function dna(
        uint256 _tokenId,
        uint256 _seed,
        CustomMetadata memory _md
    ) public view returns (string memory) {
        Bear memory instance = getProperties(_tokenId, _seed, _md);
        return instance.dna;
    }

    /**
     * @notice Returns a base64 json metadata
     * @param _tokenId The bear token id
     * @param _seed The generated seed
     * @param _md The custom metadata
     */
    function tokenURI(
        uint256 _tokenId,
        uint256 _seed,
        CustomMetadata memory _md
    ) public view returns (string memory) {
        Bear memory instance = getProperties(_tokenId, _seed, _md);
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
                                toJSONProperty(
                                    "image",
                                    string(
                                        abi.encodePacked(baseURI, instance.dna)
                                    )
                                ),
                                ",",
                                toJSONProperty(
                                    "animation_url",
                                    string(
                                        abi.encodePacked(
                                            animationURI,
                                            instance.dna
                                        )
                                    )
                                ),
                                ",",
                                toJSONProperty(
                                    "external_url",
                                    string(
                                        abi.encodePacked(
                                            animationURI,
                                            instance.dna
                                        )
                                    )
                                ),
                                ",",
                                abi.encodePacked(
                                    '"equipped": ',
                                    toDynamicProperties(instance)
                                ),
                                ",",
                                abi.encodePacked(
                                    '"attributes": ',
                                    toAttributesProperty(instance)
                                ),
                                ",",
                                toJSONProperty(
                                    "tokenId",
                                    Strings.toString(_tokenId)
                                ),
                                ",",
                                toJSONProperty("seed", Strings.toString(_seed)),
                                ",",
                                toJSONProperty("dna", instance.dna),
                                "}"
                            )
                        )
                    )
                )
            );
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0 (default value)
    }
}