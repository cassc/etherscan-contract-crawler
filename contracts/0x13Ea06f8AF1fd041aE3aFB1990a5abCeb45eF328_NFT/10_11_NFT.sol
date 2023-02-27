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
    uint256 public max_supply = 500;
    uint256 public amountMintPerAccount = 8;

    uint256 public price = 0.02 ether;

    bytes32 public whitelistRoot;
    bool public publicSaleEnabled;
    bool public mintEnabled;

    event MintSuccessful(address user, uint256 totalSupplyBeforeMint, uint256 _quantity);

    constructor(
        address _ownerAddress, 
        bytes32 _whitelistRoot, 
        address[] memory _minterAddresses,
        uint256[] memory _tokenAmount
    ) ERC721A ("Mystic Motors", "MYSTIC") {
        whitelistRoot = _whitelistRoot;
        _transferOwnership(_ownerAddress);
        
        uint256 _minterAddressesLength = _minterAddresses.length;
        uint256 _tokenAmountLength = _tokenAmount.length;
        require(_minterAddressesLength == _tokenAmountLength, "Minter Addresses and Token Amount arrays need to have the same size.");

        for (uint256 i = 0; i < _minterAddressesLength;) {
            _mint(_minterAddresses[i], _tokenAmount[i]);
            unchecked { ++i; }
        }
    }

    function mint(uint256 _quantity, bytes32[] memory _proof) external payable {
        require(mintEnabled, 'Minting is not enabled');
        require(balanceOf(msg.sender) < amountMintPerAccount, 'Each address may only mint x NFTs!');
        require(totalSupply() + _quantity <= max_supply, "Can't mint more than total supply");
        require(publicSaleEnabled || isValid(_proof, keccak256(abi.encodePacked(msg.sender))), 'You are not whitelisted');
        require(msg.value >= price * _quantity, "Not enough ETH sent; check price!");

        _mint(msg.sender, _quantity);
        
        emit MintSuccessful(msg.sender, totalSupply(), _quantity);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, Strings.toString(_tokenId), uriSuffix))
            : '';
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://bafybeiahekcekq7zqnft2wcbknbk6ysfms6dj57uskiltgbva4cfidemcq/";
    }
    
    function baseTokenURI() public pure returns (string memory) {
        return _baseURI();
    }

    function contractURI() public pure returns (string memory) {
        return "ipfs://bafkreigr3t4hrqmmd67m5ih5ieio7fit4xm3ph5eopq4o23z3o5jmzisee/";
    }

    function setAmountMintPerAccount(uint _amountMintPerAccount) public onlyOwner {
        amountMintPerAccount = _amountMintPerAccount;
    }

    function setPublicSaleEnabled(bool _state) public onlyOwner {
        publicSaleEnabled = _state;
    }

    function setWhitelistRoot(bytes32 _whitelistRoot) public onlyOwner {
        whitelistRoot = _whitelistRoot;
    }

    function isValid(bytes32[] memory _proof, bytes32 _leaf) public view returns (bool) {
        return MerkleProof.verify(_proof, whitelistRoot, _leaf);
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
    
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function airdrop(address _user, uint256 _quantity) external onlyOwner {
        _mint(_user, _quantity);
    }
    
    function _startTokenId() internal view override returns (uint256) {
        return 1;
    }
}