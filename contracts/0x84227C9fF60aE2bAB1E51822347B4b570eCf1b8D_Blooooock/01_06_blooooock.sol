// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Blooooock is Ownable, ERC721A, ReentrancyGuard {
    uint256 public constant MAX_SUPPLY = 2022;
    string public uriPrefix = "ipfs://bafybeicm6qwwvzcagvpoqwzupvproebbqfu5efzjyo6o6whrytcnb2dbby/";
    string public uriSuffix = ".json";

    constructor() ERC721A("Blooooock", "BLOC") {}

    function mint() external {
        require(_numberMinted(msg.sender) == 0, "Only ONE per wallet");
        require(totalSupply() + 1 <= MAX_SUPPLY, "Reached max supply");
        _mint(msg.sender, 1);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _toString(_tokenId),uriSuffix)) : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function setUriPrefix(string calldata _uriPrefix) external onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string calldata _uriSuffix) external onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}