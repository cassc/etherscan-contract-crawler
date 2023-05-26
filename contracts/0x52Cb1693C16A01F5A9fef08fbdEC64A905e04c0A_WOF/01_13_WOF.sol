// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WOF is ERC721A, Ownable {
    event Mint(address sender, uint256 count);
    event SetBaseURI(string baseURI);

    string public _baseTokenURI;
    uint256 public constant START_TOKEN_ID = 1;
    uint256 public constant MAX_SUPPLY = 2000;

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
        emit SetBaseURI(baseURI);
    }

    // Deploy and Mint
    constructor(
        string memory baseTokenURI_
    ) ERC721A("OneCool Collective: Run Cool", "WOF") {
        _baseTokenURI = baseTokenURI_;
    }

    function airdrop(address[] calldata receivers) external onlyOwner {
        uint256 count = receivers.length;
        require(
            totalSupply() + count <= MAX_SUPPLY,
            "Exceeds maximum supply of tokens"
        );
        for (uint256 i = 0; i < count; i++) {
            _mint(receivers[i], 1);
        }
    }

    // For Opensea catching Metadata
    function baseTokenURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // For skipping Token ID 0
    function _startTokenId() internal view virtual override returns (uint256) {
        return START_TOKEN_ID;
    }
}