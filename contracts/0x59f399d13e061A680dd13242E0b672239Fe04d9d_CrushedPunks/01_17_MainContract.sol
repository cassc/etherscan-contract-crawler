// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer/DefaultOperatorFilterer.sol";


/*
*
*   ░█████╗░██████╗░██╗░░░██╗░██████╗██╗░░██╗███████╗██████╗░
*   ██╔══██╗██╔══██╗██║░░░██║██╔════╝██║░░██║██╔════╝██╔══██╗
*   ██║░░╚═╝██████╔╝██║░░░██║╚█████╗░███████║█████╗░░██║░░██║
*   ██║░░██╗██╔══██╗██║░░░██║░╚═══██╗██╔══██║██╔══╝░░██║░░██║
*   ╚█████╔╝██║░░██║╚██████╔╝██████╔╝██║░░██║███████╗██████╔╝
*   ░╚════╝░╚═╝░░╚═╝░╚═════╝░╚═════╝░╚═╝░░╚═╝╚══════╝╚═════╝░
*   ██████╗░██╗░░░██╗███╗░░██╗██╗░░██╗░██████╗
*   ██╔══██╗██║░░░██║████╗░██║██║░██╔╝██╔════╝
*   ██████╔╝██║░░░██║██╔██╗██║█████═╝░╚█████╗░
*   ██╔═══╝░██║░░░██║██║╚████║██╔═██╗░░╚═══██╗
*   ██║░░░░░╚██████╔╝██║░╚███║██║░╚██╗██████╔╝
*   ╚═╝░░░░░░╚═════╝░╚═╝░░╚══╝╚═╝░░╚═╝╚═════╝░
* 
*/


contract CrushedPunks is ERC721, ERC721URIStorage, DefaultOperatorFilterer, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    string baseURI;

    uint256 public constant PRICE = 0.00375 ether;

    uint256 public constant MAX_ELEMENTS = 10000;
    uint256 public constant MAX_PER_TRANSACTION = 20;
    uint256 public constant MAX_PER_WALLET = 20; 

    bool private IS_PAUSED = true;

    constructor(string memory baseTokenURI) ERC721("CrushedPunks", "CRSHDPNKS") {
        setBaseURI(baseTokenURI);
    }
    
    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    // DETECT IF SALE IS OPEN - BOOL RETURN
    modifier isSaleOpen {
        require(totalToken() < MAX_ELEMENTS, "Soldout!");
        require(!IS_PAUSED, "Sales not open");
        _;
    }

    // Get current amount of minted (= the current id)
    function totalToken() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function setPause(bool _pause) public onlyOwner{
        IS_PAUSED = _pause;
    }
    
    function totalPrice(uint256 _amount, uint256 _price) public pure returns (uint256) {
        return _price.mul(_amount);
    }
    
    // MINTING
    function mint(uint256 _amount) public payable isSaleOpen{
        address wallet = msg.sender;
        uint256 total = totalToken(); // get total token
        uint256 currentPrice = PRICE;
        uint256 maxPerTransation = MAX_PER_TRANSACTION;
        uint256 overAllLimit = MAX_ELEMENTS;
        uint256 currentBalance = balanceOf(wallet);
        uint256 amountToPay = currentBalance == 0 ? (_amount - 1) : _amount;
    
        require(_amount <= maxPerTransation, "Exceeds per transaction");
        require(total + _amount <= overAllLimit, "Global overlimit"); 
        require(currentBalance + _amount <= MAX_PER_WALLET, "Too many in wallet");
        require(msg.value >= totalPrice(amountToPay, currentPrice), "Value below price");


        for(uint8 i = 0; i < _amount; i++){
            safeMint(wallet);
        }
    }

    function safeMint(address to) private {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    // WITHDRAW
    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, 'Withdraw failed');
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return string(abi.encodePacked(super.tokenURI(tokenId),".json"));
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
}