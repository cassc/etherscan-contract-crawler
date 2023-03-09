// SPDX-License-Identifier: MIT

/*********************************
*                                *
*              (oo)              *
*                                *
 *********************************/

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./IOinkDescriptor.sol";

contract Oinks is ERC721Enumerable, ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    event SeedUpdated(uint256 indexed tokenId, uint256 seed);

    mapping(uint256 => uint256) internal seeds;
    IOinkDescriptor public descriptor;
    uint256 public maxSupply = 10000;
    uint256 public price = 5000000000000000;
    bool public minting = false;
    bool public canUpdateSeed = true;

    constructor(IOinkDescriptor newDescriptor) ERC721("Oink", "OINK") {
        descriptor = newDescriptor;
    }

    function mint(uint32 count) external nonReentrant payable {
        require(minting, "Minting needs to be enabled to start minting");
        require(count < 101, "Exceeds max per transaction.");
        require(
            msg.value >= price.mul(count),
            "Insufficient funds."
        );
        
        unchecked {
            require(totalSupply() + count <= maxSupply, "Exceeds max supply.");
        }
        
        uint256 nextTokenId = totalSupply()+1;
        for (uint32 i; i < count;) {
            seeds[nextTokenId] = generateSeed(nextTokenId);
            _mint(_msgSender(), nextTokenId);
            unchecked { ++nextTokenId; ++i; }
        }
    }

    function setMinting(bool value) external onlyOwner {
        minting = value;
    }

    function setDescriptor(IOinkDescriptor newDescriptor) external onlyOwner {
        descriptor = newDescriptor;
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

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved to burn.");
        delete seeds[tokenId];
        _burn(tokenId);
    }

    function getSeed(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Oink does not exist.");
        return seeds[tokenId];
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(tokenId > 0 && tokenId <= totalSupply(), "tokenId not exist.");
        uint256 seed = seeds[tokenId];
        return descriptor.tokenURI(tokenId, seed);
    }

    function generateSeed(uint256 tokenId) private view returns (uint256) {
        uint256 r = random(tokenId);
        uint256 headSeed = 100 * (r % 11 + 10) + ((r >> 48) % 20 + 10);
        uint256 faceSeed = 100 * ((r >> 96) % 18 + 10) + ((r >> 96) % 20 + 10);
        uint256 bodySeed = 100 * ((r >> 144) % 15 + 10) + ((r >> 144) % 20 + 10);
        return 10000 * (10000 * (10000 * headSeed + faceSeed) + bodySeed);
    }

    function random(uint256 tokenId) private view returns (uint256 pseudoRandomness) {
        pseudoRandomness = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), tokenId))
        );

        return pseudoRandomness;
    }
}