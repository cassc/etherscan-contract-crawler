// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";

contract NFT is Ownable, ERC721A, DefaultOperatorFilterer {
    string public uriPrefix = '';
    string public uriSuffix = '.json';
    uint256 public max_supply = 4_444;
    uint256 public burnAmount;

    uint256 public amountMintPerAccount = 2;
    bool public mintEnabled;
    uint256 public price = 0 ether;

    bool public revealed;

    event MintSuccessful(address user);

    constructor() ERC721A("Block Beggars", "BEG") {
        _mint(msg.sender, 222);
    }

    function mint(uint256 quantity) external payable {
        require(mintEnabled, 'Minting is not enabled');
        require(totalSupply() + quantity < max_supply, 'Cannot mint more than max supply');
        require(balanceOf(msg.sender) + quantity <= amountMintPerAccount, 'Each address may only mint x NFTs!');
        require(msg.value >= getPrice() * quantity, "Not enough ETH sent; check price!");

        _mint(msg.sender, quantity);

        emit MintSuccessful(msg.sender);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, Strings.toString(_tokenId), uriSuffix))
            : '';
    }

    function _baseURI() internal view override returns (string memory) {
        if (revealed) {
            return "ipfs://QmUyFRqyffoivMVtGVVsuS2Yc87x83GNqSr2PujcwFJksA/json/";
        }
        return "ipfs://QmYoHSexuY5rKipPYfF59mbnjj7B6K9jcJjm9qDgXEvAaE/";
    }
    
    function baseTokenURI() public view returns (string memory) {
        return _baseURI();
    }

    function contractURI() public pure returns (string memory) {
        return "ipfs://Qmb7zykUMw8PUD6xrnRfPg8nDKSDyFoChxEpMeWNFuPtU6/";
    }

    function setAmountMintPerAccount(uint _amountMintPerAccount) public onlyOwner {
        amountMintPerAccount = _amountMintPerAccount;
    }

    function setRevealed(bool _revealed) public onlyOwner {
        revealed = _revealed;
    }

    function getPrice() view public returns(uint) {
        return price;
    }

    function setPrice(uint _price) public onlyOwner {
        price = _price;
    }

    function setMintEnabled(bool _state) public onlyOwner {
        mintEnabled = _state;
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
    
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function _startTokenId() internal view override returns (uint256) {
        return 1;
    }
}