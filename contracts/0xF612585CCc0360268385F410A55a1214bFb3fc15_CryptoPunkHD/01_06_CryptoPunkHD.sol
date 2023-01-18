// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CryptoPunkHD is ERC721A, Ownable, ReentrancyGuard {
    uint256 public constant MAX_SUPPLY = 10000;
    string public uriPrefix = "ipfs://bafybeidkvbnrz7axn4xxet4pw552bhku4slkoe2rgdio77g2jqicfpghqa/";
    string public uriSuffix = ".json";

    constructor() ERC721A("CryptoPunkHD", "PKHD") {}

    function mint() external {
        require(_numberMinted(msg.sender) == 0, "Only ONE per wallet");
        require(totalSupply() + 1 <= MAX_SUPPLY, "Reached max supply");
        _mint(msg.sender, 1);
    }

    function mintForAddress(uint256 _mintAmount, address _receiver) external onlyOwner {
        require(totalSupply() + _mintAmount <= MAX_SUPPLY, "Reached max supply");
        _safeMint(_receiver, _mintAmount);
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