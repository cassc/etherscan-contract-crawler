// SPDX-License-Identifier: MIT

/*********************************
*                                *
*              PU,NK             *
*                                *
 *********************************/

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./lib/ERC721Enumerable.sol";
import "./lib/IPunkDescriptor.sol";

contract OnchainPunks is ERC721Enumerable, Ownable {
    event SeedUpdated(uint256 indexed tokenId, uint256 seed);

    mapping(uint256 => uint256) internal seeds;
    IPunkDescriptor public descriptor;
    uint256 public maxSupply = 3333;
    uint256 public cost = 0.001 ether;
    bool public minting = false;
    bool public canUpdateSeed = true;

    constructor(IPunkDescriptor newDescriptor) ERC721("OnchainPunks", "Punk") {
        descriptor = newDescriptor;
    }
    

    function mint(uint32 count) external payable {
        require(minting, "Minting needs to be enabled to start minting");
        require(count < 11, "Exceeds max per transaction.");
        uint256 nextTokenId = _owners.length;
        unchecked {
            require(nextTokenId + count < maxSupply, "Exceeds max supply.");
        }
            uint256 totalCost = count * cost;
    require(msg.value >= totalCost, "Insufficient funds.");

        for (uint32 i; i < count;) {
            seeds[nextTokenId] = generateSeed(nextTokenId);
            _mint(_msgSender(), nextTokenId);
            unchecked { ++nextTokenId; ++i; }
        }
    }

    function setMinting(bool value) external onlyOwner {
        minting = value;
    }

    function setDescriptor(IPunkDescriptor newDescriptor) external onlyOwner {
        descriptor = newDescriptor;
    }

    function setCost(uint256 newCost) external onlyOwner {
        cost = newCost;
    }
    
    function withdraw() public onlyOwner  {
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
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

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved to burn.");
        delete seeds[tokenId];
        _burn(tokenId);
    }

    function getSeed(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Punk does not exist.");
        return seeds[tokenId];
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Punk does not exist.");
        uint256 seed = seeds[tokenId];
        return descriptor.tokenURI(tokenId, seed);
    }

    function generateSeed(uint256 tokenId) private view returns (uint256) {
        uint256 r = random(tokenId);
        uint256 headSeed = 100 * (r % 7 + 10) + ((r >> 48) % 20 + 10);
        uint256 faceSeed = 100 * ((r >> 96) % 6 + 10) + ((r >> 96) % 20 + 10);
        uint256 bodySeed = 100 * ((r >> 144) % 7 + 10) + ((r >> 144) % 20 + 10);
        uint256 legsSeed = 100 * ((r >> 192) % 2 + 10) + ((r >> 192) % 20 + 10);
        return 10000 * (10000 * (10000 * headSeed + faceSeed) + bodySeed) + legsSeed;
    }

    function random(uint256 tokenId) private view returns (uint256 pseudoRandomness) {
        pseudoRandomness = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), tokenId))
        );

        return pseudoRandomness;
    }
}