// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RedCandleHeros is ERC721, Ownable {
    string private _baseURIextended;
    uint public currentIndex = 0;
    bool public saleIsActive = false;

    constructor(string memory baseURI) ERC721("Red Candle Heros", "COOMER") {
        _baseURIextended = baseURI;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function totalSupply() view public returns (uint){
        return currentIndex;
    }

     function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function mint(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint")
        ;require(msg.sender == tx.origin, "Humans Only Coomer(<:")
        ;require(numberOfTokens <= 10, "Can only mint 10 tokens at a time")
        ;require(currentIndex + numberOfTokens <= 6968, "Purchase would exceed max supply")
        ;if(currentIndex + numberOfTokens > 1000){
            require(0.02 ether * numberOfTokens <= msg.value, "Ether value sent is not correct");
        }

        for(uint i = 0; i < numberOfTokens; i++) {
            if (currentIndex < 6968) {
                _safeMint(msg.sender, currentIndex + i);
            }
        }
        currentIndex += numberOfTokens;
    }

    // withdraw addresses
    address kingcoom = 0x4C6CA258F1e547855bE38DAb6106c9ACa1467A72;
    address lilcoom = 0xAEA65F632957A7dCC34288e3657C50465FAE8dc3;
    address bigcoom = 0xa9A512F969c471264da75f8440857198242cF3F8;
    address sercoom = 0x3075ca518509f1568F83708620BeDB447C970585;
    address mrcoom = 0xe898F53C00E13f5bd231cC160E889F4697cf921D;

    function withdraw() public onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function withdrawAll() public payable onlyOwner {
        uint256 _kingcoom = address(this).balance * 81/100;
        uint256 _lilcoom = address(this).balance * 10/100;
        uint256 _bigcoom = address(this).balance * 3/100;
        uint256 _sercoom = address(this).balance * 3/100;
        uint256 _mrcoom = address(this).balance * 3/100;
        require(payable(kingcoom).send(_kingcoom));
        require(payable(lilcoom).send(_lilcoom));
        require(payable(bigcoom).send(_bigcoom));
        require(payable(sercoom).send(_sercoom));
        require(payable(mrcoom).send(_mrcoom));
    }
}