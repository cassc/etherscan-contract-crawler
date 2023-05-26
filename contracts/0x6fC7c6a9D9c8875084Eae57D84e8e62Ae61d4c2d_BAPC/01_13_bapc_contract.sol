/*
██████╗  █████╗ ██████╗  ██████╗
██╔══██╗██╔══██╗██╔══██╗██╔════╝
██████╔╝███████║██████╔╝██║
██╔══██╗██╔══██║██╔═══╝ ██║
██████╔╝██║  ██║██║     ╚██████╗
╚═════╝ ╚═╝  ╚═╝╚═╝      ╚═════╝
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract BAPC is ERC721Enumerable, Ownable {


    string _baseTokenURI;
    string _notRevealedURI;
    uint256 public maxApes;
    uint256 public nftPerAddressLimit;
    uint256 private apePrice = 0.00 ether;
    bool public saleIsActive = false;
    bool public revealed = false;


    constructor() ERC721("Bored Ape Pixel Club", "BAPC")  {
        maxApes = 5000;
    }


    function mintApe(uint256 apeQuantity) public payable {
        uint256 supply = totalSupply();
        require( saleIsActive,"Sale is paused" );

        if (msg.sender != owner()) {
            require(msg.value >= apePrice * apeQuantity, "TX Value not correct");
        }
        require( supply + apeQuantity <= maxApes, "Exceeds maximum supply" );
        require( msg.value >= apePrice * apeQuantity,"TX Value not correct" );

        for(uint256 i; i < apeQuantity; i++){
            _safeMint( msg.sender, supply + i );
        }
    }


    function setPrice(uint256 newApePrice) public onlyOwner() {
        apePrice = newApePrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        if(revealed == false) {
            return _notRevealedURI;
        }

        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }



    function setNotRevealedURI(string memory notRevealedURI) public onlyOwner {
      _notRevealedURI = notRevealedURI;
    }


    function reveal() public onlyOwner {
        revealed = true;
    }



 function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }


    function withdraw_all() public onlyOwner{
        uint balance = address(this).balance;
        require(payable(msg.sender).send(balance));
    }

}