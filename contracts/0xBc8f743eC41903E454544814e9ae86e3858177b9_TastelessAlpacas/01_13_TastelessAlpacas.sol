// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract TastelessAlpacas is ERC721Enumerable, Ownable {

    string _baseTokenURI;
    uint256 private _price = 0.03 ether;
    bool private _puased = true;

    uint256 constant private MAX_TOTAL_SUPPLY = 10000;
    // withdraw addresses
    address constant private t1 = 0x87f1b7793B06Df360e57D87087B58E681a506931;
    address constant private t2 = 0x1947374DBD7Dd0225896a4885A6FB29a1005cd56;

    constructor(string memory baseURI) ERC721("Tasteless Alpacas", "TLSAlpaca")  {
        setBaseURI(baseURI);
    }

    function adopt(uint256 num, bool needWithdraw) public payable {
        uint256 supply = totalSupply();
        require( !_puased, "The contract has been paused by owner" );
        require( num <= 20, "You can adopt a maximum of 20 Alpakas" );
        require( supply + num <= MAX_TOTAL_SUPPLY, "Exceeds maximum Alpakas supply" );
        require( msg.value >= _price * num, "Ether sent is not correct" );

        for(uint256 i; i < num; i++) {
            _safeMint(msg.sender, supply + i);
        }

        if (needWithdraw) {
            withdrawAllInternal();
        }
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        _price = _newPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function getPrice() public view returns (uint256){
        return _price;
    }

    function giveAway(
        address to,
        uint256 amount
    ) external onlyOwner {
        uint256 supply = totalSupply();

        require( supply + amount <= MAX_TOTAL_SUPPLY, "Exceeds maximum Alpakas supply" );

        for(uint256 i; i < amount; i++) {
            _safeMint(to, supply + i);
        }
    }

    function setIsPaused(bool isPaused) public onlyOwner {
        _puased = isPaused;
    }

    function getIsPaused() public view returns(bool) {
        return _puased;
    }

    function withdrawAllInternal() private {
        uint256 balance = address(this).balance;
        uint256 firstPart = balance * 80 / 100;
        require(payable(t1).send(firstPart));
        require(payable(t2).send(balance - firstPart));
    }

    function withdrawAll() public payable onlyOwner {
        withdrawAllInternal();
    }
}