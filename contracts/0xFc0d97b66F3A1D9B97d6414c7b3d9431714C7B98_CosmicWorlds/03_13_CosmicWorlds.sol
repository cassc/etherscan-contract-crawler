// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "./StringUtils.sol";
import "./WorldBuilder.sol";
import "hardhat/console.sol";
import "./ERC2981/ERC2981Royalties.sol";

contract CosmicWorlds is ERC721AQueryable, ERC2981Royalties {
    uint16 public constant TOKEN_LIMIT = 512;
    mapping(uint256 => uint24) private seedMapping;
    mapping(uint24 => bool) private usedSeeds;

    constructor() ERC721A("CosmicWorlds", "CWS") {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, IERC721A, ERC2981Royalties)
        returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function mint(uint24 _seed) public payable {
        require(_totalMinted() <= TOKEN_LIMIT, "TOKEN_LIMIT_HIT");
        require(usedSeeds[_seed] == false, "SEED_USED");

        uint256 tokenID = _nextTokenId();
        seedMapping[tokenID] = _seed;
        usedSeeds[_seed] = true;
        _mint(msg.sender, 1);
    }

    function mintMany(uint24[] memory seeds) external payable {
        require(_totalMinted() <= TOKEN_LIMIT, "TOKEN_LIMIT_HIT");

        // uint256 tokenID = _nextTokenId();
        // _mint(msg.sender, seeds.length);

        // for (uint i = 0; i < seeds.length; i++) {
        //     seedMapping[tokenID + i] = seeds[i];
        //     usedSeeds[seeds[i]] = true;
        // }

        uint validCount = 0;
        
        for (uint i = 0; i < seeds.length; i++) {
            if (usedSeeds[seeds[i]] == false) {
                validCount = validCount + 1;
            } else {
                delete seeds[i];
            }
            if (_totalMinted() + validCount >= TOKEN_LIMIT || validCount >= 10) {
                break;
            }
        }

        uint256 startTokenID = _nextTokenId();
        _mint(msg.sender, validCount);

        uint j = 0;
        while (validCount > 0) { 
            uint currentTokenID = startTokenID + j;
            if (seeds[j] != 0) {
                seedMapping[currentTokenID] = seeds[j];
                usedSeeds[seeds[j]] = true;
                validCount = validCount - 1;
            }
            j = j + 1;
        }
    }

    function tokenURI(uint256 _tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
        require(_exists(_tokenId), "BAD_ID");
    
        // TODO: Consider if base64 encoding is necessary.. which chain to use?
        // Base64 encode because OpenSea does not interpret data properly as plaintext served from Polygon
        return string(abi.encodePacked(
            'data:application/json,{"name":"CWS #',  StringUtils.uintToString(_tokenId), ': a stunning Cosmic World",'
                '"description": "https://cosmicworlds.xyz", ', 
                WorldBuilder.getTraits(seedMapping[_tokenId]), ', '
                '"image": "data:image/svg+xml,', 
                generateSvg(_tokenId), 
                '"}'
            )); 
    }

    function generateSvg(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId) && _tokenId < TOKEN_LIMIT, "BAD_ID");
        return WorldBuilder.build(seedMapping[_tokenId]);
    }    

// FOR OPENSEA
    function contractURI() public pure returns (string memory) {
        return "https://www.cosmicworlds.xyz/storefront-metadata";
    }

}