// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './HexamillenniaAlgorithm.sol';

contract Hexamillennia is ERC721Enumerable, Ownable {
    uint256 public constant MAX_SUPPLY = 1000;

    bool public active;
    mapping(uint256 => uint256) public randomSource;

    constructor() ERC721('Hexamillennia', 'HXMLLNN') {}

    function activate() external onlyOwner {
        active = true;
    }

    function mintTiling() external {
        require(active, 'Mint not active');
        uint256 tokenId = totalSupply();
        require(tokenId < MAX_SUPPLY, 'Max supply reached');
        randomSource[tokenId] = uint256(keccak256(abi.encodePacked(msg.sender, blockhash(block.number - 1), tokenId)));
        _mint(msg.sender, tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);
        return HexamillenniaAlgorithm.tokenURI(tokenId, randomSource[tokenId]);
    }

    function tokenSVG(uint256 tokenId) public view returns (string memory) {
        _requireMinted(tokenId);
        return HexamillenniaAlgorithm.tokenSVG(tokenId, randomSource[tokenId]);
    }
}