// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";

contract NFT is Ownable, ERC721A, DefaultOperatorFilterer {
    string public uriPrefix = '';
    string public uriSuffix = '.json';
    string public baseUri = "";
    string public unrevealedUri = 'ipfs://bafybeiddotjz44ucjp6zlklko2olxb3cgnqa4df6b7ontusahtiee6mjly/';
    uint256 public max_supply = 4_000;
    uint256 public amountMintPerAccount = 5;
    uint256 public amountMintPerAccountPrimeList = 10;
    uint256 public price = 0.025 ether;
    uint256 public pricePrimeList = 0.02375 ether;

    bytes32 public allowListRoot;
    bytes32 public primeListRoot;
    bool public publicSaleEnabled;
    bool public mintEnabled;
    bool public revealed;

    event MintSuccessful(address user, uint256 totalSupplyBeforeMint, uint256 _quantity);

    constructor(
        address _ownerAddress, 
        bytes32 _allowListRoot, 
        bytes32 _primeListRoot
    ) ERC721A ("Mystic Motors Olympus", "MYSTIC") {
        allowListRoot = _allowListRoot;
        primeListRoot = _primeListRoot;
        _transferOwnership(_ownerAddress);
    }

    function mint(uint256 _quantity, bytes32[] memory _proof) external payable {
        require(mintEnabled, 'Minting is not enabled');
        require(totalSupply() + _quantity <= max_supply, "Can't mint more than total supply");

        bool isAllowList = isValidAllowList(_proof, keccak256(abi.encodePacked(msg.sender)));
        bool isPrimeList = isValidPrimeList(_proof, keccak256(abi.encodePacked(msg.sender)));
        
        require(publicSaleEnabled || isAllowList || isPrimeList, 'You are not whitelisted');

        require(balanceOf(msg.sender) + _quantity <= amountMintPerAccount 
            || (isPrimeList && balanceOf(msg.sender) + _quantity <= amountMintPerAccountPrimeList), 'Each address may only mint x NFTs!');
        
        require(msg.value >= price * _quantity
            || (isPrimeList && msg.value >= pricePrimeList * _quantity), "Not enough ETH sent; check price!");

        _mint(msg.sender, _quantity);
        
        emit MintSuccessful(msg.sender, totalSupply(), _quantity);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory currentBaseURI = _baseURI();
        if (!revealed) {
            currentBaseURI = unrevealedUri;
        }

        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, Strings.toString(_tokenId), uriSuffix))
            : '';
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }
    
    function baseTokenURI() public view returns (string memory) {
        return _baseURI();
    }

    function setAmountMintPerAccount(uint _amountMintPerAccount) public onlyOwner {
        amountMintPerAccount = _amountMintPerAccount;
    }

    function setPublicSaleEnabled(bool _state) public onlyOwner {
        publicSaleEnabled = _state;
    }

    function setAllowListRoot(bytes32 _allowListRoot) public onlyOwner {
        allowListRoot = _allowListRoot;
    }

    function setPrimeListRoot(bytes32 _primeListRoot) public onlyOwner {
        primeListRoot = _primeListRoot;
    }

    function isValidAllowList(bytes32[] memory _proof, bytes32 _leaf) public view returns (bool) {
        return MerkleProof.verify(_proof, allowListRoot, _leaf);
    }

    function isValidPrimeList(bytes32[] memory _proof, bytes32 _leaf) public view returns (bool) {
        return MerkleProof.verify(_proof, primeListRoot, _leaf);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setMintEnabled(bool _state) public onlyOwner {
        mintEnabled = _state;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setPricePrimeList(uint256 _price) public onlyOwner {
        pricePrimeList = _price;
    }

    function setBaseUri(string memory _uri) public onlyOwner {
        baseUri = _uri;
    }

    function setUnrevealedUri(string memory _uri) public onlyOwner {
        unrevealedUri = _uri;
    }
    
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function airdrop(address _user, uint256 _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= max_supply, "Can't mint more than total supply");
        _mint(_user, _quantity);
    }
    
    function _startTokenId() internal view override returns (uint256) {
        return 501;
    }

    function setMaxSupply(uint _max_supply) public onlyOwner {
        max_supply = _max_supply;
    }
}