// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract CleverGhouls is ERC721Enumerable, Ownable {  
    using Address for address;
    
    // Activate contract
    bool public active = false;

    // Reserved for giveaways and so on
    uint256 public reserved = 40;

    // Maximum limit of tokens that can ever exist
    uint256 constant MAX_SUPPLY = 666;

    // The base link that leads to the image / video of the token
    string public baseTokenURI;

    // List of addresses that have a number of reserved tokens for presale
    mapping (address => bool) public winners;

    constructor (string memory newBaseURI) ERC721 ("Clever Ghouls", "CGH") {
        setBaseURI(newBaseURI);
    }

    // Override so the openzeppelin tokenURI() method will use this method to create the full tokenURI instead
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // See which address owns which tokens
    function tokensOfOwner(address addr) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(addr);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(addr, i);
        }
        return tokensId;
    }

    function redeemGhoul() public {
        uint256 supply = totalSupply();
        require( active,              "Contract isn't active" );
        require( winners[msg.sender], "Sorry, you don't have any redeemable Clever Ghouls" );
        winners[msg.sender] = false;
        _safeMint( msg.sender, supply);
    }
    
    // Edit reserved presale spots
    function setWinners(address[] memory _a, bool[] memory _val) public onlyOwner {
        for(uint256 i; i < _a.length; i++){
            winners[_a[i]] = _val[i];
        }
    }

    // Admin minting function to reserve tokens for auctions and giveaways
    function reserveGhouls(uint256 _amount) public onlyOwner {
        // Limited to a publicly set amount
        require( _amount <= reserved, "Can't reserve more than set amount" );
        reserved -= _amount;
        uint256 supply = totalSupply();
        for(uint256 i; i < _amount; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    // Start and stop contract
    function setActive(bool _val) public onlyOwner {
        active = _val;
    }

    // Set new baseURI
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }
}