// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract TATest is ERC721, Ownable, ERC721Burnable {
    
    // State Variables
    using Counters for Counters.Counter;
    Counters.Counter private tokenIdCounter;
    string public currentBaseURI;
    string public currentContractURI;

    // Constructor
    constructor(string memory _currentBaseURI, string memory _name, string memory _symbol, address _owner) ERC721(_name, _symbol) {
        
        // Set Base URI
        currentBaseURI = _currentBaseURI;
        
        // Transfer Ownership
        transferOwnership(_owner);

         // nextTokenId is initialized to 1,
        tokenIdCounter.increment();
    }

    // Base URI
    function _baseURI() internal view override returns (string memory) {
        return currentBaseURI;
    }

    // Contract URI
    function contractURI() public view returns (string memory) {
        return currentContractURI;
    }

    /**
        @dev Set Base URI - onlyOwner
    */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        currentBaseURI = _newBaseURI;
    }

    /**
        @dev Set Contract URI - onlyOwner
    */
    function setContractURI(string memory _newContractURI) public onlyOwner {
        currentContractURI = _newContractURI;
    }

    /**
        @dev Mint - onlyOwner
    */
    function mint(address to) public onlyOwner {
        uint256 tokenId = tokenIdCounter.current();
        tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    /**
        @dev Batch Mint - onlyOwner
    */
    function batchMint(address to , uint256 amount) public onlyOwner {
        for(uint i=1; i<=amount;i++){
            mint(to);
        }
    }

    /**
        @dev Returns the total tokens minted so far.
        1 is always subtracted from the Counter since it tracks the next available tokenId.
    */
    function totalSupply() public view returns (uint256) {
        return tokenIdCounter.current() - 1;
    }


}