//SPDX-License-Identifier: MIT
/*
                                
         (                      
   )     )\              (      
  /(( ((((_)(   `  )    ))\ (   
 (_))\ )\ _ )\  /(/(   /((_))\  
 _)((_)(_)_\(_)((_)_\ (_)) ((_) 
 \ V /  / _ \  | '_ \)/ -_)|_ / 
  \_/  /_/ \_\ | .__/ \___|/__| 
               |_|              
*/
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Vapez is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private tokenIdCounter;

    string baseURI;
    string public baseExtension = ".json";
    string public preRevealURI;
    uint256 public currentPrice = 0.03 ether;
    uint256 public totalVapez = 3000;
    uint256 public maxFreeVapez = 200;
    bool public paused = true;
    bool public revealed = false;

    constructor(string memory _initBaseURI, string memory _preRevealURI)
        ERC721("vApez", "VAPEZ")
    {
        setBaseURI(_initBaseURI);
        setPreRevealURI(_preRevealURI);
        //mintVapez(msg.sender, 20);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    //free vApez
    function freeVape(uint256 mintAmount) public {
        uint256 supply = tokenIdCounter.current();
        require(!paused, "Sale paused");
        require(supply + mintAmount < maxFreeVapez, "No more free vApez left");
        mintVapez(msg.sender, mintAmount);
    }

    //public mint function
    function blazeVape(uint256 mintAmount) external payable {
        uint256 supply = tokenIdCounter.current();
        require(!paused, "Sale paused");
        require(mintAmount < 9, "You can only give vapes to 8 Apes");
        require(
            supply + mintAmount < totalVapez + 1,
            "Exceeds maximum vApez supply"
        );
        require(
            msg.value >= currentPrice * mintAmount,
            "Not enough Ether sent"
        );

        mintVapez(msg.sender, mintAmount);
    }

    function mintVapez(address addr, uint256 mintAmount) private {
        for (uint256 i = 0; i < mintAmount; i++) {
            tokenIdCounter.increment();
            _safeMint(addr, tokenIdCounter.current());
        }
    }

    //returns number of vApez minted
    function getCurrentId() external view returns (uint256) {
        return tokenIdCounter.current();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return preRevealURI;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    //----------------Owner functions--------------------
    function pause(bool val) public onlyOwner {
        paused = val;
    }

    //one way change, cannot be reverted
    function reveal() public onlyOwner {
        revealed = true;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setPreRevealURI(string memory _newPreRevealURI) public onlyOwner {
        preRevealURI = _newPreRevealURI;
    }

    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failed to send Ether");
    }
}