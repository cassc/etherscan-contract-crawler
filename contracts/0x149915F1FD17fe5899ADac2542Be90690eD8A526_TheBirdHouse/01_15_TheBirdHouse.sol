// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract TheBirdHouse is ERC721Enumerable, Ownable {
    /*
 _____ _          _____ _       _ _____                 
|_   _| |_ ___   | __  |_|___ _| |  |  |___ _ _ ___ ___ 
  | | |   | -_|  | __ -| |  _| . |     | . | | |_ -| -_|
  |_| |_|_|___|  |_____|_|_| |___|__|__|___|___|___|___|
  
*/

    //uint256's
    uint256 currentPrice = 60000000000000000;
    uint256 maxSupply = 6000;
    uint256 saleStartTime = 1628787600;

    //strings
    string currentContractURI = "https://metadata.thebirdhouse.app/contract";
    string baseURI = "https://metadata.thebirdhouse.app/bird/data/";

    //bools
    bool baseURIChangeable = true;

    //structs
    struct _token {
        uint256 tokenId;
        string tokenURI;
    }

    //Libraries
    using Strings for uint256;

    constructor() ERC721("TheBirdHouse", "TBH") {}

    //Write Functions

    //Functions for users

    function mintBirds(uint256 birdCount) public payable {
        uint256 supply = totalSupply();
        require(block.timestamp >= saleStartTime, "Sale has not started");
        require(birdCount < 11, "Can only mint max 10 birds!");
        require(
            supply + birdCount <= maxSupply,
            "Maximum birds already minted!"
        );
        require(msg.value >= (currentPrice * birdCount));

        for (uint256 i = 0; i < birdCount; i++) {
            _mint(msg.sender, supply + i);
        }

        return;
    }

    function ownerMintBirds(uint256 birdCount) public {
        require(msg.sender == owner(), "Only owner may mint free birds");
        uint256 supply = totalSupply();
        require(
            supply + birdCount <= maxSupply,
            "Maximum birds already minted!"
        );

        for (uint256 i = 0; i < birdCount; i++) {
            _mint(msg.sender, supply + i);
        }

        return;
    }

    //OWNER FUNCTIONS

    function withdraw() public {
        require(msg.sender == owner(), "Only owner can withdraw funds.");
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function changeContractURI(string memory newContractURI)
        public
        returns (string memory)
    {
        require(msg.sender == owner(), "Only owner can change contract URI.");
        currentContractURI = newContractURI;
        return (currentContractURI);
    }

    function changeSaleStartTime(uint256 newSaleStartTime)
        public
        returns (uint256)
    {
        require(
            msg.sender == owner(),
            "Only owner can change sale start time."
        );
        saleStartTime = newSaleStartTime;
        return (saleStartTime);
    }

    function changeCurrentPrice(uint256 newCurrentPrice)
        public
        returns (uint256)
    {
        require(msg.sender == owner(), "Only owner can change current price.");
        currentPrice = newCurrentPrice;
        return currentPrice;
    }

    function makeBaseURINotChangeable() public returns (bool) {
        require(
            msg.sender == owner(),
            "Only owner can make base URI not changeable."
        );
        baseURIChangeable = false;
        return baseURIChangeable;
    }

    function changeBaseURI(string memory newBaseURI)
        public
        returns (string memory)
    {
        require(msg.sender == owner(), "Only owner can change base URI");
        require(
            baseURIChangeable == true,
            "Base URI is currently not changeable"
        );
        baseURI = newBaseURI;
        return baseURI;
    }

    /*
        READ FUNCTIONS
    */

    function baseURICurrentlyChangeable() public view returns (bool) {
        return baseURIChangeable;
    }

    function getCurrentPrice() public view returns (uint256) {
        return currentPrice;
    }

    function contractURI() public view returns (string memory) {
        return currentContractURI;
    }

    function getBaseURI() public view returns (string memory) {
        return baseURI;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (_token[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        //Create an array of token structs.
        _token[] memory _tokens = new _token[](tokenCount);

        for (uint256 i; i < tokenCount; i++) {
            uint256 _tokenId = tokenOfOwnerByIndex(_owner, i);
            string memory _tokenURI = tokenURI(_tokenId);
            _tokens[i] = _token(_tokenId, _tokenURI);
        }

        return _tokens;
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
            "ERC721Metadata: URI query for nonexistent bird"
        );

        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }
}