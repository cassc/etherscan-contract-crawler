// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import '@openzeppelin/contracts/access/Ownable.sol';

contract AlternateDimensions is ERC721A, Ownable {  
    using Address for address;

    // The base link that leads to the image / video of the token
    string public baseTokenURI;

    constructor (string memory newBaseURI) ERC721A ("Alternate Dimensions", "AD") {
        setBaseURI(newBaseURI);
    }

    // Override so the openzeppelin tokenURI() method will use this method to create the full tokenURI instead
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // See which address owns which tokens
    function tokensOfOwner(address addr) public view returns(uint256[] memory) {
        uint256 supply = totalSupply();
        uint256 tokenCount = balanceOf(addr);

        uint256[] memory tokensId = new uint256[](tokenCount);
        uint256 currentMatch = 0;

        if(tokenCount > 0) {
            for(uint256 i; i < supply; i++){
                address tokenOwnerAdd = ownerOf(i);
                if(tokenOwnerAdd == addr) {
                    tokensId[currentMatch] = i;
                    currentMatch = currentMatch + 1;
                }
            }
        }
        
        return tokensId;
    }

    // Admin minting function to airdrop
    function airDropByOwner(address[] memory _a, uint256[] memory _amount) public onlyOwner {
        for(uint256 i; i < _a.length; i++){
            _safeMint(_a[i], _amount[i]);
        }
    }

    // Set new baseURI
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }
}