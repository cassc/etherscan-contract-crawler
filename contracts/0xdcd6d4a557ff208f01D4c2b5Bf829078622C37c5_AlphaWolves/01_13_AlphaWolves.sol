// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
/*  
    Contract by Selema
    Disc: Selema#0880
    Twitter: @ImpurefulArt
*/
contract AlphaWolves is ERC721, ERC721Enumerable, Ownable {
    string public PROVENANCE;
    bool public isPublicSaleActive = false;
    string private _baseURIextended;

    bool public isAllowListActive = false;
    bool public isFreeMintActive = false;
    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant MAX_PUBLIC_MINT = 1;
    uint256 public constant PRIVATE_PRICE_PER_TOKEN = 0.33 ether;
    uint256 public constant FREE_TOKEN_PRICE = 0.0 ether;
    uint256 public constant PUBLIC_PRICE_PER_TOKEN = 0.33 ether;
    
    //for the private Sale
    mapping(address => uint8) private _allowList;

    //for the free Mints
    mapping(address => uint8) private _freeList;


    constructor() ERC721("Alpha Wolves DAO", "ALPHA") {
    }

    // Activation Setters

    function activatePublicSale(bool newState) public onlyOwner {
        isPublicSaleActive = newState;
    }

    function activateAllowList(bool newState) public onlyOwner {
        isAllowListActive = newState;
    }

    function activateFreeMint(bool newState) public onlyOwner {
        isFreeMintActive = newState;
    }
    
    // Adding Addresses to private Sale 

    function setAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = numAllowedToMint;
        }
    }
    // Adding Addresses to free Mint

    function setFreeList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _freeList[addresses[i]] = numAllowedToMint;
        }
    }

    
    //Check available address FreeList Mints

    function numAvailableToMintForFree(address addr) external view returns (uint8) {
        return _freeList[addr];
    }

    //Check available address AllowList Mints

    function numAvailableToMint(address addr) external view returns (uint8) {
        return _allowList[addr];
    }
    
    // Mint function for Addresses on AllowList

    function mintAllowList(uint8 numberOfTokens) external payable {
        uint256 ts = totalSupply();
        require(isAllowListActive, "Allow list is not active");
        require(numberOfTokens <= _allowList[msg.sender], "Exceeded max available to purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(PRIVATE_PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

        _allowList[msg.sender] -= numberOfTokens;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }
    // Free mint function for Addresses on FreeList

    function mintFreeList(uint8 numberOfTokens) external payable {
        uint256 ts = totalSupply();
        require(isFreeMintActive, "Free mint is not active");
        require(numberOfTokens <= _freeList[msg.sender], "Exceeded max available to purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(FREE_TOKEN_PRICE * numberOfTokens <= msg.value, "This is free");

        _freeList[msg.sender] -= numberOfTokens;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }
    

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }
    

    function reserve(uint256 n) public onlyOwner {
      uint supply = totalSupply();
      uint i;
      for (i = 0; i < n; i++) {
          _safeMint(msg.sender, supply + i);
      }
    }

  // public Mint function

    function mint(uint numberOfTokens) public payable {
        uint256 ts = totalSupply();
        require(isPublicSaleActive, "Public Sale must be active to mint tokens");
        require(numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(PUBLIC_PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }
   // Withdraw function

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}