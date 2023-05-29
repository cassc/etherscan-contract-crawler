/*

         ,MMM8&&&.
    _...MMMMM88&&&&..._
 .::'''MMMMM88&&&&&&'''::.
::    ..SPACE..LOOT..    ::
'::....MMMMM88&&&&&&....::'
   `''''MMMMM88&&&&''''`
         'MMM8&&&'


*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Base64.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract SpaceLoot is ERC721, ReentrancyGuard, Ownable {

        uint internal _totalSupply = 0;

        using Counters for Counters.Counter;
        Counters.Counter private _tokenIds;

        string[] private weapons = [
        "Particle-beam Shotgun",
        "Laser Rifle",
        "Photon Cannon",
        "Plasma Rifle",
        "Rocket Launcher",
        "Nuclear Desintegrator",
        "Frag Grenade",
        "Plasma Pistol",
        "Flare Gun",
        "Plasma Grenade",
        "Pulse Garbine",
        "Energy Net",
        "Ravager",
        "Chain Gun",
        "Combat Knife",
        "Flamer",
        "Quantum Rifle",
        "Laser Pistol",
        "Pulse Minigun",
        "Epic Lightsaber",
        "Hyperblaster",
        "Lightning Gun",
        "Vibroblade"
    ];
    
    string[] private chestArmor = [
        "Elite Space Suit",
        "Marauder Suit",
        "Recon Armor",
        "Sharpshooter Suit",
        "Engineering Suit",
        "Flight Suit",
        "Legionary Suit",
        "Exoskeleton",
        "Stealth Suit",
        "Space Y Suit",
        "Durasteel Corset",
        "Chromium Jacket",
        "Tactical Bra",
        "Plasmaproof Crystal Armor",
        "Experimental Polyester Suit",
        "Adaptive Gold-plated Suit",
        "Power Armor"

    ];
    
    string[] private helmets = [
        "Marauder Helmet",
        "Pilot Helmet",
        "Warrior Helmet",
        "Legionary Helmet",
        "Recon Helmet",
        "Scout Helmet",
        "Neutronium Helmet",
        "Operator Helmet",
        "Recruit Helmet",
        "Defender Helmet",
        "Enforcer Helmet",
        "Tactical Helmet",
        "Engineer Helmet",
        "Airassault Helmet",
        "Annihilating Helmet",
        "Crystocrene Helmet",
        "Space Y Helmet"
    ];
    
    string[] private implants = [
        "X-ray Eye",
        "Cyborg Arm",
        "Cyborg Leg",
        "Night-vision Eye",
        "Scientist Chip",
        "Tactical Chip",
        "Memory Implant",
        "Steel Skull",
        "Regenerative Skin",
        "Stamina Implant",
        "Neutronium Arm",
        "Toxin Neutralizer Chip",
        "Anti-radiation Chip"
    ];
    
    string[] private boots = [
        "Antigravity Boots",
        "Combat Boots",
        "Orbital Boots",
        "Camouflage Boots",
        "Space Y Boots",
        "Amplifying Lead Boots",
        "Defending Nitinol Sandals",
        "Radioactive Chrome Boots",
        "Psionic Bronze Boots",
        "Rigid-foam Long boot",
        "Molecular Wax Boots",
        "Reflective Uranium Boots",
        "Titanium Foam Boots",
        "Quantum Nitinol Boots",
        "Reactive Uranium Boots",
        "Atomic Titanium Sandals",
        "Nanocellulose Boots",
        "Pilot Boots",
        "Scout Boots"
    ];
    
    string[] private gloves = [
        "Metal Gloves",
        "Carbon Gloves",
        "Magnetic Gloves",
        "Brass Knuckles",
        "Ultralight Gloves",
        "Plasma Gloves",
        "Tactical Gloves",
        "Amplifying Duralumin Gloves",
        "Entropic Unobtanium Gloves",
        "Biosteel Gloves",
        "Psionic Copper Gloves",
        "Absorbing Silicon Gloves",
        "Reflective Neutronium Gloves",
        "Biopolymer Gloves",
        "Inhibiting Invar Gloves"
    ];
    
    string[] private gadgets = [
        "Teleport Bracelet",
        "Night-vision Goggles",
        "Holographic Watch",
        "Universal Translator",
        "Jet Pack",
        "Regeneration Field Ring",
        "Scout Drone",
        "Jump Pack",
        "Hardlight Shield Generator",
        "Trap Mine",
        "Radar Jammer",
        "Deployable Cover",
        "Invincibility Bracelet",
        "Portable Gravity Lift",
        "Time Manipulation Device",
        "Energy Renderer",
        "Deep Gamma Scanner",
        "Anti-gravity Generator"
    ];
    
    string[] private artifacts = [
        "Asteroid Ring",
        "Plasma Ball",
        "Energy Ball",
        "Time Capsule",
        "Tetris",
        "Black Hole Loop",
        "DH643 Planet Sand",
        "Encapsulated Stardust",
        "Teleporting Key",
        "Mankrostin Skull",
        "Memory Diamond",
        "Vitalik Cube",
        "Hypnofrog",
        "Giant Screw",
        "Cassette Player",
        "Blue Crystal ",
        "Old Bottle",
        "Invisible Cube"
    ];
    
    string[] private suffixes = [
        "of Rebels",
        "of Jedis",
        "of Skill",
        "of Force",
        "of Camouflage",
        "of the Emperor",
        "of Control",
        "of Invincibility",
        "of Invulnerability",
        "of Energy",
        "of Power",
        "of Fury",
        "of Protection",
        "of Rage",
        "of Perfection",
        "of Artificial Intelligence",
        "of Faultlessness",
        "of Clones",
        "of Mutants",
        "of Aliens",
        "of Solar"
    ];
    
    string[] private namePrefixes = [
        "Armageddon", "Force", "Galactic", "Universe", "Light", "Death", "Metagalactic", "Time", 
        "Fear", "Star", "Metaverse", "Convergence", "Black hole", "Hyper space", "Parallel world", "Post-Human", 
        "Space", "Singularity", "Biopunk", "Multiverse", "Metaverse", "Space", "Sun", "Planet", "Gravity", "Plasma", "Proton", 
        "Neutron", "Nuclear", "Photon", "Anti", "Neo"  
    ];
    
    string[] private nameSuffixes = [
        "Glow",
        "Whisper",
        "Bite",
        "Scent",
        "Crusher",
        "Annihilator",
        "Song",
        "Peak",
        "Enforcer",
        "Shadow",
        "Wind",
        "Bender",
        "Protector",
        "Defender",
        "Emperor",
        "Enlightener",
        "Liberator ",
        "Creator"
    ];
    
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function getWeapon(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "!Token");
        return pluck(tokenId, "WEAP0N", weapons);
    }
    
    function getChest(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "!Token");
        return pluck(tokenId, "CHEST ARMOR", chestArmor);
    }
    
    function getHead(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "!Token");
        return pluck(tokenId, "HELMET", helmets);
    }
    
    function getImplant(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "!Token");
        return pluck(tokenId, "IMPLANT", implants);
    }

    function getFoot(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "!Token");
        return pluck(tokenId, "BOOTS", boots);
    }
    
    function getHand(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "!Token");
        return pluck(tokenId, "GLOVES", gloves);
    }
    
    function getGadget(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "!Token");
        return pluck(tokenId, "GADGETS", gadgets);
    }
    
    function getArtifact(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "!Token");
        return pluck(tokenId, "ARTIFACTS", artifacts);
    }
    
    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        string memory output = sourceArray[rand % sourceArray.length];
        uint256 greatness = rand % 21;
        if (greatness > 14) {
            output = string(abi.encodePacked(output, " ", suffixes[rand % suffixes.length]));
        }
        if (greatness >= 19) {
            string[2] memory name;
            name[0] = namePrefixes[rand % namePrefixes.length];
            name[1] = nameSuffixes[rand % nameSuffixes.length];
            if (greatness == 19) {
                output = string(abi.encodePacked('`', name[0], ' ', name[1], '` ', output));
            } else {
                output = string(abi.encodePacked('`', name[0], ' ', name[1], '`', output, ' v7'));
            }
        }
        return output;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[17] memory parts;
        
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"> <rect width="100%" height="100%" fill="black" /> <style>.white { fill: white; font-family: monospace; font-size: 8px; }</style> <style>.green { fill: #23ff00; font-family: monospace; font-size: 8px; }</style> <style>.base { fill: #ffffff; font-family: monospace; font-size: 10px; }</style> <text x="160" y="20" class="white">,MMM8&amp;&amp;&amp;.</text> <text x="135" y="30" class="white">_...MMMMM88&amp;&amp;&amp;&amp;..._ </text> <text x="120" y="40" class="white"> .::```MMMMM88&amp;&amp;&amp;&amp;&amp;&amp;```::. </text> <text x="118" y="50" class="white">::</text> <text x="145" y="50" class="green">..SPACE..LOOT..  </text>  <text x="235" y="50" class="white">::</text> <text x="115" y="60" class="white">`::....MMMMM88&amp;&amp;&amp;&amp;&amp;&amp;....::`</text> <text x="135" y="70" class="white"> ````MMMMM88&amp;&amp;&amp;&amp;````</text> <text x="160" y="80" class="white">`MMM8&amp;&amp;&amp;`</text> <text x="90" y="30" class="white">*</text> <text x="250" y="80" class="white">*</text> <text x="10" y="140" class="base">';

        parts[1] = getWeapon(tokenId);

        parts[2] = '</text><text x="10" y="160" class="base">';

        parts[3] = getChest(tokenId);

        parts[4] = '</text><text x="10" y="180" class="base">';

        parts[5] = getHead(tokenId);

        parts[6] = '</text><text x="10" y="200" class="base">';

        parts[7] = getImplant(tokenId);

        parts[8] = '</text><text x="10" y="220" class="base">';

        parts[9] = getFoot(tokenId);

        parts[10] = '</text><text x="10" y="240" class="base">';

        parts[11] = getHand(tokenId);

        parts[12] = '</text><text x="10" y="260" class="base">';

        parts[13] = getGadget(tokenId);

        parts[14] = '</text><text x="10" y="280" class="base">';

        parts[15] = getArtifact(tokenId);

        parts[16] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));
        
        string memory json = string(abi.encodePacked('{"name": "SpaceCase #', toString(tokenId), '", "description": "SpaceLoot is randomized space gear generated and stored on chain. Fill your oxygen tanks! Intergalactic adventure begins!", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '",'));
        string memory json_attr =  Base64.encode(bytes(string(abi.encodePacked(json, '"attributes":[{"trait_type": "Weapon", "value": "',getWeapon(tokenId), '"},{"trait_type": "Chest Armor", "value": "', getChest(tokenId), '"},{"trait_type": "Helmet", "value": "' ,getHead(tokenId)  , '"},{"trait_type": "Implant", "value": "', getImplant(tokenId), '"},{"trait_type": "Boots", "value": "', getFoot(tokenId) , '"},{"trait_type": "Gloves", "value": "' , getHand(tokenId) , '"},{"trait_type": "Gadget", "value": "' , getGadget(tokenId) , '"},{"trait_type": "Artifact", "value": "' , getArtifact(tokenId) , '"}]}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json_attr));

        return output;
    }

    function claim() public nonReentrant {
        require(totalSupply() + 1 <= 8000, "MaxSupply");
        _tokenIds.increment(); 
        uint256 newItemId = _tokenIds.current();
        _safeMint(_msgSender(), newItemId);
        _totalSupply++;
    }
    
    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] memory ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalNFTs = totalSupply();
            uint256 resultIndex = 0;

            uint256 NFTId;

            for (NFTId = 1; NFTId <= totalNFTs; NFTId++) {
                if (ownerOf(NFTId) == _owner) {
                    result[resultIndex] = NFTId;
                    resultIndex++;
                }
            }
            return result;
        }
    }

    // Get total Supply
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    } 

    // Check if token exists
    function existsPubl(uint _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    } 
    
    constructor() ERC721("SpaceLoot", "SLOOT") Ownable() {}
}

/* 

function turnCalendarOver() public pure returns (string memory) {
    return "3rd of Sept";
}

c|:{|) 

*/