// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract JPMemoryBook is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    address collector;
    uint256 royaltyPercentage;

    event AirDropped(address from, address to, uint256 tokeId);

    constructor() ERC721("JPMemoryBook", "JPM") {}

    function setCollector(address newCollector) public onlyOwner {
        collector = newCollector;
    }

    function setRoyaltyPercentage(uint256 newRoyaltyPercentage) public onlyOwner {
        royaltyPercentage = newRoyaltyPercentage;
    }

    function getCollector() public view returns (address) {
        return collector;
    }

    function getRoyaltyPercentage() public view returns (uint256) {
        return royaltyPercentage;
    }

    function mint(uint256 count) public onlyOwner {
        for (uint256 i = 0; i < count; i++) {
            _safeMint(msg.sender, totalSupply());

            _tokenIdCounter.increment();
        }
    }

    function safeMint(string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();

        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        tokenURIMap[tokenId] = uri;
    }

    function airDrop(address receiver, uint256 tokenId) public onlyOwner {
        _airDropExisting(receiver, tokenId);
    }

    function airDrop(address receiver, string memory uri) public onlyOwner {
        _airDropNonExisting(receiver, uri);
    }

    function _airDropExisting(address _receiver, uint256 _tokenId) internal {
        require(_exists(_tokenId), "Token does not exist");
        safeTransferFrom(msg.sender, _receiver, _tokenId);

        emit AirDropped(msg.sender, _receiver, _tokenId);
    }

    function _airDropNonExisting(
        address _receiver,
        string memory _uri
    ) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_receiver, tokenId);
        tokenURIMap[tokenId] = _uri;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /** URI HANDLING **/

    string private customBaseURI;

    mapping(uint256 => string) private tokenURIMap;

    function getBaseURI() public view returns (string memory) {
        return customBaseURI;
    }

    function setTokenURI(
        uint256 tokenId,
        string memory tokenURI_
    ) external onlyOwner {
        tokenURIMap[tokenId] = tokenURI_;
    }

    function setBaseURI(string memory customBaseURI_) public onlyOwner {
        customBaseURI = customBaseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return customBaseURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        string memory tokenURI_ = tokenURIMap[tokenId];

        if (bytes(tokenURI_).length > 0) {
            return tokenURI_;
        }

        return string(abi.encodePacked(super.tokenURI(tokenId)));
    }


    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    /** ROYALTIES **/

    function royaltyInfo(
        uint256,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount) {
        return (collector, (salePrice * royaltyPercentage) / 10000);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721) returns (bool) {
        return (interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId));
    }
}