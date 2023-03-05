// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./IApeDescriptor.sol";

contract Apes is ERC721Enumerable, Ownable {
    event SeedUpdated(uint256 indexed tokenId, uint256 seed);

    mapping(uint256 => uint256) internal seeds;
    IApeDescriptor public descriptor;
    uint256 public maxSupply = 9999;
    bool public minting = false;
    bool public canUpdateSeed = true;
    uint256 public price = 0.003 ether;
    mapping(address => uint256) internal _walletMintedCount;

    constructor(IApeDescriptor newDescriptor) ERC721("ApesWTF", "AWTF") {
        descriptor = newDescriptor;
    }

    function mintedCount(address owner) external view returns (uint256) {
        return _walletMintedCount[owner];
    }

    function vaultApes(uint32 count) external onlyOwner {
        uint256 nextTokenId = totalSupply();
        require(count > 0, "Must mint at least one ape.");
        unchecked {
            require(nextTokenId + count <= maxSupply, "Exceeds max supply.");
        }

        for (uint32 i; i < count;) {
            seeds[nextTokenId] = generateSeed(nextTokenId);
            _mint(_msgSender(), nextTokenId);
            unchecked { ++nextTokenId; ++i; }
        }
    }

    function mint(uint32 count) external payable {
        require(minting, "Minting needs to be enabled to start minting");
        require(count <= 20, "Exceeds max per transaction.");
        require(count > 0, "Must mint at least one ape.");

        // 1 FREE per wallet
        uint256 payForCount = count;
        if (_walletMintedCount[msg.sender] == 0) {
            payForCount -= 1;
        }
        require(msg.value >= price * payForCount, "Ether value insufficient.");

        uint256 nextTokenId = totalSupply();
        unchecked {
            require(nextTokenId + count < maxSupply, "Exceeds max supply.");
        }

        for (uint32 i; i < count;) {
            seeds[nextTokenId] = generateSeed(nextTokenId);
            _mint(_msgSender(), nextTokenId);
            unchecked { ++nextTokenId; ++i; }
        }
        _walletMintedCount[msg.sender] += count;
    }

    function setMinting(bool value) external onlyOwner {
        minting = value;
    }

    function setSupply(uint256 _supply) external onlyOwner {
        maxSupply = _supply;
    }

    function setDescriptor(IApeDescriptor newDescriptor) external onlyOwner {
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
        require(_exists(tokenId), "Ape does not exist.");
        return seeds[tokenId];
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Ape does not exist.");
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