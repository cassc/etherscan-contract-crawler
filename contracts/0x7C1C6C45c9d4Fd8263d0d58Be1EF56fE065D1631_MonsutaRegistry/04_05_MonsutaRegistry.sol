// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IMonsuta} from "./interfaces/IMonsuta.sol";

contract MonsutaRegistry is Ownable {
    struct Trait {
        string scene;
        string species;
        string skin;
        string eyes;
        string mouth;
        string markings;
        string ritual;
    }

    // Public variables

    bytes4[] public traitBytes;

    // Public constants
    uint256 public constant MAX_MONSUTA_SUPPLY = 8888;

    address public immutable monsutaAddress;
    uint256 public startingIndexFromMonsutaContract;

    /**
     * @dev Initializes the contract
     */
    constructor(address monsuta) {
        require(Address.isContract(monsuta), "!contract");
        monsutaAddress = monsuta;
    }

    /*
     * Store Metadata comprising of IPFS Hashes (In Hexadecimal minus the first two fixed bytes) and explicit traits
     * Ordered according to original hashed sequence pertaining to the Hashmonsutas provenance
     * Ownership is intended to be burned (Renounced) after storage is completed
     */
    function storeMetadata(bytes4[] memory traitsHex) public onlyOwner {
        storeMetadataStartingAtIndex(traitBytes.length, traitsHex);
    }

    /*
     * Store metadata starting at a particular index. In case any corrections are required before completion
     */
    function storeMetadataStartingAtIndex(
        uint256 startIndex,
        bytes4[] memory traitsHex
    ) public onlyOwner {
        require(startIndex <= traitBytes.length, "bad length");

        for (uint256 i; i < traitsHex.length; ) {
            if ((i + startIndex) >= traitBytes.length) {
                traitBytes.push(traitsHex[i]);
            } else {
                traitBytes[i + startIndex] = traitsHex[i];
            }

            unchecked {
                ++i;
            }
        }

        // Post-assertions
        require(traitBytes.length <= MAX_MONSUTA_SUPPLY, ">max");
    }

    function reveal() external onlyOwner {
        require(startingIndexFromMonsutaContract == 0, "already did");

        IMonsuta monsuta = IMonsuta(monsutaAddress);
        uint256 startingIndex = monsuta.startingIndex();

        require(startingIndex != 0, "not revealed yet");

        startingIndexFromMonsutaContract = startingIndex;
    }

    /*
     * Returns the trait bytes for the Hashmonsuta image at specified position in the original hashed sequence
     */
    function getTraitBytesAtIndex(uint256 index) public view returns (bytes4) {
        require(
            index < traitBytes.length,
            "Metadata does not exist for the specified index"
        );
        return traitBytes[index];
    }

    function getTraitsOfMonsutaId(uint256 monsutaId)
        public
        view
        returns (Trait memory trait)
    {
        require(
            monsutaId < MAX_MONSUTA_SUPPLY,
            "Monsuta ID must be less than max"
        );

        // Derives the index of the image in the original sequence assigned to the Monsuta ID
        uint256 correspondingOriginalSequenceIndex = (monsutaId +
            startingIndexFromMonsutaContract) % MAX_MONSUTA_SUPPLY;

        bytes4 _traitBytes = getTraitBytesAtIndex(
            correspondingOriginalSequenceIndex
        );

        return
            Trait(
                _extractSceneTrait(_traitBytes),
                _extractSpeciesTrait(_traitBytes),
                _extractSkinTrait(_traitBytes),
                _extractEyesTrait(_traitBytes),
                _extractMouthTrait(_traitBytes),
                _extractMarkingsTrait(_traitBytes),
                _extractRitualTrait(_traitBytes)
            );
    }

    function getEncodedTraitsOfMonsutaId(uint256 monsutaId, uint256 state)
        public
        view
        returns (bytes memory traits)
    {
        Trait memory trait = getTraitsOfMonsutaId(monsutaId);

        return
            bytes.concat(
                abi.encodePacked(
                    '"attributes": [{ "trait_type": "Scene", "value": "',
                    trait.scene,
                    '"}, { "trait_type": "Species", "value": "',
                    trait.species,
                    '"}, { "trait_type": "Skin", "value": "',
                    trait.skin,
                    '"}, { "trait_type": "Eyes", "value": "',
                    trait.eyes
                ),
                abi.encodePacked(
                    '"}, { "trait_type": "Mouth", "value": "',
                    trait.mouth,
                    '"}, { "trait_type": "Markings", "value": "',
                    trait.markings,
                    '"}, { "trait_type": "Ritual", "value": "',
                    trait.ritual,
                    '"}, { "trait_type": "Version", "value": "',
                    state == 2
                        ? "Soul Monsuta"
                        : (state == 1 ? "Evolved Monsuta" : "Monsuta"),
                    '"}]'
                )
            );
    }

    function _extractSceneTrait(bytes4 _traitBytes)
        internal
        pure
        returns (string memory scene)
    {
        bytes1 sceneBits = _traitBytes[0] & 0x0F;

        if (sceneBits == 0x00) {
            scene = "Lonely";
        } else if (sceneBits == 0x01) {
            scene = "Somber Thoughts";
        } else if (sceneBits == 0x02) {
            scene = "Vertigo";
        } else if (sceneBits == 0x03) {
            scene = "Phantasm";
        } else if (sceneBits == 0x04) {
            scene = "Hell 666";
        } else if (sceneBits == 0x05) {
            scene = "Forsaken Fields";
        } else if (sceneBits == 0x06) {
            scene = "Empty Fields";
        } else if (sceneBits == 0x07) {
            scene = "Silent Hill";
        } else if (sceneBits == 0x08) {
            scene = "Limbo";
        } else if (sceneBits == 0x09) {
            scene = "Fallen";
        } else if (sceneBits == 0x0A) {
            scene = "Empty Within";
        } else if (sceneBits == 0x0B) {
            scene = "Forbidden Forest";
        } else if (sceneBits == 0x0C) {
            scene = "Desolate Souls";
        } else if (sceneBits == 0x0D) {
            scene = "Dante's Rest";
        } else if (sceneBits == 0x0E) {
            scene = "Cold Rest";
        } else if (sceneBits == 0x0F) {
            scene = "Forbidden City";
        }
    }

    function _extractSpeciesTrait(bytes4 _traitBytes)
        internal
        pure
        returns (string memory species)
    {
        bytes1 speciesBits = _traitBytes[0] >> 4;

        if (speciesBits == 0x00) {
            species = "Chaos";
        } else if (speciesBits == 0x01) {
            species = "Shadow";
        } else if (speciesBits == 0x02) {
            species = "Dread";
        } else if (speciesBits == 0x03) {
            species = "Ghost";
        } else if (speciesBits == 0x04) {
            species = "Sinner";
        } else if (speciesBits == 0x05) {
            species = "Wraith";
        } else if (speciesBits == 0x06) {
            species = "Ghoul";
        } else {
            species = "None";
        }
    }

    function _extractSkinTrait(bytes4 _traitBytes)
        internal
        pure
        returns (string memory skin)
    {
        bytes1 skinBits = _traitBytes[1] & 0x0F;

        if (skinBits == 0x00) {
            skin = "Darkness";
        } else if (skinBits == 0x01) {
            skin = "Toxic";
        } else if (skinBits == 0x02) {
            skin = "Heartless";
        } else if (skinBits == 0x03) {
            skin = "Dead Stars";
        } else if (skinBits == 0x04) {
            skin = "Inferno";
        } else if (skinBits == 0x05) {
            skin = "Serpent";
        } else if (skinBits == 0x06) {
            skin = "Prism";
        } else if (skinBits == 0x07) {
            skin = "Firestorm";
        } else if (skinBits == 0x08) {
            skin = "Cursed";
        } else if (skinBits == 0x09) {
            skin = "Galactic";
        } else if (skinBits == 0x0A) {
            skin = "Spark";
        } else if (skinBits == 0x0B) {
            skin = "Dreamcast";
        } else if (skinBits == 0x0C) {
            skin = "Blazed";
        } else if (skinBits == 0x0D) {
            skin = "Cyanide";
        } else if (skinBits == 0x0E) {
            skin = "Bones";
        } else if (skinBits == 0x0F) {
            skin = "Resin";
        }
    }

    function _extractEyesTrait(bytes4 _traitBytes)
        internal
        pure
        returns (string memory eyes)
    {
        bytes1 eyesBits = _traitBytes[1] >> 4;

        if (eyesBits == 0x00) {
            eyes = "Grief";
        } else if (eyesBits == 0x01) {
            eyes = "Depraved";
        } else if (eyesBits == 0x02) {
            eyes = "Terror";
        } else if (eyesBits == 0x03) {
            eyes = "Shadowy";
        } else if (eyesBits == 0x04) {
            eyes = "Joyless";
        } else if (eyesBits == 0x05) {
            eyes = "Grim";
        } else if (eyesBits == 0x06) {
            eyes = "Wicked";
        } else if (eyesBits == 0x07) {
            eyes = "Omen";
        } else if (eyesBits == 0x08) {
            eyes = "Funeral";
        } else if (eyesBits == 0x09) {
            eyes = "Deep";
        } else if (eyesBits == 0x0A) {
            eyes = "Panic";
        } else if (eyesBits == 0x0B) {
            eyes = "Doomy";
        } else if (eyesBits == 0x0C) {
            eyes = "Chilled";
        } else if (eyesBits == 0x0D) {
            eyes = "Dimension";
        } else if (eyesBits == 0x0E) {
            eyes = "Spooky";
        } else if (eyesBits == 0x0F) {
            eyes = "Stormy";
        }
    }

    function _extractMouthTrait(bytes4 _traitBytes)
        internal
        pure
        returns (string memory mouth)
    {
        bytes1 mouthBits = _traitBytes[2] & 0x0F;

        if (mouthBits == 0x00) {
            mouth = "Chomper";
        } else if (mouthBits == 0x01) {
            mouth = "Insidious";
        } else if (mouthBits == 0x02) {
            mouth = "Chainsaw";
        } else if (mouthBits == 0x03) {
            mouth = "Stitches";
        } else if (mouthBits == 0x04) {
            mouth = "Thing";
        } else if (mouthBits == 0x05) {
            mouth = "Stranger";
        } else if (mouthBits == 0x06) {
            mouth = "Slasher";
        } else if (mouthBits == 0x07) {
            mouth = "Psycho";
        } else if (mouthBits == 0x08) {
            mouth = "Prodigy";
        } else if (mouthBits == 0x09) {
            mouth = "Myth";
        } else if (mouthBits == 0x0A) {
            mouth = "Maniac";
        } else if (mouthBits == 0x0B) {
            mouth = "Awakened";
        } else if (mouthBits == 0x0C) {
            mouth = "Hunter";
        } else if (mouthBits == 0x0D) {
            mouth = "Lost";
        } else if (mouthBits == 0x0E) {
            mouth = "Horror";
        } else if (mouthBits == 0x0F) {
            mouth = "Morgue";
        }
    }

    function _extractMarkingsTrait(bytes4 _traitBytes)
        internal
        pure
        returns (string memory markings)
    {
        bytes1 markingsBits = _traitBytes[2] >> 4;

        if (markingsBits == 0x00) {
            markings = "Spider";
        } else if (markingsBits == 0x01) {
            markings = "Monkey";
        } else if (markingsBits == 0x02) {
            markings = "Lizard";
        } else if (markingsBits == 0x03) {
            markings = "Wolf";
        } else if (markingsBits == 0x04) {
            markings = "Rat";
        } else if (markingsBits == 0x05) {
            markings = "Owl";
        } else if (markingsBits == 0x06) {
            markings = "Koi";
        } else if (markingsBits == 0x07) {
            markings = "Frog";
        } else if (markingsBits == 0x08) {
            markings = "Cat";
        } else if (markingsBits == 0x09) {
            markings = "Moth";
        } else if (markingsBits == 0x0A) {
            markings = "Demon";
        } else if (markingsBits == 0x0B) {
            markings = "Butterfly";
        } else if (markingsBits == 0x0C) {
            markings = "Scorpion";
        } else if (markingsBits == 0x0D) {
            markings = "Monster";
        } else if (markingsBits == 0x0E) {
            markings = "Bat";
        } else if (markingsBits == 0x0F) {
            markings = "Rabbit";
        }
    }

    function _extractRitualTrait(bytes4 _traitBytes)
        internal
        pure
        returns (string memory ritual)
    {
        bytes1 ritualBits = _traitBytes[3] & 0x0F;

        if (ritualBits == 0x00) {
            ritual = "Untrue";
        } else if (ritualBits == 0x01) {
            ritual = "Unrest";
        } else if (ritualBits == 0x02) {
            ritual = "Grimoire";
        } else if (ritualBits == 0x03) {
            ritual = "Blind";
        } else if (ritualBits == 0x04) {
            ritual = "Secrets";
        } else if (ritualBits == 0x05) {
            ritual = "Hypnosis";
        } else if (ritualBits == 0x06) {
            ritual = "Memory";
        } else if (ritualBits == 0x07) {
            ritual = "Rouge";
        } else if (ritualBits == 0x08) {
            ritual = "Mana";
        } else if (ritualBits == 0x09) {
            ritual = "Trespass";
        } else if (ritualBits == 0x0A) {
            ritual = "Shaman";
        } else if (ritualBits == 0x0B) {
            ritual = "Evoke";
        } else if (ritualBits == 0x0C) {
            ritual = "Emotion";
        } else if (ritualBits == 0x0D) {
            ritual = "Le Dragon";
        } else if (ritualBits == 0x0E) {
            ritual = "Demonic";
        } else if (ritualBits == 0x0F) {
            ritual = "Neo";
        }
    }
}