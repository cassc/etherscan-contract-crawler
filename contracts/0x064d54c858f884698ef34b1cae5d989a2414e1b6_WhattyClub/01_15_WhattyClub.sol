// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./WithdrawFairly.sol";

contract WhattyClub is ERC721, Ownable, WithdrawFairly {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;
    Counters.Counter private _burnedTracker;

    uint256 public constant MAX_ELEMENTS = 10000;
    uint256 public constant RESERVE_NFT = 50;
    uint256 public constant PRICE = 0.06 ether;
    uint256 public constant WHITELIST_MINT_MAX = 10;
    uint256 public constant PRESALE_MINT_MAX = 10;
    uint256 public constant PUBLICSALE_MINT_MAX = 5;
    uint256 public constant START_AT = 1;

    uint256 private constant HASH_SIGN_WHITELIST = 745112421052;
    uint256 private constant HASH_SIGN_PRESALE = 23157425452;

    uint256 public whitelistSalesStart = 1635022800; // 2021-10-23 at 21:00:00 UTC
    uint256 public preSalesStart = 1635109200; // 2021-10-24 at 21:00:00 UTC
    uint256 public publicSalesStart = 1635195600; // 2021-10-25 at 21:00:00 UTC

    string public baseTokenURI;
    bool public emergencyPause = false;

    mapping(address => uint256) private balanceWhitelist;
    mapping(address => uint256) private balancePresales;
    mapping(uint256 => bool) private signatureIds;

    event EventWhitelistSaleStartChange(uint256 _date);
    event EventPreSaleStartChange(uint256 _date);
    event EventPublicSaleStartChange(uint256 _date);
    event EventMint(uint256 _totalSupply);

    constructor(string memory baseURI) ERC721("WhattyClub", "WHATTY") WithdrawFairly() {
        setBaseURI(baseURI);
    }

    //******************************************************//
    //                     Modifier                         //
    //******************************************************//
    modifier whitelistIsOpen {
        require(totalMinted() <= MAX_ELEMENTS, "Sold out!");
        if (_msgSender() != owner()) {
            require(whitelistSalesIsOpen(), "Whitelist Sales not open");
            require(!emergencyPause, "It's an emergency!..");
        }
        _;
    }
    modifier preIsOpen {
        require(totalMinted() <= MAX_ELEMENTS, "Sold out!");
        if (_msgSender() != owner()) {
            require(preSalesIsOpen(), "PreSales not open");
            require(!emergencyPause, "It's an emergency!..");
        }
        _;
    }
    modifier publicIsOpen {
        require(totalMinted() <= MAX_ELEMENTS, "Sold out!");
        if (_msgSender() != owner()) {
            require(publicSalesIsOpen(), "PublicSales not open");
            require(!emergencyPause, "It's an emergency!..");
        }
        _;
    }

    //******************************************************//
    //                      Mint                            //
    //******************************************************//
    function whitelistSalesMint(uint256 _count, uint256 _max, bytes memory _signature) public payable whitelistIsOpen{

        address wallet = _msgSender();
        uint256 total = totalMinted();

        require(_count <= WHITELIST_MINT_MAX && _count <= _max, "Exceeds number");
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(msg.value >= price(_count), "Value below price");

        require(balanceWhitelist[wallet] + _count <= _max, "Max minted");
        require(whitelistSalesSignature(wallet,_count,_max,_signature) == owner(), "Not allowed to mint");

        balanceWhitelist[wallet] += _count;

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(wallet);
        }

        emit EventMint(totalMinted());
    }
    function whitelistSalesSignature(address _wallet, uint256 _count, uint256 _max, bytes memory _signature) public pure returns(address){
        return ECDSA.recover(keccak256(abi.encode(_wallet, _count, _max, HASH_SIGN_WHITELIST)), _signature);
    }
    function getBalanceWhitelist(address wallet) public view returns(uint256){
        return balanceWhitelist[wallet];
    }

    function preSalesMint(uint256 _count, uint256 _signatureId, bytes memory _signature) public payable preIsOpen{

        address wallet = _msgSender();
        uint256 total = totalMinted();

        require(_count <= PRESALE_MINT_MAX, "Exceeds number");
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(msg.value >= price(_count), "Value below price");

        require(balancePresales[wallet] + _count <= PRESALE_MINT_MAX, "Max minted");
        require(signatureIds[_signatureId] == false, "Signature already used");
        require(preSalesSignature(wallet,_count,_signatureId,_signature) == owner(), "Not allowed to mint");

        signatureIds[_signatureId] = true;
        balancePresales[wallet] += _count;

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(wallet);
        }

        emit EventMint(totalMinted());
    }
    function preSalesSignature(address _wallet, uint256 _count, uint256 _signatureId, bytes memory _signature) public pure returns(address){
        return ECDSA.recover(keccak256(abi.encode(_wallet, _count, _signatureId, HASH_SIGN_PRESALE)), _signature);
    }
    function signatureIdUsed(uint256 _signatureId) public view returns(bool){
        return signatureIds[_signatureId];
    }
    function getBalancePresales(address wallet) public view returns(uint256){
        return balancePresales[wallet];
    }

    function publicSalesMint(uint256 _count) public payable publicIsOpen {

        address wallet = _msgSender();
        uint256 total = totalMinted();

        require(_count <= PUBLICSALE_MINT_MAX, "Exceeds number");
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(msg.value >= price(_count), "Value below price");

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(wallet);
        }

        emit EventMint(totalMinted());
    }

    function _mintAnElement(address _to) private{
        uint256 token = totalMinted() + START_AT;
        _tokenIdTracker.increment();
        _safeMint(_to, token);
    }

    //******************************************************//
    //                      Base                            //
    //******************************************************//
    function totalSupply() public view returns (uint256) {
        return _tokenIdTracker.current() - _burnedTracker.current();
    }
    function totalMinted() public view returns (uint256) {
        return _tokenIdTracker.current();
    }
    function price(uint256 _count) public pure returns (uint256) {
        return PRICE.mul(_count);
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }
    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256 key = 0;
        uint256[] memory tokensId = new uint256[](tokenCount);

        for (uint256 i = START_AT; i <= totalMinted(); i++) {
            if(rawOwnerOf(i) == _owner){
                tokensId[key] = i;
                key++;

                if(key == tokenCount){
                    break;
                }
            }
        }
        return tokensId;
    }
    function reserve(uint256 _count) public onlyOwner {
        uint256 total = totalMinted();
        require(total + _count <= RESERVE_NFT, "Exceeded");

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_msgSender());
        }
    }

    //******************************************************//
    //                      States                          //
    //******************************************************//
    function whitelistSalesIsOpen() public view returns (bool){
        return block.timestamp >= whitelistSalesStart && block.timestamp < preSalesStart;
    }
    function preSalesIsOpen() public view returns (bool){
        return block.timestamp >= preSalesStart && block.timestamp < publicSalesStart;
    }
    function publicSalesIsOpen() public view returns (bool){
        return block.timestamp >= publicSalesStart;
    }

    //******************************************************//
    //                      Setters                         //
    //******************************************************//
    function setWhitelistSalesStart(uint256 _start) public onlyOwner {
        whitelistSalesStart = _start;
        emit EventWhitelistSaleStartChange(whitelistSalesStart);
    }
    function setPreSalesStart(uint256 _start) public onlyOwner {
        preSalesStart = _start;
        emit EventPreSaleStartChange(preSalesStart);
    }
    function setPublicSalesStart(uint256 _start) public onlyOwner {
        publicSalesStart = _start;
        emit EventPublicSaleStartChange(publicSalesStart);
    }
    function dontPressThisButton(bool _pause) public onlyOwner {
        emergencyPause = _pause;
    }

    //******************************************************//
    //                      Burn                            //
    //******************************************************//
    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not owner nor approved");
        _burnedTracker.increment();
        _burn(tokenId);
    }

}