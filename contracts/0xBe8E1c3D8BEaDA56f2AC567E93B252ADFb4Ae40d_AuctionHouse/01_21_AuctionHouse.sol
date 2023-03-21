// SPDX-License-Identifier: GPL-3.0

// The Wildxyz auctionhouse.sol

// AuctionHouse.sol is a modified version of the original code from the
// NounsAuctionHouse.sol which is a modified version of Zora's AuctionHouse.sol:
// https://github.com/ourzora/auction-house/
// licensed under the GPL-3.0 license.

pragma solidity ^0.8.17;

import './Pausable.sol';
import './ReentrancyGuard.sol';
import './Ownable.sol';
import './WildNFT.sol';
import './IAuctionHouse.sol';

contract AuctionHouse is
    IAuctionHouse,
    Pausable,
    ReentrancyGuard,
    Ownable
{
    // auction variables
    uint256 public allowlistMintMax     = 2;        // max number of tokens per allowlist mint
    uint256 public timeBuffer           = 120;       // min amount of time left in an auction after last bid
    uint256 public minimumBid           = .1 ether;  // The minimum price accepted in an auction
    uint256 public minBidIncrement      = .01 ether; // The minimum amount by which a bid must exceed the current highest bid
    uint256 public allowListPrice       = .1 ether;  // The allowlist price
    uint256 public duration             = 86400;     // 86400 == 1 day The duration of a single auction in seconds

    address payable public payee;               // The address that receives funds from the auction
    uint256 public raffleSupply         = 2;   // max number of raffle winners
    uint256 public auctionSupply        = 13;   // number of auction supply max of raffle ticket
    uint256 public allowlistSupply      = 59;   // number allowlist supply
    uint256 public maxSupply            = 103;  // max supply 
    uint256 public promoSupply          = 29;   // promo supply

    uint256 public oasisListStartDateTime = 1679421600; //oasislistStartDate 11AM PST 2023-02-28
    uint256 public allowListStartDateTime = 1679425200; //allowListStartDateTime
    uint256 public allowListEndDateTime   = 1679468400; //allowListEndDateTime  
    uint256 public auctionStartDateTime   = 1679468400; //==allowListEndDateTime; 
    uint256 public auctionEndDateTime     = 1679511600; //auctionEndDateTime
    
    uint256 public auctionExtentedTime  = 0; 
    bool    public auctionWinnersSet    = false;
    bool    public raffleWinnersSet     = false;
    bool    public auctionSettled       = false;
    bool    public settled              = false;
    bool    public publicSale           = false;

    // allowlist mapping 1=oasis;2=allowlist;0=not on list
    mapping(address => uint8) public allowList;

    WildNFT public nft;

    // Only allow the auction functions to be active when not paused
    modifier onlyUnpaused() {
        require(!paused(), 'AuctionHouse: paused');
        _;
    }

    // Bids Struct
    struct Bid {
        address payable bidder; // The address of the bidder
        uint256 amount; // The amount of the bid
        bool minted; // has the bid been minted
        uint256 timestamp; // timestamp of the bid
        bool refunded; // refund difference between winning_bid and max_bid for winner; and all for losers  
        bool winner; // is the bid the winner
        uint256 finalprice; // if won, what price won at

    }

    // mapping of Bid structs
    mapping(address => Bid) public Bids;

    constructor(WildNFT _nft, address _payee) {
        nft = _nft;
        payee = payable(_payee);
    }

    /* ADMIN VARIABLE SETTERS FUNCTIONS */

    // set the 721 contract address
    function set721ContractAddress(WildNFT _nft) public onlyOwner {
        nft = _nft;
    }

    function setAuctionSupply(uint256 _newAuctionSupply) public onlyOwner {
        auctionSupply = _newAuctionSupply;
    }

    function setPromoSupply(uint256 _newPromoSupply) public onlyOwner {
        promoSupply = _newPromoSupply;
    }

    function addToAllowList(address[] memory _addresses, uint8 _state) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            allowList[_addresses[i]] = _state;
        }
    }

    function removeFromAllowList(address[] memory _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            allowList[_addresses[i]] = 0;
        }
    }

    function setAllowlistMintMax(uint256 _newAllowlistMintMax) public onlyOwner {
        allowlistMintMax = _newAllowlistMintMax;
    }

    function setOasislistStartDateTime(uint256 _newOasislistStartDateTime) public onlyOwner {
        oasisListStartDateTime = _newOasislistStartDateTime;
    }

    function setAuctionStartDateTime(uint256 _newAuctionStartDateTime) public onlyOwner {
        auctionStartDateTime = _newAuctionStartDateTime;
    }

    function setAuctionEndDateTime(uint256 _newAuctionEndDateTime) public onlyOwner {
        auctionEndDateTime = _newAuctionEndDateTime;
    }

    function setAllowListStartDateTime(uint256 _newAllowListStartDateTime) public onlyOwner {
        allowListStartDateTime = _newAllowListStartDateTime;
    }

    function setAllowListEndDateTime(uint256 _newAllowListEndDateTime) public onlyOwner {
        allowListEndDateTime = _newAllowListEndDateTime;
    }

    function setPublicSale() public onlyOwner {
        publicSale = !publicSale;
    }

    function setRaffleSupply(uint256 _newRaffleSupply) public onlyOwner {
        raffleSupply = _newRaffleSupply;
    }

    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        maxSupply = _newMaxSupply;
    }

    // set the time buffer
    function setTimeBuffer(uint256 _timeBuffer) external onlyOwner override {
        timeBuffer = _timeBuffer;
        emit AuctionTimeBufferUpdated(_timeBuffer);
    }

    // set the minimum bid
    function setMinimumBid(uint256 _minimumBid) external onlyOwner {
        minimumBid = _minimumBid;
    }

    // set min bid incr
    function setMinBidIncrement(uint256 _minBidIncrement) external onlyOwner {
        minBidIncrement = _minBidIncrement;
    }

    // set the duration
    function setDuration(uint256 _duration) external onlyOwner override {
        duration = _duration;
        emit AuctionDurationUpdated(_duration);
    }

    // airdrop mint
    function promoMint(address _to, uint256 _qty) external onlyOwner {
        require(promoSupply >= _qty, 'Not enough promo supply');
        require(block.timestamp <= allowListEndDateTime, 'Outside promo mint window');
        for (uint256 i = 0; i < _qty; i++) {
            nft.mint(_to);
        }
        promoSupply -= _qty;
        auctionSupply = maxSupply - nft.totalSupply() - raffleSupply;
    }

    // airdrop batch mint; sends 1 to each address in array
    function promoBatchMint(address[] memory _to) external onlyOwner {
        require(promoSupply >= _to.length, 'Not enough promo supply');
        require(block.timestamp <= allowListEndDateTime, 'Outside promo mint window');
        for (uint256 i = 0; i < _to.length; i++) {
            nft.mint(_to[i]);
        }
        promoSupply -= _to.length;
        auctionSupply = maxSupply - nft.totalSupply() - raffleSupply;
    }

    // allowlist mint
    function allowlistMint(uint256 _qty) payable external {
        require(allowList[msg.sender] > 0, 'Not on allowlist');
        require(_qty <= allowlistMintMax, 'Qty exceeds max allowed.');
        require(msg.value >= allowListPrice * _qty, 'Not enough ETH sent');
        require(allowlistSupply - _qty >= 0, 'No more allowlist supply');
        if (allowList[msg.sender] == 1) {
            require(
                block.timestamp >= oasisListStartDateTime &&
                    block.timestamp <= allowListEndDateTime,
                'Outside Oasis allowlist window'
            );
        } else if (allowList[msg.sender] == 2) {
            require(
                block.timestamp >= allowListStartDateTime &&
                    block.timestamp <= allowListEndDateTime,
                'Outside allowlist window'
            );
        }

        for (uint256 i = 0; i < _qty; i++) {
            nft.mint(msg.sender);
            allowlistSupply--;
        }
        allowList[msg.sender] = 0;
        auctionSupply = maxSupply - nft.totalSupply() - raffleSupply;

        emit AllowlistMint(msg.sender);
    }

    // pause
    function pause() external onlyOwner override {
        _pause();
    }

    // unpause
    function unpause() external onlyOwner override {
        _unpause();

    }

    // withdraw
    function withdraw() public onlyOwner {
        require(auctionSettled == true && block.timestamp > auctionEndDateTime , "Auction not settled||not ended.");
        (bool success, ) = payee.call{value: address(this).balance}("");
        require(success, "Failed to send to payee.");
    }

    // update payee for withdraw
    function setPayee(address payable _payee) public onlyOwner {
        payee = _payee;
    }

    /* END ADMIN VARIABLE SETTERS FUNCTIONS */


    // UNIVERSAL GETTER FOR AUCTION-RELATED VARIABLES 
       function getAuctionInfo() public view returns (
            uint256 _auctionSupply,
            uint256 _auctionStartDateTime,
            uint256 _auctionEndDateTime,
            uint256 _auctionExtentedTime,
            bool _auctionWinnersSet,
            bool _auctionSettled,
            bool _settled,
            uint256 _timeBuffer,
            uint256 _duration,
            uint256 _minimumBid,
            uint256 _minBidIncrement            
        ) {
            return (
            auctionSupply,
            auctionStartDateTime,
            auctionEndDateTime,
            auctionExtentedTime,
            auctionWinnersSet,
            auctionSettled,
            settled,
            timeBuffer,
            duration,
            minimumBid,
            minBidIncrement
            );
        }

        // UNIVERSAL GETTER FOR ALLOWLIST AND RAFFLE-RELATED VARIABLES 
        function getAllowlistAndRaffleInfo() public view returns (
            uint256 _raffleSupply,
            uint256 _allowListPrice,
            uint256 _allowListStartDateTime,
            uint256 _allowListEndDateTime,
            bool _raffleWinnersSet,
            bool _publicSale,
            uint256 _allowlistSupply,
            uint256 _totalMinted,
            uint256 _oasislistStartDateTime,
            uint256 _allowlistMintMax
        ) {
            return (
            raffleSupply,
            allowListPrice,
            allowListStartDateTime,
            allowListEndDateTime,
            raffleWinnersSet,
            publicSale,
            allowlistSupply,
            nft.totalSupply(),
            oasisListStartDateTime,
            allowlistMintMax
            );
        }

    /* PUBLIC FUNCTIONS */

    // Creates bids for the current auction
    function createBid() external payable nonReentrant onlyUnpaused {


        // Check that the auction is live && Bid Amount is greater than minimum bid
        require(block.timestamp < auctionEndDateTime && block.timestamp >= auctionStartDateTime, "Outside auction window.");
        require(msg.value >= minimumBid, "Bid amount too low.");

        // check if bidder already has bid
        // if so, refund old and replace with new
        if (Bids[msg.sender].amount > 0) {
            require(msg.value > Bids[msg.sender].amount, "You can only increase your bid, not decrease.");
            _safeTransferETH(Bids[msg.sender].bidder, Bids[msg.sender].amount);
            Bids[msg.sender].amount = msg.value;
        }
        // otherwise, enter new bid.
        else {
            Bid memory new_bid;
            new_bid.bidder = payable(msg.sender);
            new_bid.amount = msg.value;
            new_bid.timestamp = block.timestamp;
            new_bid.winner = false;
            new_bid.refunded = false;
            new_bid.minted = false;
            new_bid.finalprice = 0;
            Bids[msg.sender] = new_bid;
        }


        // Extend the auction if the bid was received within the time buffer
        // bool extended = auctionEndDateTime - block.timestamp < timeBuffer;
        //if (extended) {
        //    auctionEndDateTime = auctionEndDateTime + timeBuffer;
        //    auctionExtentedTime = auctionExtentedTime + timeBuffer;
        //}

        emit AuctionBid(msg.sender, Bids[msg.sender].amount, false); 

    }


    function publicSaleMint() public payable nonReentrant onlyUnpaused {
        // if we didnt sell out, we can mint the remaining
        // for price of min bid
        // will error when supply is 0
        // Note: 1) is the auction closed and 2) is the raffle set and 
        // 3) if the total supply is less than the max supply, then you can allow ppl to mint
        // require(auctionEndDateTime < block.timestamp, "Auction not over yet.");
        // require(raffleWinnersSet == true, "Raffle not settled yet.");
        require(nft.totalSupply() < nft.maxSupply());
        require(publicSale == true, "Not authorized.");
        require(msg.value >= minimumBid, "Amount too low.");
        nft.mint(msg.sender);
        auctionSupply--;
    }

    /* END PUBLIC FUNCTIONS */

    /* END OF AUCTION FUNCTIONS */

    function setRaffleWinners(address[] memory _raffleWinners) external onlyOwner {
        require(block.timestamp > auctionEndDateTime, "Auction not over yet.");
        require(raffleWinnersSet == false, "Raffle already settled");
        require(_raffleWinners.length <= raffleSupply, "Incorrect number of winners");
        for (uint256 i = 0; i < _raffleWinners.length; i++) {
            Bids[_raffleWinners[i]].winner = true;
            Bids[_raffleWinners[i]].finalprice = minimumBid;
        }
        raffleWinnersSet = true;
    }

    function setAuctionWinners(address[] memory _auctionWinners, uint256[] memory _prices) external onlyOwner {
        require(block.timestamp > auctionEndDateTime, "Auction not over yet.");
        require(auctionWinnersSet == false, "Auction already settled");
        for (uint256 i = 0; i < _auctionWinners.length; i++) {
            Bids[_auctionWinners[i]].winner = true;
            Bids[_auctionWinners[i]].finalprice = _prices[i];
        }
        auctionWinnersSet = true;
    }

    /**
     * Settle an auction, finalizing the bid and paying out to the owner.
     * If there are no bids, the Oasis is burned.
     */
    function settleBidder(address[] memory _bidders) external onlyOwner nonReentrant {
        require(block.timestamp > auctionEndDateTime, "Auction hasn't ended.");
        require(auctionWinnersSet == true && raffleWinnersSet == true, "Auction winners not set");

        for (uint256 i = 0; i < _bidders.length; i++) {
            if (Bids[_bidders[i]].winner == true && Bids[_bidders[i]].minted == false && Bids[_bidders[i]].refunded == false) {
                // if winner, mint and refunde diff if any, update Bids
                uint256 difference = Bids[_bidders[i]].amount - Bids[_bidders[i]].finalprice;
                if (difference > 0) {
                    (bool success, ) = _bidders[i].call{value: difference}("");
                    require(success, "Failed to refund difference to winner.");
                }
                nft.mint(_bidders[i]);
                Bids[_bidders[i]].minted = true;
                Bids[_bidders[i]].refunded = true;
            } 
            else if (Bids[_bidders[i]].winner == false && Bids[_bidders[i]].refunded == false) {
                // if not winner, refund
                (bool success, ) = _bidders[i].call{value: Bids[_bidders[i]].amount}("");
                require(success, "Failed to send refund to loser.");
                Bids[_bidders[i]].refunded = true;
            }
        }

    }



    function setAuctionSettled() external onlyOwner {
        require(auctionSettled == false, "Auction already settled");
        auctionSettled = !auctionSettled;
    }

    function setTimes(uint256 allowListStart, uint256 _duration) public onlyOwner{
        oasisListStartDateTime = allowListStart + 90;
        allowListStartDateTime = allowListStart + 90;
        allowListEndDateTime = allowListStartDateTime + _duration;
        auctionStartDateTime = allowListEndDateTime;
        auctionEndDateTime = auctionStartDateTime + _duration;
    }

    function setAllowListPrice (uint256 _allowListPrice) public onlyOwner {
        allowListPrice = _allowListPrice;
    }

    /**
     * Transfer ETH and return the success status.
     * This function only forwards 30,000 gas to the callee.
     */
    function _safeTransferETH(address to, uint256 value)
        internal
        returns (bool)
    {
        (bool success, ) = to.call{value: value, gas: 30_000}(new bytes(0));
        return success;
    }

}