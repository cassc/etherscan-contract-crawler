// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract NFT is ERC721A, Ownable {
    uint128 immutable MAX_SUPPLY = 999;
    uint256 immutable PRICE = 0.002 ether;
    uint8 immutable PER_TX = 5;
    string URI = "";
    bool public SALE_STATE = false;

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    constructor() ERC721A("ST4MPZNFT", "ST4") {
        _startTokenId();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return URI;
    }

    function setURI(string memory NewURI) public onlyOwner {
        URI = NewURI;
    }

    function toggleSale() public onlyOwner {
        SALE_STATE = !SALE_STATE;
    }

     function OwnerMint(uint8 quantity) public onlyOwner {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Exceeds Max Supply."); 
        require(quantity <= PER_TX, "Exceeds per tx"); 
        _mint(msg.sender, quantity);
    }

    function Mint(uint8 quantity) external payable {
        require(SALE_STATE, "Sale is not active");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Exceeds Max Supply.");
        require(quantity <= PER_TX, "Exceeds per tx");
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
        );
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                       _toString(_tokenId),
                        ".json"
                    )
                )
                : "";
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}