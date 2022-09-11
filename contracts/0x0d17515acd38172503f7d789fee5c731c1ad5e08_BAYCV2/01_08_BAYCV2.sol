// SPDX-License-Identifier: MIT
// twitter: 0x088
// web: boredapeyachtclubv2.com

pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BAYCV2 is ERC721A, IERC2981, Ownable {
    using Strings for uint256;

    string public baseURI = "ipfs://bafybeiaaq7vfgh5hw6dgwc3wayepooj5lzhhawa4huxyny6itcivyubs4i/";
    string public uriSuffix = ".json";
    uint256 public price = 4000000000000000; // 0.004

    uint256 public maxSupply = 10000;
    uint256 public royalty = 0;

    constructor() ERC721A("Bored Ape Yacht Club V2", "BAYCV2") Ownable() {}

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function mint(uint256 _quantity) external payable {
        require(0 < _quantity, "Wrong quantity");
        require(totalSupply() + _quantity <= maxSupply, "Sold out");
        require(price * _quantity <= msg.value, "Insufficient funds");

        _safeMint(_msgSender(), _quantity);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Nonexistent token");

        return string(abi.encodePacked(baseURI, _tokenId.toString(), uriSuffix));
    }

    function setRoyaly(uint256 _royalty) external onlyOwner {
        royalty = _royalty;
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(_tokenId), "Nonexistent token");
        return (owner(), (_salePrice * royalty) / 100);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC165)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
}