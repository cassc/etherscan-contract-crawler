// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICheckDescriptor.sol";

contract Checkscii is ERC721Enumerable, Ownable {
    event SeedUpdated(uint256 indexed tokenId, string seed);

    mapping(uint256 => string) internal tokenIdToSchema;
    uint256 public maxSupply = 10000;
    uint256 public maxPerWallet = 25;
    mapping(address => uint256) public walletMints;
    bool public minting = false; 
    bool public canUpdateSeed = true;

    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address descriptorAddress = 0xbBe8d96e30038d08417eeF67Fecb6D29500a6169;
    ICheckDescriptor public descriptor = ICheckDescriptor(descriptorAddress);
    
    uint256 token_price = 0.005 ether;

    constructor() ERC721("Checkscii", "CSCII") {}

    function mint(uint32 count) external payable {
        require(minting, "Minting needs to be enabled to start minting");
        require(count <= 10, "Exceeds max per transaction.");
        uint256 nextTokenId = _tokenIds.current();
        unchecked {
            require(nextTokenId + count <= maxSupply, "Exceeds max supply.");
        }
        require(msg.value >= token_price * count, "Insufficient ETH.");
        require(walletMints[msg.sender] + count <= maxPerWallet, "Exceeds wallet quantity.");
        for (uint32 i = 0; i < count; i++) {
            nextTokenId = _tokenIds.current();
            tokenIdToSchema[nextTokenId] = generateSeed(nextTokenId);
            _mint(_msgSender(), nextTokenId);
            unchecked { _tokenIds.increment(); walletMints[msg.sender]++;}
        }
    }

    function setDescriptor(ICheckDescriptor newDescriptor) external onlyOwner {
        descriptor = newDescriptor;
    }

    function setMinting(bool value) external onlyOwner {
        minting = value;
    }

    function withdraw() external payable onlyOwner {
        (bool os,)= payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function updateSeed(uint256 tokenId, string memory seed) external onlyOwner {
        require(canUpdateSeed, "Cannot set the seed");
        tokenIdToSchema[tokenId] = seed;
        emit SeedUpdated(tokenId, seed);
    }

    function disableSeedUpdate() external onlyOwner {
        canUpdateSeed = false;
    }

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved to burn.");
        delete tokenIdToSchema[tokenId];
        _burn(tokenId);
    }

    function getSeed(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Checks does not exist.");
        return tokenIdToSchema[tokenId];
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Checks does not exist.");
        string memory seed = tokenIdToSchema[tokenId];
        return descriptor.tokenURI(tokenId.toString(), seed);
    }

    function generateSeed(uint256 tokenId) private view returns (string memory) {
        return random(tokenId);
    }

    function random(uint256 tokenId) private view returns (string memory) {
        return toHex(keccak256(abi.encodePacked(blockhash(block.number - 1), tokenId)));
    }

    function toHex16 (bytes16 data) internal pure returns (bytes32 result) {
        result = bytes32 (data) & 0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000 |
            (bytes32 (data) & 0x0000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000000000) >> 64;
        result = result & 0xFFFFFFFF000000000000000000000000FFFFFFFF000000000000000000000000 |
            (result & 0x00000000FFFFFFFF000000000000000000000000FFFFFFFF0000000000000000) >> 32;
        result = result & 0xFFFF000000000000FFFF000000000000FFFF000000000000FFFF000000000000 |
            (result & 0x0000FFFF000000000000FFFF000000000000FFFF000000000000FFFF00000000) >> 16;
        result = result & 0xFF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000 |
            (result & 0x00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000) >> 8;
        result = (result & 0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000) >> 4 |
            (result & 0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00) >> 8;
        result = bytes32 (0x3030303030303030303030303030303030303030303030303030303030303030 +
            uint256 (result) +
            (uint256 (result) + 0x0606060606060606060606060606060606060606060606060606060606060606 >> 4 &
            0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F) * 7);
    }

    function toHex (bytes32 data) private pure returns (string memory) {
        return string (abi.encodePacked ("0x", toHex16 (bytes16 (data)), toHex16 (bytes16 (data << 128))));
    }  
}