// SPDX-License-Identifier: MIT
// Written by Hans Hergen Lehmann

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";


contract SturmhaubeNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint16 public constant maxSupply = 365;

    string public baseURI = "https://hammerhead-app-pz6vc.ondigitalocean.app/sturmhaubenft-api/nft/";

    constructor() ERC721("Sturmhaube", "STURMHAUBE") {}

    function mint(address to, uint256 tokenId) external onlyOwner {
        require(totalSupply() < maxSupply, "SturmhaubeNFT: Max supply reached");
        require(tokenId < maxSupply, "SturmhaubeNFT: Token ID invalid");
        _safeMint(to, tokenId);
    }

    function getUnmintedIds() external view returns (uint256[] memory) {
        uint256[] memory available = new uint256[](maxSupply - totalSupply());
        uint256 counter = 0;
        for (uint256 i = 0; i < maxSupply; i++) {
            if (!_exists(i)) {
                available[counter] = i;
                counter++;
            }
        }
        return available;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newbaseURI) external onlyOwner {
        baseURI = newbaseURI;
    }
}