// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ChildhoodDreams is ERC721A, Ownable {
    using Strings for uint256;

    uint16 public immutable MAX_SUPPLY = 888;
    uint16 public immutable MAX_PER_TX = 5;
    uint256 public PRICE = 0.002 ether;
    bool public IS_SALE_ACTIVE = false;
    string _URI = "https://gateway.pinata.cloud/ipfs/QmWvfcbyeMD3x16e6XFdMzoFKDL34Cw4xcaFP9MRshmbv1/";

    constructor(string memory Name, string memory Symbol)
        ERC721A(Name, Symbol)
    { 
        _mint(msg.sender, 1);
    }

    function toggleSale() public onlyOwner {
        IS_SALE_ACTIVE = !IS_SALE_ACTIVE;
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _URI;
    }

    function setURI(string memory URI) public onlyOwner {
        _URI = URI;
    } 

    function Mint(uint256 quantity) external payable {
        require(IS_SALE_ACTIVE, "Sale haven't started");
        require(quantity <= MAX_PER_TX, "Excedes max per tx");
        uint256 nextTokenId = _nextTokenId();
        require(nextTokenId + quantity <= MAX_SUPPLY, "Excedes max supply.");
        require(
            PRICE * quantity <= msg.value,
            "Ether value sent is not correct"
        );

        _mint(msg.sender, quantity);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        ); //
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }
}