// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// 1. PokemonNFT Contract

contract PokemonNFT is ERC721Enumerable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Mapping from Token ID to Pokemon name
    mapping(uint256 => string) private _pokemonNames;

    constructor() ERC721("PokemonNFT", "PMNFT") {}

    function mint(address to, string memory pokemonName) external returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(to, newTokenId);
        _pokemonNames[newTokenId] = pokemonName;
        return newTokenId;
    }

    function pokemonNameOf(uint256 tokenId) external view returns (string memory) {
        return _pokemonNames[tokenId];
    }
}

// 2. PokemonDistributor Contract

contract PokemonDistributor {
    PokemonNFT public pokemonNFT;
    mapping(uint8 => string) private _pokemonByIndex;

    constructor(address _pokemonNFTAddress) {
        pokemonNFT = PokemonNFT(_pokemonNFTAddress);
        
        _pokemonByIndex[0] = "Alakazam";
        _pokemonByIndex[1] = "Blastoise";
        _pokemonByIndex[2] = "Charizard";
        _pokemonByIndex[3] = "Dragonite";
        _pokemonByIndex[4] = "Eevee";
        _pokemonByIndex[5] = "Fearow";
        _pokemonByIndex[6] = "Gyarados";
        _pokemonByIndex[7] = "Hypno";
        _pokemonByIndex[8] = "Ivysaur";
        _pokemonByIndex[9] = "Jolteon";
        _pokemonByIndex[10] = "Kabutops";
        _pokemonByIndex[11] = "Lapras";
        _pokemonByIndex[12] = "Mewtwo";
        _pokemonByIndex[13] = "Nidoking";
        _pokemonByIndex[14] = "Onix";
        _pokemonByIndex[15] = "Pikachu";
        _pokemonByIndex[16] = "Quagsire"; 
        _pokemonByIndex[17] = "Rapidash";
        _pokemonByIndex[18] = "Snorlax";
        _pokemonByIndex[19] = "Togepi";
        _pokemonByIndex[20] = "Umbreon";   
        _pokemonByIndex[21] = "Venusaur";
        _pokemonByIndex[22] = "Wartortle";
        _pokemonByIndex[23] = "Xatu";      
        _pokemonByIndex[24] = "Yanma"; 
        _pokemonByIndex[25] = "Zapdos";


    }

    function claimPokemon() external {
        uint8 firstTwoDigits = uint8(uint160(address(msg.sender)) % 100);
        uint8 index = uint8(firstTwoDigits % 26);
        
        require(bytes(_pokemonByIndex[index]).length > 0, "No Pokemon for this index.");

        pokemonNFT.mint(msg.sender, _pokemonByIndex[index]);
    }
}