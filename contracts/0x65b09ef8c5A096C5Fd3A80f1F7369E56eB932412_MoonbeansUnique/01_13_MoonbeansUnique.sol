pragma solidity ^0.8.14;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract MoonbeansUnique is ERC721Enumerable, Ownable {

    mapping(uint256 => string) public uris;
    constructor() ERC721("MoonbeansUnique", "MB") {
        uris[0] = "ipfs://QmPuiLt4GTSs3fUSE7bWkSWjSxqTEGzm4oW9U3oXgmE6fK";
        _safeMint(msg.sender, 0);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return uris[tokenId];
    }

    function setBaseURI(string memory uri, uint256 tokenId) external onlyOwner {
        uris[tokenId] = uri;
    }

    function mint(string memory uri) external onlyOwner {
        uris[totalSupply()]= uri;
        _safeMint(msg.sender, totalSupply());
    }


    //EMERGENCY ONLY
    function withdrawAll() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawNFT(address _token, uint256 tokenId) external onlyOwner {
        IERC721(_token).transferFrom(address(this), owner(), tokenId);
    }
}