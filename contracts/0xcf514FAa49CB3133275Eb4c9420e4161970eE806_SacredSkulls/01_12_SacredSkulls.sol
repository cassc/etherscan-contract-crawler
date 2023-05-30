// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/*
   _____                          __   _____ __         ____    
  / ___/____ ______________  ____/ /  / ___// /____  __/ / /____
  \__ \/ __ `/ ___/ ___/ _ \/ __  /   \__ \/ //_/ / / / / / ___/
 ___/ / /_/ / /__/ /  /  __/ /_/ /   ___/ / ,< / /_/ / / (__  ) 
/____/\__,_/\___/_/   \___/\__,_/   /____/_/|_|\__,_/_/_/____/  

I see you nerd! ⌐⊙_⊙
*/

contract SacredSkulls is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    uint256 public maxTokenSupply;

    uint256 public mintPrice = 0.065 ether;

    uint256 public maxPresaleMintsPerWallet = 4;
    uint256 public constant MAX_MINTS_PER_TXN = 20;

    bool public preSaleIsActive = false;
    bool public saleIsActive = false;

    bool public isLocked = false;
    string public baseURI;
    string public provenance;

    mapping (address => uint256) private _presaleMints;

    constructor(string memory name, string memory symbol, uint256 maxSupply) ERC721(name, symbol) {
        maxTokenSupply = maxSupply;
    }

    function setMaxTokenSupply(uint256 maxSupply) public onlyOwner {
        require(!isLocked, "Locked");
        maxTokenSupply = maxSupply;
    }

    function setMintPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
    }

    function setMaxPresaleMintsPerWallet(uint256 newLimit) public onlyOwner {
        maxPresaleMintsPerWallet = newLimit;
    }

    function withdrawForGiveaway(uint256 amount, address payable to) public onlyOwner {
        Address.sendValue(to, amount);
    }

    function withdraw(uint256 amount) public onlyOwner {
        Address.sendValue(payable(msg.sender), amount);
    }

    /*
    * Mint reserved NFTs for giveaways, devs, etc.
    */
    function reserveMint(uint256 reservedAmount, address mintAddress) public onlyOwner {        
        for (uint256 i = 1; i <= reservedAmount; i++) {
            _tokenIdCounter.increment();
            _safeMint(mintAddress, _tokenIdCounter.current());
        }
    }

    /*
    * Pause sale if active, make active if paused.
    */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /*
    * Pause pre-sale if active, make active if paused.
    */
    function flipPreSaleState() public onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }

    /*
    * Lock provenance and base URI.
    */
    function lockProvenance() public onlyOwner {
        isLocked = true;
    }

    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function mint(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale not live");
        require(numberOfTokens <= MAX_MINTS_PER_TXN, "Exceeds max mints per txn");
        require(_tokenIdCounter.current() + numberOfTokens <= maxTokenSupply, "Exceeds max supply");
        require(mintPrice * numberOfTokens <= msg.value, "Incorrect ether value");

        for(uint256 i = 0; i < numberOfTokens; i++) {
            _tokenIdCounter.increment();
            _safeMint(msg.sender, _tokenIdCounter.current());
        }
    }

    function presaleMint(uint256 numberOfTokens) public payable {
        require(preSaleIsActive, "Pre-sale not live");
        require(_presaleMints[msg.sender] + numberOfTokens <= maxPresaleMintsPerWallet, "Presale mint limit exceeded");
        require(_tokenIdCounter.current() + numberOfTokens <= maxTokenSupply, "Exceeds max supply");
        require(mintPrice * numberOfTokens <= msg.value, "Incorrect ether value");

        _presaleMints[msg.sender] += numberOfTokens;

        for(uint256 i = 0; i < numberOfTokens; i++) {
            _tokenIdCounter.increment();
            _safeMint(msg.sender, _tokenIdCounter.current());
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        require(!isLocked, "Locked");
        baseURI = newBaseURI;
    }

    /*     
    * Set provenance once it's calculated.
    */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        require(!isLocked, "Locked");
        provenance = provenanceHash;
    }
}