// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//    ___                      _       _      _  _                    __ _
//   / __|    __     __ _     | |     | |    | || | __ __ __ __ _    / _` |   ___
//   \__ \   / _|   / _` |    | |     | |     \_, | \ V  V // _` |   \__, |  (_-<
//   |___/   \__|_  \__,_|   _|_|_   _|_|_   _|__/   \_/\_/ \__,_|   |___/   /__/_
// _|"""""|_|"""""|_|"""""|_|"""""|_|"""""|_| """"|_|"""""|_|"""""|_|"""""|_|"""""|
// "`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'

contract Scallywags is ERC721Enumerable, Ownable {
    uint256 public MAX_PER_TRANSACTION = 20;
    uint256 public constant PRICE = 0.0299 ether;
    uint256 public constant MAX_SUPPLY = 11000;
    bool public saleIsOpen = false;
    string public baseURI;

    address a1 = 0xD2Bf76BA687109FbEafE59307EFcdaAB77177425;
    address a2 = 0x8C3CFA102945ADE120ad2de561c4EDd1047630D5;

    event SaleStateChanged(bool status);
    event Mint(address adopter, uint256 amount);

    constructor() ERC721("Scallywags", "SCALLYWAG") {}

    function mint(uint256 amount) public payable {
        require(saleIsOpen, "SALE_CLOSED");
        require(totalSupply() + amount <= MAX_SUPPLY, "EXCEEDS_MAX_SUPPLY");
        require(amount <= MAX_PER_TRANSACTION, "EXCEEDED_MAX_PER_TRANSACTION");
        require(PRICE * amount <= msg.value, "INSUFFICIENT_ETH");

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }

        emit Mint(msg.sender, amount);
    }

    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function flipSaleState() public onlyOwner {
        saleIsOpen = !saleIsOpen;
        emit SaleStateChanged(saleIsOpen);
    }

    function setMaxPerTransaction(uint256 amount) public onlyOwner {
        MAX_PER_TRANSACTION = amount;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(a1).transfer((balance * 50) / 100);
        payable(a2).transfer((balance * 50) / 100);
    }
}