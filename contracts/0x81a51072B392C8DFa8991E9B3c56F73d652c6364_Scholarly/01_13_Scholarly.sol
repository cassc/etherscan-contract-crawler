// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Scholarly is ERC721, Ownable {
    using Strings for uint256;
    uint256 private maxSupply = 0;
    uint256 private mintCount = 0;
    string private baseURI_;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 _maxSupply
    ) ERC721(name_, symbol_) {
        maxSupply = _maxSupply;
    }

    function totalSupply() external view returns (uint256) {
        return mintCount;
    }

    /**
     * @dev Allow to set base URI
     * @param newBaseURI - IPFS pointing to the new base URI file
     *  - Verify that the caller is the owner
     */
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI_ = newBaseURI;
    }

    /**
     * @dev Return baseURI
     */
    function baseURI() public view returns (string memory) {
        return baseURI_;
    }

    function mint() external onlyOwner {
        require(mintCount < maxSupply, "Main: Max supply reached");
        _mint(msg.sender, mintCount);
        mintCount++;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(_exists(tokenId), "Main: URI query for nonexistent token");
        string memory baseURI__ = baseURI();
        return
            bytes(baseURI__).length != 0
                ? string(abi.encodePacked(baseURI__))
                : "";
    }
}