// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';


//gaper x cam

contract ChiptoPunks is ERC721Enumerable, Ownable {


    string _baseTokenURI;
    uint256 public maxChips;
    uint256 private chipPrice = 0.2 ether;
    uint256 public saleStartTimestamp = 1629500400;

    address ga = 0xF354d776288EfF3A9B860945c2066936FD5a79e1;
    address ct = 0x26dB774e3c5ed9d8930E89AaDd598cb6E498d369;

    constructor() ERC721("ChiptoPunks", "CHIP")  {
        maxChips = 512;
    }


    function mintChip(uint256 chipQuantity) public payable {
        uint256 supply = totalSupply();
        require( block.timestamp >= saleStartTimestamp, "Not time yet");
        require( chipQuantity < 4, "3 Max" );
        require( supply + chipQuantity <= maxChips, "Exceeds maximum supply" );
        require( msg.value >= chipPrice * chipQuantity,"TX Value not correct" );

        for(uint256 i; i < chipQuantity; i++){
            _safeMint( msg.sender, supply + i );
        }
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setTime(uint256 newTime) public onlyOwner {
        saleStartTimestamp = newTime;
    }

    function reserveChips() public onlyOwner {        
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < 8; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

        function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance / 2;
        require(payable(ga).send(balance));
        require(payable(ct).send(balance));
    }
}