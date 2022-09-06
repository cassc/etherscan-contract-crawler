// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import './ERC721A.sol';

// minting at.... >> https://cognitionnft.xyz
// Supply 750
// Mint Price 0.03 ETH

// A generative and procedurally generated art collection which explores the relationship
// between, and distances between, concepts. The art provides a metaphor
// for the thought process involved in linking words and ideas together, their similarity 
// or lack thereof, and sentiment.

// The art is 100% generative and powered by a composite machine learning model and Natural
// Language Processing techniques (such as TF-IDF, Cosine Similarity, Vectorized Tokens, etc).

// a unique piece of art is generated encapsulating the essence of thought, recollection, and
// problem solving.

// Developed by theblockchain.eth -> Twitter: @tbc_eth

//  .._..._.........._....._............_........_..........._............._..._.....
//  .|.|.|.|........|.|...|.|..........|.|......|.|.........(_)...........|.|.|.|....
//  .|.|_|.|__...___|.|__.|.|.___...___|.|._____|.|__...__._._._.__....___|.|_|.|__..
//  .|.__|.'_.\./._.\.'_.\|.|/._.\./.__|.|/./.__|.'_.\./._`.|.|.'_.\../._.\.__|.'_.\.
//  .|.|_|.|.|.|..__/.|_).|.|.(_).|.(__|...<.(__|.|.|.|.(_|.|.|.|.|.||..__/.|_|.|.|.|
//  ..\__|_|.|_|\___|_.__/|_|\___/.\___|_|\_\___|_|.|_|\__,_|_|_|.|_(_)___|\__|_|.|_|
//  .................................................................................\

contract cognition is Ownable, ERC721A, Pausable {
    using SafeMath for uint256;

    uint private constant maxSupplyPlusOne = 751;
    uint private constant mintPrice = 0.03 ether;
    uint private constant maxMintPlusOne = 6;

    string public _metadataBaseURI;

    constructor(string memory metadataBaseURI) ERC721A("Cognition", "COGNI") {
        _metadataBaseURI = metadataBaseURI;
        _pause();
    }   
    
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function updateMetadata(string memory baseURI) public onlyOwner {
        _metadataBaseURI = baseURI;
    }

    function mint(uint256 quantity) external payable whenNotPaused {
        require(quantity > 0, "Insufficient Mint");
        require(mintPrice * quantity <= msg.value, "Insufficient funds sent");
        require(quantity < maxMintPlusOne, "Too Many Requested");

        uint totalMinted = totalSupply();
        require(totalMinted.add(quantity) < maxSupplyPlusOne, "Insufficient Supply");

        _safeMint(msg.sender, quantity);
    }

    function premintForMarketplaceSale() public payable onlyOwner {
        _safeMint(msg.sender, 5);
        _safeMint(msg.sender, 5);
        _safeMint(msg.sender, 5);
        _safeMint(msg.sender, 5);
        _safeMint(msg.sender, 5);
    }

    function withdrawContractFunds() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return _metadataBaseURI;
    }

}