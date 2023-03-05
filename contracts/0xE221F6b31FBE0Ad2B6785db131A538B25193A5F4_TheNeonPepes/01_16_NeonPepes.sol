// SPDX-License-Identifier: MIT

/*********************************
*                                *
*              0,0               *
*                                *
 *********************************/

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./lib/ERC721Enumerable.sol";
import "./IPepeDescriptor.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";


contract TheNeonPepes is ERC721Enumerable, Ownable, OperatorFilterer {
    event SeedUpdated(uint256 indexed tokenId, uint256 seed);

    mapping(uint256 => uint256) internal seeds;
    IPepeDescriptor public descriptor;
    uint256 public maxSupply = 10000;
    bool public minting = false;
    bool public canUpdateSeed = true;

    uint256 token_price = 0.002 ether;

    uint256 free_per_txn = 2;

    constructor() ERC721("The Neon Pepes", "NPepeO") {

    }

    function mint(uint32 count) external payable {
        require(minting, "Minting needs to be enabled to start minting");
        require(count < 101, "Exceeds max per transaction.");
        uint256 nextTokenId = _owners.length;
        unchecked {
            require(nextTokenId + count < maxSupply, "Exceeds max supply.");
        }

        require(msg.value >= token_price * (count - free_per_txn), "Two Freement. Need to send more ETH.");


        for (uint32 i; i < count;) {
            seeds[nextTokenId] = generateSeed(nextTokenId);
            _mint(_msgSender(), nextTokenId);
            unchecked { ++nextTokenId; ++i; }
        }
    }

    function teamClaim(uint32 count) external payable {
        require(minting, "Minting needs to be enabled to start minting");
        require(count < 101, "Exceeds max per transaction.");
        uint256 nextTokenId = _owners.length;
        unchecked {
            require(nextTokenId + count < maxSupply, "Exceeds max supply.");
        }

        for (uint32 i; i < count;) {
            seeds[nextTokenId] = generateSeed(nextTokenId);
            _mint(_msgSender(), nextTokenId);
            unchecked { ++nextTokenId; ++i; }
        }
    }    

    function setMinting(bool value) external onlyOwner {
        minting = value;
    }

    function setDescriptor(IPepeDescriptor newDescriptor) external onlyOwner {
        descriptor = newDescriptor;
    }

    function withdraw() external payable onlyOwner {
        (bool os,)= payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function setTokenPrice(uint256 newPrice) external onlyOwner {
        require(newPrice >= 0, "Token price must be greater than zero");
        token_price = newPrice;
    }

    function setFreeNum(uint256 _num) external onlyOwner {
        require(_num >= 0, "Token price must be greater than zero");
        free_per_txn = _num;
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
        require(_exists(tokenId), "Pepe does not exist.");
        return seeds[tokenId];
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Pepe does not exist.");
        uint256 seed = seeds[tokenId];
        return descriptor.tokenURI(tokenId, seed);
    }

    function generateSeed(uint256 tokenId) private view returns (uint256) {
        uint256 r = random(tokenId);
        uint256 earSeed = 100 * (r % 6 + 10) + (r  % 20 + 10);
        uint256 eyeSeed = 100 * ((r >> 48) % 7 + 10) + ((r >> 48) % 20 + 10);
        uint256 faceSeed = 100 * ((r >> 96) % 6 + 10) + ((r >> 96) % 20 + 10);
        uint256 neckSeed = 100 * ((r >> 144) % 6 + 10) + ((r >> 144) % 20 + 10);
        uint256 bodySeed = 100 * ((r >> 192) % 7 + 10) + ((r >> 192) % 20 + 10);
        return 10000 * (10000 * (10000 * (10000 * earSeed + eyeSeed) + faceSeed) + neckSeed) + bodySeed;
    }

    function random(uint256 tokenId) private view returns (uint256 pseudoRandomness) {
        pseudoRandomness = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), tokenId))
        );

        return pseudoRandomness;
    }
}