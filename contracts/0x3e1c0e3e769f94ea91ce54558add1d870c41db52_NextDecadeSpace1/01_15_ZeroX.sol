// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NextDecadeSpace1 is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    address private bank = 0x74CaD1e8e7a81215857ce194540dA21d29Ae22a2;
    bool public hasSaleStarted = false;
    uint public supply = 500;
    uint public price = 0.1 ether;
    string private baseURI = 'https://nfts.buns.land/ndzx/';

    constructor() ERC721("Next Decade Space 1", "NDS1") {}

    function safeMint(uint nb) public payable {
        require(hasSaleStarted, "Mint has not started.");
        require(msg.value == price * nb, "Not enough ETH sent; check price!");
        require(supplyLeft() - nb >= 0, "Quantity not available.");
        require(nb > 0 && nb < 6, "Invalid nb to mint.");

        for (uint i = 0; i < nb; i++) {
            _tokenIdCounter.increment();
            _safeMint(msg.sender, _tokenIdCounter.current());
        }
    }

    function gift(address to, uint nb) public onlyOwner {
        require(supplyLeft() - nb >= 0, "Quantity not available.");

        for (uint i = 0; i < nb; i++) {
            _tokenIdCounter.increment();
            _safeMint(to, _tokenIdCounter.current());
        }
    }

    function startSale() public onlyOwner {
        hasSaleStarted = true;
    }

    function stopSale() public onlyOwner {
        hasSaleStarted = false;
    }

    function withdraw() public onlyOwner {
        uint256 _balance = address(this).balance;

        require(payable(bank).send(_balance));
    }

    function supplyLeft() public view returns(uint) {
        return supply - _tokenIdCounter.current();
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newURI) public onlyOwner {
        baseURI = newURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}