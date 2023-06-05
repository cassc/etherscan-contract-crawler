// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract XDoodlesNFTV3 is ERC721A, Ownable {
    using Strings for uint256;
    string public baseTokenURI;

    // Constants
    uint256 public TOTAL_SUPPLY = 10000;
    uint256 public MINT_PRICE = 0.01 ether;
    uint256 public FREE_ITEMS_COUNT = 1100;
    string  public uriSuffix = "";

    constructor() ERC721A("XDoodlesNFTV3", "XDL3") {
        baseTokenURI = "https://api.mint0xDoodles.xyz/metadata/";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return
            string(abi.encodePacked(_baseURI(), (tokenId + 10000).toString(), uriSuffix));
    }

    function mintItem(uint256 quantity) external payable {
        uint256 supply = totalSupply();
        require((quantity > 0) && (quantity <= 10), "Invalid quantity.");
        require(supply + quantity - 1 <= TOTAL_SUPPLY, "Exceeds maximum supply");
        require(
            (supply + quantity - 1 <= FREE_ITEMS_COUNT) ||
                (msg.value >= MINT_PRICE * quantity),
            "Not enough supply."
        );
        _safeMint(msg.sender, quantity);
    }

    function claimByOwner(uint256 quantity) external payable onlyOwner {
        uint256 supply = totalSupply();
        require(supply + quantity - 1 <= TOTAL_SUPPLY, "Exceeds maximum supply");
        _safeMint(msg.sender, quantity);
    }

    function mintTo(address to,uint256 quantity) external payable onlyOwner{
        uint256 supply = totalSupply();
        require(supply + quantity - 1 <= TOTAL_SUPPLY, "Exceeds maximum supply");
        _safeMint(to, quantity);
    }

    function withdraw() external virtual onlyOwner {
        address payable ownerAddr = payable(owner());
        require(ownerAddr.send(address(this).balance));
    }

    function withdrawLegacy() external onlyOwner {
        address payable owner = payable(owner());
        owner.transfer(address(this).balance);
    }

    function withdrawLegacy(uint256 _amount) external onlyOwner {
        address payable owner = payable(owner());
        owner.transfer(_amount);
    }

    function withdrawLips() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function withdrawLips(uint256 _amount) external onlyOwner {
        (bool os, ) = payable(owner()).call{value: _amount}("");
        require(os);
    }

    function setCost(uint256 _newCost) public onlyOwner {
        MINT_PRICE = _newCost;
    }

    function setFreeCount(uint256 _count) public onlyOwner {
        FREE_ITEMS_COUNT = _count;
    }

    function setmaxMintAmount(uint256 _count) public onlyOwner {
        TOTAL_SUPPLY = _count;
    }
}