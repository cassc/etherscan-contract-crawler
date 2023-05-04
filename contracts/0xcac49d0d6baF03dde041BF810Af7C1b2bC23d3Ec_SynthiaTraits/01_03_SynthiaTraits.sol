pragma solidity ^0.8.0;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract SynthiaTraits is Ownable {
    string[] bgColors = [
        "#FF2079",
        "#28fcb3",
        "#1C1C1C",
        "#7122FA",
        "#FDBC3B",
        "#1ba6fe"
    ];

    function getClothesName(
        uint16 x,
        uint16 y
    ) public pure returns (string memory) {
        uint32 position = packXY(x, y);
        string memory name;
        if (position == 0) {
            name = "Rustic Cotton Shirt";
        } else if (position == 65536) {
            name = "Rebel Collar Shirt";
        } else if (position == 131072) {
            name = "Earthbound Hooded Shirt";
        } else if (position == 196608) {
            name = "Naturalist Layered Tunic";
        } else if (position == 262144) {
            name = "Traditional Linen Shirt";
        } else if (position == 1) {
            name = "Clandestine Button-Down";
        } else if (position == 65537) {
            name = "Stealth-Tech Long Sleeve";
        } else if (position == 131073) {
            name = "Encryptor Shirt";
        } else if (position == 196609) {
            name = "Cipher Shirt";
        } else if (position == 262145) {
            name = "Holographic Hoodie";
        } else if (position == 2) {
            name = "Transcendent Shoulderless Top";
        } else if (position == 65538) {
            name = "Mystic Cutaway Shirt";
        } else if (position == 131074) {
            name = "Spiritual Circuit Cowl";
        } else if (position == 196610) {
            name = "Enchanted Tech Hoodie";
        } else if (position == 262146) {
            name = "Etheric Energy Shirt";
        } else if (position == 3) {
            name = "Cybernetic Infiltrator Jacket";
        } else if (position == 65539) {
            name = "Stealth Matrix Jacket";
        } else if (position == 131075) {
            name = "Hologram Hacker Jacket";
        } else if (position == 196611) {
            name = "Firewall Breaker Jacket";
        } else if (position == 262147) {
            name = "Cryptic Code Hoodie";
        } else if (position == 4) {
            name = "Harmonic Interface Bodysuit";
        } else if (position == 65540) {
            name = "Dual Existence Exoskeleton";
        } else if (position == 131076) {
            name = "Fusion Suit";
        } else if (position == 196612) {
            name = "Adaptive Synthesis Jumpsuit";
        } else if (position == 262148) {
            name = "Biomechanical Balance Armor";
        } else if (position == 5) {
            name = "Autonomous Muscle Shirt";
        } else if (position == 65541) {
            name = "Off The Grid Shirt";
        } else if (position == 131077) {
            name = "Autonomous Jacket";
        } else if (position == 196613) {
            name = "Independent Shirt";
        } else if (position == 262149) {
            name = "Privacy Shoulder Guard";
        }

        return name;
    }

    function getHairName(
        uint16 x,
        uint16 y
    ) public pure returns (string memory) {
        uint32 position = packXY(x, y);
        string memory name;
        if (position == 0) {
            name = "Wild Tangle";
        } else if (position == 65536) {
            name = "Windswept Waves";
        } else if (position == 131072) {
            name = "Nature Inspired Volume";
        } else if (position == 196608) {
            name = "Rustic Updo";
        } else if (position == 262144) {
            name = "Earthy Braids";
        } else if (position == 1) {
            name = "Sleek Side Sweep";
        } else if (position == 65537) {
            name = "Holographic Tie Back";
        } else if (position == 131073) {
            name = "Futuristic Buzz";
        } else if (position == 196609) {
            name = "Covert Pony";
        } else if (position == 262145) {
            name = "Digital Duality Crew";
        } else if (position == 2) {
            name = "Spirit-Woven Locks";
        } else if (position == 65538) {
            name = "Aetheric Locks";
        } else if (position == 131074) {
            name = "Chakra-Balanced Curls";
        } else if (position == 196610) {
            name = "Mystic Baldness";
        } else if (position == 262146) {
            name = "Enchanted Long Hair";
        } else if (position == 3) {
            name = "Datastream";
        } else if (position == 65539) {
            name = "Glitchy Buzzcut";
        } else if (position == 131075) {
            name = "Cyberpunk Slick";
        } else if (position == 196611) {
            name = "Matrix Slick";
        } else if (position == 262147) {
            name = "Datastream Quiff";
        } else if (position == 4) {
            name = "Biomech Fringe";
        } else if (position == 65540) {
            name = "Hybrid Side Sweep";
        } else if (position == 131076) {
            name = "Synthesized Spikes";
        } else if (position == 196612) {
            name = "Organic Circuit";
        } else if (position == 262148) {
            name = "Two-Worlds Tousle";
        } else if (position == 5) {
            name = "Free Spirit Patch";
        } else if (position == 65541) {
            name = "Liberated Side Shave";
        } else if (position == 131077) {
            name = "Unbound Layered Cut";
        } else if (position == 196613) {
            name = "Outlier Long-Straight";
        } else if (position == 262149) {
            name = "Rebel Pomp";
        }

        return name;
    }

    function getHatName(
        uint16 x,
        uint16 y
    ) public pure returns (string memory) {
        uint32 position = packXY(x, y);
        string memory name;

        if (position == 0) {
            name = "Timeless Bowler Cap";
        } else if (position == 65536) {
            name = "Heritage Bowler Hat";
        } else if (position == 131072) {
            name = "Nature's Embrace Headband";
        } else if (position == 196608) {
            name = "Organic Slouch Beanie";
        } else if (position == 262144) {
            name = "Earthen Earflap Hat";
        } else if (position == 1) {
            name = "Enigma Infiltrator Helmet";
        } else if (position == 65537) {
            name = "Shadow Broker Visor";
        } else if (position == 131073) {
            name = "Veiled Intellect Headgear";
        } else if (position == 196609) {
            name = "Cryptic Interface Helm";
        } else if (position == 262145) {
            name = "Secret Network Visor";
        } else if (position == 2) {
            name = "Astral Resonance Headpiece";
        } else if (position == 65538) {
            name = "Transcendent Energy Veil";
        } else if (position == 131074) {
            name = "Spirit-Tech Headgear";
        } else if (position == 196610) {
            name = "Mystical Sound Mask";
        } else if (position == 262146) {
            name = "Etheric Amplifier Crown";
        } else if (position == 3) {
            name = "Anonymous Infiltrator Mask";
        } else if (position == 65539) {
            name = "Firewall Breacher Helmet";
        } else if (position == 131075) {
            name = "Holographic Intruder Helm";
        } else if (position == 196611) {
            name = "Decryption Master Headpiece";
        } else if (position == 262147) {
            name = "Cyber Stealth Bandana";
        } else if (position == 4) {
            name = "Cyber-Organic Circlet";
        } else if (position == 65540) {
            name = "Symbiotic Synthesis Helmet";
        } else if (position == 131076) {
            name = "Harmony Seeker Mask";
        } else if (position == 196612) {
            name = "Dual-Worlds Visor";
        } else if (position == 262148) {
            name = "Integrated Identity Module";
        } else if (position == 5) {
            name = "Off-Grid Guardian Helm";
        } else if (position == 65541) {
            name = "Untraceable Survivor Helmet";
        } else if (position == 131077) {
            name = "Autonomous Defender Headgear";
        } else if (position == 196613) {
            name = "Rogue Resistor Helm";
        } else if (position == 262149) {
            name = "Hidden Haven Headpiece";
        }

        return name;
    }

    function getAccesoryName(
        uint16 x,
        uint16 y
    ) public pure returns (string memory) {
        uint32 position = packXY(x, y);
        string memory name;

        if (position == 0) {
            name = "Ancestral Insight Eyepiece";
        } else if (position == 65536) {
            name = "Primitive Vision Goggles";
        } else if (position == 131072) {
            name = "Luminous Earthbound Visor";
        } else if (position == 196608) {
            name = "Organic Barrier Face Shield";
        } else if (position == 262144) {
            name = "Nature's Whisper Mouthguard";
        } else if (position == 1) {
            name = "Neon Infiltrator Glasses";
        } else if (position == 65537) {
            name = "Covert Protector Mask";
        } else if (position == 131073) {
            name = "High-Tech Recon Goggles";
        } else if (position == 196609) {
            name = "Cipher Lens Eyewear";
        } else if (position == 262145) {
            name = "Datastream Vision Glasses";
        } else if (position == 2) {
            name = "Sacred Rune Amulet";
        } else if (position == 65538) {
            name = "Gem-Infused Divination Eye";
        } else if (position == 131074) {
            name = "Mystical Power Headband";
        } else if (position == 196610) {
            name = "Spirit Earring";
        } else if (position == 262146) {
            name = "Enchanted Vision Eyewear";
        } else if (position == 3) {
            name = "Encryption Mask";
        } else if (position == 65539) {
            name = "Partial Anonymity Face Guard";
        } else if (position == 131075) {
            name = "Digital Cloak Uplink Device";
        } else if (position == 196611) {
            name = "Full-Spectrum Security Mask";
        } else if (position == 262147) {
            name = "Hacked Identity Barrier";
        } else if (position == 4) {
            name = "Biomech Vision Enhancer";
        } else if (position == 65540) {
            name = "Synaptic Interface Goggles";
        } else if (position == 131076) {
            name = "Cyber-Organic Optics";
        } else if (position == 196612) {
            name = "Integrated Identity Faceplate";
        } else if (position == 262148) {
            name = "Human-Tech Fusion Eyewear";
        } else if (position == 5) {
            name = "Unbound Vision Goggles";
        } else if (position == 65541) {
            name = "Illuminated Isolation Mask";
        } else if (position == 131077) {
            name = "Rogue Optics Eyepiece";
        } else if (position == 196613) {
            name = "Autonomous Sight Enhancer";
        } else if (position == 262149) {
            name = "Independent Perception Goggles";
        }

        return name;
    }

    string description;

    function packXY(uint16 x, uint16 y) public pure returns (uint32) {
        return (uint32(x) << 16) | uint32(y);
    }

    // Extract x and y values from a uint32
    function unpackXY(uint32 packed) public pure returns (uint16 x, uint16 y) {
        x = uint16(packed >> 16);
        y = uint16(packed);
    }

    function getDescription() public view returns (string memory) {
        return
            bytes(description).length == 0
                ? "Synthia is a unique, AI-powered storytelling and gaming NFT project featuring customizable virtual avatars as ERC721 NFTs on the Ethereum blockchain. Set in a post-apocalyptic world, users can explore various factions, interact directly with Synthia and the factions through an immersive terminal experience, and participate in games. The on-chain, CC0 licensed art fuels a new creator economy, offering endless possibilities for the Synthia universe."
                : description;
    }

    function updateDescription(string memory _desc) public onlyOwner {
        description = _desc;
    }
}