// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Jolly Elves Girls v1.0

contract JollyElvesGirls is ERC721Enumerable, Ownable {  
    using Address for address;

    // Sale Controls
    bool public saleActive = false;
    
    // Token Supply
    uint256 public constant TOTAL_SUPPY = 3000;
    uint256 public constant PUBLIC_SUPPLY = 2800;
    uint256 public GIFT_SUPPLY = 200;

    // Contract URI
    string public contractURI;

    // Create New TokenURI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // Base Link That Leads To Metadata
    string public baseTokenURI;

    constructor (string memory newBaseURI) ERC721 ("Jolly Elves Girls", "JEG") {
        setBaseURI(newBaseURI);
    }

    // Check Token # Ownership
    function checkOwner(address addr) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(addr);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(addr, i);
        }
        return tokensId;
    }

    // Minting Function
    function mintElves(uint256 _amount) public {
        uint256 supply = totalSupply();
        require( saleActive, "Public Sale Not Active" );
        require( _amount > 0 && _amount < 4, "Can't Mint More Than 3" );
        require( supply + _amount <= PUBLIC_SUPPLY, "Not Enough Supply" );
        for(uint256 i; i < _amount; i++){
            _safeMint( msg.sender, supply + i );
        }
    }
    
    // Set New baseURI
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    // Sale On/Off
    function setSaleActive(bool val) public onlyOwner {
        saleActive = val;
    }

    // Set Contract URI
    function setContractURI(string memory newContractURI) external onlyOwner {
        contractURI = newContractURI;
    }

}