// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';

contract TheRockingUniquehorns is ERC721Enumerable, Ownable {

    using Counters for Counters.Counter;

    Counters.Counter private _returnedCounter;
    Counters.Counter private _refundableCounter;

    uint256 public MAX_SUPPLY = 9990;
    // reserved for team, giveaways, collabs, musicians
    uint256 public PROMO_TICKETS = 190;
    uint256 public PRICE = 0.0666 ether;

    uint256 public RETURN_PERIOD_START = 1638813966;   // December 6th 6:06:06pm UTC
    uint256 public RETURN_PERIOD_END = 1644516366;   // February 10th 6:06:06pm UTC

    // Provenance hash
    string public PROVENANCE;

    // will be moved to IPFS when sale has ended. needs to be centralized for instant reveal.
    string private _baseTokenURI;
    string private _contractURI;

    uint256 private _maxBookingTransactionSize = 10;
    uint256 private _maxBookingSizeWhitelist = 6;

    uint256 private _amountBlockedForRefund = 0 ether;

    bool private _salePaused = true;
    bool private _whitelistPaused = true;

    // possibly allow for additional refundable TRUs after whitelist
    uint256 private _maxReturnable = 0;

    struct TRUData {
        address discoveredBy;
        uint256 mintPrice;
        bool refundable;
    }

    //whitelist etc
    mapping(address => uint256) public whitelist;
    mapping(uint256 => TRUData) public originalBandMembers;

    bool private _running;

    address[] private _team;

    address private _returnPoolAddress = 0x73939879050B0C5216EC97928D53Ef49B4E984dC;

    event TRUCreated(address mintedBy, uint256 indexed id);

    modifier nonReentrant() {
        require(!_running, "No reentry");
        _running = true;
        _;
        _running = false;
    }

    constructor(uint256 maxSupply, uint256 promoTickets, uint256 returnPeriodStart, uint256 returnPeriodEnd, string memory initialBaseURI, string memory initialContractURI, address[] memory team) ERC721("The Rocking Uniquehorns", "TRU")  {
        MAX_SUPPLY = maxSupply;
        PROMO_TICKETS = promoTickets;
        RETURN_PERIOD_START = returnPeriodStart;
        RETURN_PERIOD_END = returnPeriodEnd;
        _baseTokenURI = initialBaseURI;
        _contractURI = initialContractURI;
        _team = team;
    }

    function mint(uint256 num) external payable nonReentrant {
        require( !_salePaused,                                       "The TRUs all passed out. Sale paused." );
        require( num <= _maxBookingTransactionSize,                  "You can't book that many TRUs in one transaction." );
        require( msg.value >= PRICE * num,                          "The Amount of Ether sent is not correct" );
        require( !_isSoldOut(),                                      "The TRUs are sold out." );

        // TRUs minted in public sale can only be refunded if total supply is <= _maxReturnable
        _mintInternal(msg.sender, num, totalSupply() <= _maxReturnable);
    }

    function mintWhitelist(uint256 num) external payable nonReentrant {
        require( !_whitelistPaused,                                     "The TRUs all passed out. Whitelist sale paused." );
        require(_isWalletWhitelisted(msg.sender),                       "Sorry, this address is not on the whitelist.");
        require( num <= _getWalletWhitelistMax(msg.sender),             "No one needs a band this big" );
        require( msg.value >= PRICE * num,                             "Ether sent is not correct" );
        require( !_isSoldOut(),                                         "The TRUs are sold out." );

        //TRUs minted during whitelist can always be refunded
        _mintInternal(msg.sender, num, true);
        whitelist[msg.sender] -= num;
    }

    /**
     * Fire your TRU, return the TRU to the pool and get back the mint price.
     */
    function fire(uint256[] memory tokenIds) external nonReentrant {
        require(_isRefundPeriodActive(),                "Return period is not active.");

        uint256 totalRefund = 0 ether;

        for(uint256 i = 0; i < tokenIds.length; i++){
            uint256 tokenId = tokenIds[i];
            if(ownerOf(tokenId) == msg.sender && originalBandMembers[tokenId].refundable) {
                //Transfer back to TRU to pool
                _transfer(msg.sender, _returnPoolAddress, tokenId);
                _returnedCounter.increment();
                totalRefund += originalBandMembers[tokenId].mintPrice;
            }
        }

        // refund former holder with the price that was paid during minting
        _widthdraw(msg.sender, totalRefund);
    }

    // Get the TRUs for the address
    function bandOfOwner(address addr) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(addr);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(addr, i);
        }
        return tokensId;
    }

    /*
    * ONLY OWNER STUFF
    */

    // Get the Rocking Uniquehorns to play a promo gig
    // (Method to mint from the reserved TRUs)
    function playPromoGig(address to, uint256 amount) external onlyOwner {
        require( amount <= PROMO_TICKETS, "Not enough promo tickets. This would exceed reserved TRU supply" );

        //promo TRUs can't be refunded
        _mintInternal(to, amount, false);
        PROMO_TICKETS -= amount;
    }

    // Get the TRUs to do a massive stagedive
    // Method to airdrop 1 TRU into every wallet address in the provided list
    function stagedive(address[] memory addresses) external onlyOwner {
        require( addresses.length <= PROMO_TICKETS, "Not enough promo tickets. This would exceed reserved TRU supply" );

        for (uint256 i = 0; i < addresses.length; i++) {
            //promo TRUs can't be refunded
            _mintInternal(addresses[i], 1, false);
            PROMO_TICKETS--;
        }
    }

    // founding band members get the first 5 TRUs for their team pfps
    function castFoundingBand() external onlyOwner {
        for(uint256 i = 0; i < _team.length; i++) {
            _mintInternal(_team[i], 1, false);
        }
        PROMO_TICKETS -= _team.length;
    }

    function withdraw() external payable onlyOwner {
        //make sure the funds needed for potential refunds stay on the contract until return period is over
        _widthdraw(owner(), address(this).balance - _getAmountBlockedForRefund());
    }

    // Setters

    function setProvenanceHash(string memory provenanceHash) external onlyOwner {
        PROVENANCE = provenanceHash;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setContractURI(string memory newURI) external onlyOwner {
        _contractURI = newURI;
    }

    function setReturnPoolAddress(address addr) external onlyOwner {
        _returnPoolAddress = addr;
    }

    function setMaxBookingSizes(uint256 maxBookingTransactionSize, uint256 maxBookingSizeWhitelist) external onlyOwner {
        _maxBookingTransactionSize = maxBookingTransactionSize;
        _maxBookingSizeWhitelist = maxBookingSizeWhitelist;
    }

    // They are rockstars after all, who knows when they are hung over and need a break.
    function setPauseStates(bool salesPaused, bool whitelistPaused) external onlyOwner {
        _salePaused = salesPaused;
        _whitelistPaused = whitelistPaused;
    }

    function addToWhitelist(address[] memory addresses) external onlyOwner {
        for(uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = _maxBookingSizeWhitelist;
        }
    }

    // edit or remove addresses (set amount to 0) from whitelist
    function editWhitelist(address[] memory addresses, uint256[] memory amounts) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = amounts[i];
        }
    }

    /*
    * Public view stuff
    */

    function isSaleActive() public view returns(bool) {
        return !_salePaused;
    }

    function isWhitelistSaleActive() public view returns(bool) {
        return !_whitelistPaused;
    }

    function getMaxMintableTransactionForWallet(address addr) public view returns(uint256) {
        return _getMaxMintableTransactionForWallet(addr) - 1;
    }

    function getAmountBlockedForRefund() public view returns (uint256) {
        return _getAmountBlockedForRefund();
    }

    function isWalletWhitelisted(address addr) public view returns (bool) {
        return _isWalletWhitelisted(addr);
    }

    function getWalletWhitelistMax(address addr) public view returns (uint256) {
        return _getWalletWhitelistMax(addr);
    }

    function isEligibleForRefund(uint256 tokenId) public view returns (bool) {
        return _isRefundPeriodActive() && originalBandMembers[tokenId].refundable;
    }

    function getRefundValue(uint256 tokenId) public view returns (uint256) {
        return originalBandMembers[tokenId].refundable ? originalBandMembers[tokenId].mintPrice : 0;
    }

    function getTotalReturned() public view returns (uint256) {
        return _returnedCounter.current();
    }

    function getTotalRefundable() public view returns (uint256) {
        return _refundableCounter.current();
    }

    function getPrice() public view returns (uint256) {
        return PRICE;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function isSoldOut() public view returns (bool) {
        return _isSoldOut();
    }

    // like every good rockstar, we sometimes cover & sample stuff (override section)
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    //private stuff

    function _isSoldOut() private view returns (bool) {
        return !(totalSupply() < MAX_SUPPLY - PROMO_TICKETS);
    }

    function _getAmountBlockedForRefund() private view returns (uint256) {
        if(block.timestamp < RETURN_PERIOD_END) {
            return _amountBlockedForRefund;
        }
        return 0;
    }

    function _isWalletWhitelisted(address addr) private view returns (bool) {
        return whitelist[addr] > 0;
    }

    function _getMaxMintableTransactionForWallet(address addr) private view returns(uint256) {
        if(!_whitelistPaused) {
            return _getWalletWhitelistMax(addr);
        }
        else if(!_salePaused) {
            return _maxBookingTransactionSize;
        }
        return 1;
    }

    function _getWalletWhitelistMax(address addr) private view returns (uint256) {
        return whitelist[addr];
    }

    function _isRefundPeriodActive() private view returns (bool) {
        return block.timestamp > RETURN_PERIOD_START && block.timestamp < RETURN_PERIOD_END;
    }

    function _mintInternal(address to, uint256 amount, bool refundable) private {
        uint256 supply = totalSupply();
        require( supply + amount <= MAX_SUPPLY,     "Exceeds maximum TRU supply" );

        for(uint256 i = 0; i < amount; i++){
            uint256 id = supply + i;
            _safeMint( to, id );
            emit TRUCreated(msg.sender, id);
            originalBandMembers[id].discoveredBy = to;
            originalBandMembers[id].mintPrice = PRICE;
            originalBandMembers[id].refundable = refundable;
            if(refundable) {
                _refundableCounter.increment();
                _amountBlockedForRefund += PRICE;
            }
        }
    }

    function _widthdraw(address addr, uint256 amount) private {
        require(payable(addr).send(amount), "Transfer failed");
    }

}