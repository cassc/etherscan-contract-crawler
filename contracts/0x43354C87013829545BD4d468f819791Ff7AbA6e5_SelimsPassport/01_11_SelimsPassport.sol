// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SelimsPassport is ERC721, Ownable {
    using Strings for uint256;

    constructor() ERC721("Selims Passport", "SP") {}

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmT5LeXGwTGwvMSVW8ey6hTSQPmJASkVMgFzVLEw4L9AMr/";
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal view override {
        require(from == address(0) || msg.sender == owner(), "Soulbound");
    }
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);

        return _baseURI();
    }
}