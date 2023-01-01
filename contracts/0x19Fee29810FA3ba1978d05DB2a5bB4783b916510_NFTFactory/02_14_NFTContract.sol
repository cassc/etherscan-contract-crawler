pragma solidity ^0.8.10;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


contract NFTContract is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    uint256 private _maxTokens;
    uint256 public _price;
    uint256 public _presalePrice;
    uint256 private _tax_rate;
    address private _tax_man;
    bool private _presaleActive = false;
    bool private _saleActive = false;

    address _verifyingAccount;

    string public _prefixURI;

    constructor(uint256 maxTokens, string memory assetName, string memory ticker, uint256 price,
                uint256 preSalePrice, address verifyingAccount, address new_owner, uint256 tax_rate, address tax_man) ERC721(assetName, ticker) 
    {
        _maxTokens = maxTokens;
        _price = price;
        _presalePrice = preSalePrice;
        _verifyingAccount = verifyingAccount;
        transferOwnership(new_owner);
        _tax_rate = tax_rate;
        _tax_man = tax_man;
    }


    //view functions
    function _baseURI() internal view override returns (string memory) {
        return _prefixURI;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function preSale() public view returns (bool) {
        return _presaleActive;
    }    

    function Sale() public view returns (bool) {
        return _saleActive;
    }

    function numSold() public view returns (uint256) {
        return _tokenIds.current();
    }

    function displayMax() public view returns (uint256) {
        return _maxTokens;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId));

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(tokenId),
                        ".json"
                    )
                )
                : "";
    } 



    //variable changing functions

    function changeMax(uint256 _newMax) public onlyOwner {
        _maxTokens = _newMax;
    }

    function togglePreSale() public onlyOwner {
        _presaleActive = !_presaleActive;
    }

    function toggleSale() public onlyOwner {
        _saleActive = !_saleActive;
        _presaleActive = false;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        _prefixURI = _uri;
    }

    function changeVerifyingAccount(address _newVerifier) public onlyOwner {
        _verifyingAccount = _newVerifier;
    }

    function changePrice(uint256 _newPrice) public onlyOwner {
        _price = _newPrice;
    }

    function changePresalePrice(uint256 _newPrice) public onlyOwner {
        _presalePrice = _newPrice;
    }


    //onlyOwner contract interactions

    function reserve(uint256 quantity) public onlyOwner {
        for (uint256 i = 0; i < quantity; i++) {
            _mintItem(msg.sender);
        }
    }

    function withdraw() external onlyOwner {
        uint tax = (address(this).balance * _tax_rate) / 100;
        payable(_tax_man).transfer(tax);
        payable(msg.sender).transfer(address(this).balance);    
    }

    //off-chain whitelist verification code
    using ECDSA for bytes32;

    function verifyAccountWithSignature(address message, bytes memory signedMessage, address signer) public pure returns (bool) {
        return keccak256(abi.encodePacked(message))
        .toEthSignedMessageHash()
        .recover(signedMessage) == signer;
    }

    function hashAddress(address _addr) public pure returns (bytes32){
        return(keccak256(abi.encodePacked(_addr)));
    }

    //minting functionality

    function presaleMintItems(uint256 amount, bytes memory signedMessage) public payable {
        require(_presaleActive);
        require(verifyAccountWithSignature(msg.sender, signedMessage, _verifyingAccount));

        uint256 totalMinted = _tokenIds.current();
        require(totalMinted + amount <= _maxTokens);

        require(msg.value >= amount * _presalePrice);

        for (uint256 i = 0; i < amount; i++) {
            _mintItem(msg.sender);
        }
    }

    function mintItems(uint256 amount) public payable {
        require(_saleActive);

        uint256 totalMinted = _tokenIds.current();
        require(totalMinted + amount <= _maxTokens);

        require(msg.value >= amount * _price);

        for (uint256 i = 0; i < amount; i++) {
            _mintItem(msg.sender);
        }
    }

    function _mintItem(address to) internal returns (uint256) {
        _tokenIds.increment();

        uint256 id = _tokenIds.current();
        _mint(to, id);

        return id;
    }


}