// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

import './ImmortalzInterface.sol';
import './ImmortalzMetadataInterface.sol';

contract Immortalz is ERC721Enumerable, Ownable, ImmortalzInterface, ImmortalzMetadataInterface {
    using Strings for uint256;

    uint256 public constant IMMORTALZ_RESERVE = 150;
    uint256 public constant IMMORTALZ_MAX = 4_375;
    uint256 public constant IMMORTALZ_MAX_MINT = IMMORTALZ_RESERVE + IMMORTALZ_MAX;
    uint256 public constant PURCHASE_LIMIT = 10;
    uint256 public constant PRICE = 0.07 ether;
    uint256 public constant ATTR_PRICE = 0.01 ether;

    string private _contractURI = '';
    string private _tokenBaseURI = '';

    event AttributeChanged(uint256 indexed _tokenId, string _key, string _value);

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    function changeAttribute(uint256 tokenId, string memory key, string memory value) public payable {
        address owner = ERC721.ownerOf(tokenId);
        require(_msgSender() == owner, "This is not your Nft.");

        uint256 amountPaid = msg.value;
        require(amountPaid == ATTR_PRICE, "There is a price for changing your attributes.");

        emit AttributeChanged(tokenId, key, value);
    }

    function airdropMint(address _to, uint256 _tokenId) external onlyOwner {
        require(totalSupply() < IMMORTALZ_MAX_MINT, 'All tokens have been minted');

        _safeMint(_to, _tokenId);
    }

    function withdraw() external override onlyOwner {
        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance);
    }

    function setContractURI(string calldata URI) external override onlyOwner {
        _contractURI = URI;
    }

    function setBaseURI(string calldata URI) external override onlyOwner {
        _tokenBaseURI = URI;
    }

    function contractURI() public view override returns (string memory) {
        return _contractURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), 'Token id does not exist');

        return string(abi.encodePacked(_tokenBaseURI, tokenId.toString()));
    }
}