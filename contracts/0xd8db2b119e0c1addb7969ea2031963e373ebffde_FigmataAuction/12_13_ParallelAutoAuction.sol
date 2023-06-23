// SPDX-License-Identifier: MIT
// Archetype ParallelAutoAuction
//
//        d8888                 888               888
//       d88888                 888               888
//      d88P888                 888               888
//     d88P 888 888d888 .d8888b 88888b.   .d88b.  888888 888  888 88888b.   .d88b.
//    d88P  888 888P"  d88P"    888 "88b d8P  Y8b 888    888  888 888 "88b d8P  Y8b
//   d88P   888 888    888      888  888 88888888 888    888  888 888  888 88888888
//  d8888888888 888    Y88b.    888  888 Y8b.     Y88b.  Y88b 888 888 d88P Y8b.
// d88P     888 888     "Y8888P 888  888  "Y8888   "Y888  "Y88888 88888P"   "Y8888
//                                                            888 888
//                                                       Y8b d88P 888
//                                                        "Y88P"  888

pragma solidity ^0.8.4;

import "./interfaces/IParallelAutoAuction.sol";
import "./interfaces/IExternallyMintable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "solady/src/utils/SafeTransferLib.sol";


error WrongTokenId();
error WrongBidAmount();
error AuctionPaused();
error OptionLocked();

struct StateLocks {
    bool initializationLocked;
    bool baseDurationLocked;
    bool timeBufferLocked;
    bool startingPriceLocked;
    bool bidIncrementLocked;
}


contract ParallelAutoAuction is IParallelAutoAuction, Ownable {
    
    // @notice The config for the auction should be immutable.
    AuctionConfig private _auctionConfig;
    
    StateLocks private _stateLocks;

    // @notice `_lineToState[i]` should only be mutable from the line `i`. 
    mapping(uint8 => LineState) private _lineToState;

    function initialize(
        address nftToAuction,
        uint8 lines,
        uint32 baseDuration,
        uint32 timeBuffer,
        uint96 startingPrice,
        uint96 bidIncrement
    ) external onlyOwner {
        require(!_stateLocks.initializationLocked); 
        _stateLocks.initializationLocked = true;

        require(bidIncrement > 0);

        _auctionConfig.auctionedNft = nftToAuction;
        _auctionConfig.lines = lines;
        _auctionConfig.baseDuration = baseDuration;
        _auctionConfig.timeBuffer = timeBuffer;
        _auctionConfig.startingPrice = startingPrice;
        _auctionConfig.bidIncrement = bidIncrement;
    }

    /* ------------- *\
    |* Bidding logic *|
    \* ------------- */
    /**
     * @dev Create a bid for a NFT, with a given amount.
     * This contract only accepts payment in ETH.
     */
    function createBid(uint24 nftId) public payable virtual {
        
        uint8 lineNumber = tokenIdToLineNumber(nftId);
        LineState storage line = _lineToState[lineNumber];
        IExternallyMintable token = IExternallyMintable(_auctionConfig.auctionedNft);
        
        if (!token.isMinter(address(this)))
            revert AuctionPaused();

        /* ---------- AUCTION UPDATING AND SETTLEMENT ---------- */
        if (block.timestamp > line.endTime) {
            if (!token.exists(line.head) && line.head > 0) _settleAuction(line);
            _updateLine(line, lineNumber);
        }

        if (line.head != nftId || nftId > token.maxSupply())
            revert WrongTokenId();
        
        /* ------------------ BIDDING LOGIC ------------------ */
        bool winnerExists = line.currentWinner != address(0);
        if (
            (!winnerExists && _auctionConfig.startingPrice > msg.value) ||
            (winnerExists && line.currentPrice + _auctionConfig.bidIncrement > msg.value)
        ) revert WrongBidAmount();

        if (line.currentPrice != 0)
            SafeTransferLib.forceSafeTransferETH(line.currentWinner, line.currentPrice);

        line.currentPrice = uint96(msg.value);
        line.currentWinner = msg.sender;

        emit Bid(nftId, msg.sender, msg.value);
        
        uint40 extendedTime = uint40(block.timestamp + _auctionConfig.timeBuffer);
        if (extendedTime > line.endTime)
            line.endTime = extendedTime;

    }

    function settleAuction(uint24 nftId) external {
        LineState memory line = _lineToState[tokenIdToLineNumber(nftId)];
        IExternallyMintable token = IExternallyMintable(_auctionConfig.auctionedNft);
        require(block.timestamp > line.endTime, "Auction still ongoing.");
        require(line.head != 0, "Auction not started.");
        require(!token.exists(nftId), "Token already settled.");
        _settleAuction(line);
    }

    function _settleAuction(LineState memory line) private {
        emit Won(line.head, line.currentWinner, line.currentPrice);
        address nftContract = _auctionConfig.auctionedNft;
        IExternallyMintable(nftContract).mint(line.head, line.currentWinner);
        payable(nftContract).transfer(line.currentPrice);
    }
    
    /**
     * @dev `line.head` will be the current token id auctioned at the
     * `line`. If is the first auction for this line (if `line.head == 0`)
     * then the token id should be the line number itself. Otherwise
     * increment the id by the number of lines. For more info about the 
     * second case check the `AuctionConfig.lines` doc.
     * @notice This function should be the only one allowed to change
     * `line.startTime`, `line.endTime` and `line.head` state, and it should
     * do so only when the dev is sure thats its time to auction the next
     * token id.
     */
    function _updateLine(LineState storage line, uint8 lineNumber) private {
        line.startTime = uint40(block.timestamp);
        line.endTime = uint40(block.timestamp + _auctionConfig.baseDuration);

        if (line.head == 0) line.head = lineNumber; 
        else {
            line.head += _auctionConfig.lines;
            line.currentPrice = 0;
            line.currentWinner = address(0);
        }
    }

    /* --------------------------- *\
    |* IAuctionInfo implementation *|
    \* --------------------------- */
    function getIdsToAuction() external view returns (uint24[] memory) {
        uint24[] memory ids = new uint24[](_auctionConfig.lines);
        for (uint8 i = 0; i < _auctionConfig.lines; i++) {
            LineState memory line = _lineToState[i+1];
            uint24 lineId = line.head;
            if (lineId == 0) lineId = i + 1;
            else if (block.timestamp > line.endTime) lineId += _auctionConfig.lines;
            ids[i] = lineId;
        }
        return ids;
    }

    function getAuctionedToken() external view returns (address) {
        return _auctionConfig.auctionedNft;
    }
    
    // TODO it should revert if `tokenId != expectedHead`
    function getMinPriceFor(uint24 tokenId) external view returns (uint96) {
        uint8 lineNumber = uint8(tokenId % _auctionConfig.lines);
        LineState memory line = _lineToState[lineNumber];
        if (block.timestamp > line.endTime) return _auctionConfig.startingPrice;
        else return line.currentPrice + _auctionConfig.bidIncrement;
    }
    

    /* -------------------------------------------- *\
    |* IHoldsParallelAutoAuctionData implementation *|
    \* -------------------------------------------- */
    function auctionConfig() external view returns (AuctionConfig memory) {
        return _auctionConfig;    
    }

    function lineState(uint24 tokenId) external view returns (LineState memory) {
        return _lineState(tokenId);
    }

    function lineStates() external view returns (LineState[] memory lines) {
        lines = new LineState[](_auctionConfig.lines);
        for (uint8 i = 0; i < _auctionConfig.lines; i++)
            lines[i] = _lineState(i+1);
    }
    
    function _lineState(uint24 tokenId) private view returns (LineState memory line) {
        uint8 lineNumber = tokenIdToLineNumber(tokenId);
        line = _lineToState[lineNumber];
        
        if (block.timestamp > line.endTime) {
            line.head += line.head == 0 ? lineNumber : _auctionConfig.lines;
            line.startTime = uint40(block.timestamp);
            line.endTime = uint40(block.timestamp + _auctionConfig.baseDuration);
            line.currentWinner = address(0);
            line.currentPrice = 0;
        }
    }

    /**
     * @return A value that will always be in {1, 2, ..., _auctionConfig.lines}.
     * So the returned value will always be a valid line number.
     */
    function tokenIdToLineNumber(uint24 tokenId) public view returns (uint8) {
        return uint8((tokenId - 1) % _auctionConfig.lines) + 1;
    }


    /* ----------------------------------- *\
    |* General contract state manipulation *|
    \* ----------------------------------- */
    /**
     * @dev Updating `baseDuration` will only affect to future auctions.
     */
    function setBaseDuration(uint32 baseDuration) external onlyOwner {
        if (_stateLocks.baseDurationLocked) revert OptionLocked();
        _auctionConfig.baseDuration = baseDuration;
    }

    /**
     * @dev Updating `timeBuffer` will only affect to future bufferings.
     */
    function setTimeBuffer(uint32 timeBuffer) external onlyOwner {
        if (_stateLocks.timeBufferLocked) revert OptionLocked();
        _auctionConfig.timeBuffer = timeBuffer; 
    }

    /**
     * @dev Updating `startingPrice` will only affect to future auctions.
     */
    function setStartingPrice(uint96 startingPrice) external onlyOwner {
        if (_stateLocks.startingPriceLocked) revert OptionLocked();
        _auctionConfig.startingPrice = startingPrice;
    }

    /**
     * @dev Updating `bidIncrement` will only affect to future increments.
     */
    function setBidIncrement(uint96 bidIncrement) external onlyOwner {
        if (_stateLocks.bidIncrementLocked) revert OptionLocked();
        _auctionConfig.bidIncrement = bidIncrement;
    }
    

    /* ---------------- *\
    |* Contract locking *|
    \* ---------------- */
    function lockBaseDurationForever() external onlyOwner {
        _stateLocks.baseDurationLocked = true;
    }

    function lockTimeBufferForever() external onlyOwner {
        _stateLocks.timeBufferLocked = true;
    }

    function lockStartingPriceForever() external onlyOwner {
        _stateLocks.startingPriceLocked = true;
    }

    function lockBidIncrementForever() external onlyOwner {
        _stateLocks.bidIncrementLocked = true;
    }
}