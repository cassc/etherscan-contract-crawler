//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract CryptoMories is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    using SafeMath for uint256;

    string public IWWON_PROVENANCE = "";

    uint256 public startingIndexBlock;

    uint256 public startingIndex;

    uint256 public constant tokenPrice = 20000000000000000; //0.02 ETH

    uint public constant maxTokenPurchase = 10;
    uint256 constant public maxTokenPurchasePresale = 20;

    uint256 public MAX_TOKEN=10000;

    bool public saleIsActive = false;
    bool public privateSaleIsActive = false;

    uint256 public REVEAL_TIMESTAMP;

    struct Whitelist {
        address addr;
        uint hasMinted;
    }
    mapping(address => Whitelist) public whitelist;
    
    address[] public whitelistAddr;


    constructor() public ERC721("CryptoMories", "CRYPTOMORIES") {
    }

     function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    /**
     * Set some Tokens aside
     */
    function reserveToken() public onlyOwner {        
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < 50; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    /**
     * RevealTime set at he begining of the presale .
     * Ovverdies if the collection is sold out
     */
    function setRevealTimestamp(uint256 revealTimeStampInSec) public onlyOwner {
        REVEAL_TIMESTAMP = block.timestamp + revealTimeStampInSec;
    } 

    /*     
    * Set provenance. It is calculated and saved before the presale.
    */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        IWWON_PROVENANCE = provenanceHash;
    }

    /* 
    * To manage the reveal -The baseUri will be modified after
    * the startingIndex has been calculated.
    */
    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }


    /*
    * Pause sale if active, make active if paused
    */
    function flipSaleState() public onlyOwner returns (bool) {
        saleIsActive = !saleIsActive;
        return  saleIsActive;
    }

    /*
    * Pause presale if active, make active if paused - 
    * Presale for whitelisted only
    */
    function flipPrivateSaleState() public onlyOwner {
        privateSaleIsActive = !privateSaleIsActive;
    }


    /**
    * Mints token
    */
    function mintToken(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active");
        require(totalSupply().add(numberOfTokens) <= MAX_TOKEN, "Purchase would exceed max supply.");
        require(tokenPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
        
       if(privateSaleIsActive) {
            require(numberOfTokens <= maxTokenPurchasePresale, "Presale Purchase would not exeed maxTokenWhiteList at a time");
            require(isWhitelisted(msg.sender), "Is not whitelisted");
            require(whitelist[msg.sender].hasMinted.add(numberOfTokens) <= maxTokenPurchasePresale, "Above presale maxToken.");
            whitelist[msg.sender].hasMinted = whitelist[msg.sender].hasMinted.add(numberOfTokens);
        } else {
            require(numberOfTokens <= maxTokenPurchase, "Can only mint maxTokenPurchase tokens at a time");
        }
        
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_TOKEN) {
                _safeMint(msg.sender, mintIndex);
            }
        }

        // If we haven't set the starting index and this is either 1) the last saleable token or 2) the first token to be sold after
        // the end of pre-sale, set the starting index block
        if (startingIndexBlock == 0 && (totalSupply() == MAX_TOKEN || block.timestamp >= REVEAL_TIMESTAMP)) {
            startingIndexBlock = block.number;
        } 
    }

    /**
     * Set the starting index once the startingBlox index is known
     */
    function setStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_TOKEN;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % MAX_TOKEN;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }

    /**
     * Set the starting index block for the collection, essentially unblocking
     * setting starting index
     */
    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        
        startingIndexBlock = block.number;
    }

/******** WHITELIST */
    /**
    * @dev add an address to the whitelist
    * @param addr address
    */
    function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
        require(!isWhitelisted(addr), "Already whitelisted");
        whitelist[addr].addr = addr;
        whitelist[addr].hasMinted = 0;
        success = true;
        whitelistAddr.push(addr);
    }

    /*
    *   Add an array of adresses 
    */
    function addAddressesToWhitelist(address[] memory addrs) onlyOwner public returns(bool success) {
       
        for(uint i = 0; i < addrs.length; i++) {
            addAddressToWhitelist(addrs[i]);
        }
    }

    /*
    * Are you an happy Early Believer?
    */
    function isWhitelisted(address addr) public view returns (bool isWhiteListed) {
        return whitelist[addr].addr == addr;
    }

    /*
    * Returns the list of Whitelisted / Early Believers
    */
    function getWhiteListedAdrrs() view public returns(address[] memory ) {
        return whitelistAddr;
    }

    function getWhitelistedData(address _address) view public returns ( uint) {
        return ( whitelist[_address].hasMinted);
    }

    /*
    * Number of whitemisted / Early Believers
    */
    function countWhitelisted() view public returns (uint) {
        return whitelistAddr.length;
    }


}