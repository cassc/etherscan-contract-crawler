// SPDX-License-Identifier: UNLICENSED

/*********************************
*                                *
*            (o.O)               *
*           (^^^^^)              *
*                                *
 *********************************/

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IMonstersDecoder.sol";
import "./ERC721Enumerable.sol";


contract Monsters is ERC721Enumerable, Ownable {
    event SeedUpdated(uint256 indexed tokenId, uint256 seed);

    mapping(uint256 => uint256) internal seeds;
    IMonstersDecoder public decoder;
    bool public minting = false;
    bool public canUpdateSeed = true;

    constructor() ERC721("Monsters club", "MCB") {
    }

    function mint(uint32 count) external payable {
        require(minting, "Minting needs to be enabled to start minting");
        require(count < 101, "Exceeds max per transaction.");
        uint256 nextTokenId = _owners.length;

        for (uint32 i; i < count;) {
            seeds[nextTokenId] = generateSeed(nextTokenId);
            _mint(_msgSender(), nextTokenId);
            unchecked {
                ++nextTokenId; i++;
            }
        }
    }

    function setMinting(bool value) external onlyOwner {
        minting = value;
    }

    function setDecoder(IMonstersDecoder newDecoder) external onlyOwner {
        decoder = newDecoder;
    }

    function withdraw() external payable onlyOwner {
        (bool os,)= payable(owner()).call{value: address(this).balance}("");
        require(os);
    } 
    
    function updateSeed(uint256 tokenId, uint256 seed) external onlyOwner {
        require(canUpdateSeed, "Cannot set the seed");
        seeds[tokenId] = seed;
        emit SeedUpdated(tokenId, seed);
    }

    function disableSeedUpdate() external onlyOwner {
        canUpdateSeed = false;
    }

    function getSeed(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Monster does not exist.");
        return seeds[tokenId];
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Monster does not exist.");
        uint256 seed = seeds[tokenId];
        return decoder.tokenURI(tokenId, seed);
    }

    function generateSeed(uint256 tokenId) private view returns (uint256) {
        uint256 r = random(tokenId);
        uint256 headSeed = 100 * (r % 20 + 10) + ((r >> 48) % 20 + 10);
        uint256 faceSeed = 100 * ((r >> 96) % 12 + 10) + ((r >> 96) % 20 + 10);
        uint256 mouthSeed = 100 * ((r >> 144) % 7 + 10) + ((r >> 144) % 20 + 10);
        uint256 neckSeed = 100 * ((r >> 172) % 8 + 10) + ((r >> 172) % 20 + 10);
        uint256 bodySeed = 100 * ((r >> 192) % 9 + 10) + ((r >> 192) % 20 + 10);
        uint256 legsSeed = 100 * ((r >> 236) % 4 + 10) + ((r >> 236) % 20 + 10);
        return 10000 * (10000 * ( 10000 * (10000 * (10000 * headSeed + faceSeed) + mouthSeed ) + neckSeed) + bodySeed) + legsSeed;
    }

    function random(uint256 tokenId) private view returns (uint256 pseudoRandomness) {
        pseudoRandomness = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), tokenId))
        );

        return pseudoRandomness;
    }
}