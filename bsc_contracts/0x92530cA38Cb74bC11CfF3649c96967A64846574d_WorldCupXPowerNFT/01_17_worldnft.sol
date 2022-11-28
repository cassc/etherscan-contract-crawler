// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract WorldCupXPowerNFT is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Burnable,
    AccessControl
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    string public uriPrefix =
        "ipfs://QmTcKSoqxm6yVnVxZKqQCBkthe76HShaiS7hwEhqMasf5o/";
    string public uriSuffix = ".json";
    uint256 public cost = 0.1 ether;

    address payable public marketWallet =
        payable(0x8338C3841F3302AcF3D29F1813CF7be2E08e4CD3);

    constructor() ERC721("WORLDCUPXPOWER NFT", "WCXP") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier mintPriceCompliance() {
        require(msg.value >= cost, "Insufficient funds!");
        _;
    }

    function safeMint(address to) public payable mintPriceCompliance {
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
        _tokenIdCounter.increment();
    }

    function updateCost(uint256 value) external onlyRole(DEFAULT_ADMIN_ROLE) {
        cost = value;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory currentBaseURI = _baseURI();
        uint256 actualToken = tokenId % 60;
        return string(abi.encodePacked(currentBaseURI, actualToken, uriSuffix));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function getNftPrice() external view returns (uint256) {
        return cost;
    }

    function withdraw() public payable onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool os, ) = payable(marketWallet).call{value: address(this).balance}(
            ""
        );
        require(os);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}