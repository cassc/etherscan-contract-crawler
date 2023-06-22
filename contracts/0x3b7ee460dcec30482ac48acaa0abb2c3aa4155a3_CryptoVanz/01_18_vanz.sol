// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//   ---------------------------.
// `/""""/""""/|""|'|""||""|   ' \.
// /    /    / |__| |__||__|      |
// /----------====================|
// | \  /\  /    _.               |
// |()\ \/ /()   _            _   |
// |   \  /     / \          / \  |-( )
// =C========C=_| ) |--------| ) _/==] _-{ CryptoVanz }_)
// \_\_/__..  \_\_/_ \_\_/ \_\_/__.__.

// The downlow lowdown:
//  Every week we'll mint a batch of 222 Vanz
//  The first batch is a free drop
//  Every week after that, the price goes up 0.01eth
//
//  If we don't sell out a batch within a week, 
//   it's the end of the road, and there is no next batch.
//  
//  Hop a ride and join the convoy
//   There's a destination in the distance, 
//   but we've got interesting stops to make along the way.

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol"; 
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract CryptoVanz is ERC721, ERC721URIStorage, Pausable, PaymentSplitter, AccessControl {

    uint256 private _numPerBatch = 222; 
    uint16 public constant _maxMint = 5;
    uint private _batchDurationDays = 7; // one week to mint out
    uint private _lastBatchDate = block.timestamp;    

    uint256 private _priceMultiplier = 10000000000000000; // 0.01 Ether per batch
    string private _baseHash; // tokenURI base hash changes with every batch

    bytes32 public constant MOST_SOBER_DRIVERS = keccak256("MOST_SOBER_DRIVERS");

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _batchIdCounter;
    Counters.Counter private _batchNum;

    using Strings for string;

    constructor(
        string memory hash,  
        address[] memory _payees,
        uint256[] memory _shares,
        address[] memory _drivers
    ) 
      ERC721("CryptoVanz", "VANZ")
      PaymentSplitter(_payees, _shares) payable
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MOST_SOBER_DRIVERS, msg.sender);

        require(_drivers.length > 1, "Set drivers");
        for(uint16 i; i < _drivers.length; i++) {
            _setupRole(MOST_SOBER_DRIVERS, _drivers[i]);
        }

        _tokenIdCounter.increment(); // start at 1
        _baseHash = hash; // the first metadata hash
    }

    function nextBatch(string memory hash)
        public  
    {
        require(hasRole(MOST_SOBER_DRIVERS, msg.sender), "No permission");

        // there will be no next batch if this current one doesn't sell out
        uint256 batchMinted = _batchIdCounter.current();
        require(batchMinted == _numPerBatch, "Not all sold");

        // need to be sold out in a week [see _mintyFresh()], then have a 1 day buffer to start next batch
        uint256 batchWithinDays = _batchDurationDays + 1;
        require (block.timestamp <= _lastBatchDate + batchWithinDays * 1 days, "Did not sell out in time");

        _batchNum.increment();
        _batchIdCounter.reset();
        _lastBatchDate = block.timestamp;
        _baseHash = hash;
    }
    
    function hitchhikerMint() 
        public  
    {
        // We're picking up hitchhikers!
        // the first batch is free to mint so heres a non-payable function call
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId <= _numPerBatch, "None left in batch");

        _mintyFresh(msg.sender); 
    }

    function mint(uint16 num) 
        payable 
        public  
    {
        // Everything after the first batch mints through this payable check
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId >= _numPerBatch, "free! call hitchhikerMint");

        uint256 currentBatchNum = _batchNum.current();
        uint256 price = currentBatchNum * _priceMultiplier; // 0.01 Ether per batch

        uint256 batchId = _batchIdCounter.current();

        require(num > 0, "Mint at least 1");
        require(num <= _maxMint, "Cannot mint that many" );
        require((num + batchId) <= _numPerBatch, "Exceeds supply");
        require(msg.value >= price * num, "Insufficient eth to mint");

        for(uint16 i; i < num; i++) {
            _mintyFresh(msg.sender);
        }
    }

    function driverMint(address[] memory to) 
        public 
    {
        // Owner/driver can mint for giveaways and airdrops

        require(hasRole(MOST_SOBER_DRIVERS, msg.sender), "driverMint: no permission");

        uint256 num = to.length;
        uint256 batchId = _batchIdCounter.current();

        require(num > 0, "No addresses received");
        require((num + batchId) <= _numPerBatch, "Exceeds supply");

        for(uint16 i; i < to.length; i++) {
            _mintyFresh(to[i]);
        }
    }

    function _mintyFresh(address to) 
        internal
        whenNotPaused
    {
        // handles the common minting functions once require checks are done elsewhere

        uint256 batchId = _batchIdCounter.current();
        require(batchId < _numPerBatch, "None left in batch");            

        // don't allow minting if it's past the cutoff number of days
        require (block.timestamp <= _lastBatchDate + _batchDurationDays * 1 days, "Too late");

        uint256 tokenId = _tokenIdCounter.current();

        _tokenIdCounter.increment();
        _batchIdCounter.increment();
        _safeMint(to, tokenId);

        string memory uri = string(abi.encodePacked('ipfs://', _baseHash, '/', uint2str(tokenId)));
        
        _setTokenURI(tokenId, uri);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function pause() 
        public 
    {
        require(hasRole(MOST_SOBER_DRIVERS, msg.sender), "pause error");

        _pause();
    }

    function unpause() 
        public 
    {
        require(hasRole(MOST_SOBER_DRIVERS, msg.sender), "unpause error");

        _unpause();
    }

    function withdraw() 
        public 
    {
        this.release(payable(msg.sender));
    }

    function addAdmin(address addy) 
        public 
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "not admin");
        _grantRole(DEFAULT_ADMIN_ROLE, addy);
    }

    function isAdmin(address addy) 
        public 
        view 
        returns (bool) 
    {
        return hasRole(DEFAULT_ADMIN_ROLE, addy);
    }


    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // Getter functions for checking out what's under the hood

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function baseHash()
        public
        view
        returns (string memory)
    {
        return _baseHash;
    }

    function batchSecondsLeft()
        public  
        view
        returns (uint)
    {        
        require (block.timestamp <= _lastBatchDate + _batchDurationDays * 1 days, "Time is up");
        return _lastBatchDate + _batchDurationDays * 1 days - block.timestamp;
    }

    function totalSupply()
        public
        view
        returns (uint256)
    {
        uint256 tokenId = _tokenIdCounter.current() - 1;
        return tokenId;
    }

    function batchSupply()
        public
        view
        returns (uint256)
    {
        return _batchIdCounter.current();
    }

    function batchNum()
        public
        view
        returns (uint256)
    {
        return _batchNum.current();
    }

    function numPerBatch()
        public
        view
        returns (uint256)
    {
        return _numPerBatch;
    }

    function currentPrice()
        public
        view
        returns (uint256)
    {
        uint256 price = _batchNum.current() * _priceMultiplier; // 0.01 Ether per batch
        return price;
    }
       
    // gettin stringy with it
    
    function uint2str(uint256 value) 
        internal 
        pure 
        returns (string memory) 
    {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

// @naftponk