// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ChubbiReserve.sol";

/**
 * @title ChubbiAuction
 * ChubbiAuction - A contract that enables tokens to be distributed using a Dutch Auction.
 */
contract ChubbiAuction is ChubbiReserve {
    using SafeMath for uint256;

    bool internal _isAuctionActive;

    // Events
    event BidSuccessful(
        address indexed owner,
        uint256 amountOfTokens,
        uint256 totalPrice
    );

    // Auction parameters
    uint256 public startTime;
    uint256 public maxPrice;
    uint256 public minPrice;

    // The amount of time after price will decrease next.
    uint256 public constant timeDelta = 10 minutes;

    // The amount of eth to decrease price by every `timeDelta`
    uint256 public constant priceDelta = 0.05 ether;

    // The maximum amount of tokens per bid
    uint256 public maxTokensPerBid;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress,
        uint256 _maxSupply
    ) ChubbiReserve(_name, _symbol, _proxyRegistryAddress, _maxSupply) {
        _isAuctionActive = false;
        maxTokensPerBid = 20;
        maxPrice = 0.69 ether;
        minPrice = 0.09 ether;
    }

    /**
     * @dev Set the parameters for the auction.
     * @param _maxPrice the maximum price of a token in the auction.
     * @param _minPrice the minimum price of a token in the auction.
     */
    function setAuctionParameters(uint256 _maxPrice, uint256 _minPrice)
        external
        onlyOwner
    {
        require(!_isAuctionActive, "Auction is active");
        require(_maxPrice > _minPrice, "Invalid max price");
        require(_minPrice > 0, "Invalid min price");
        maxPrice = _maxPrice;
        minPrice = _minPrice;
    }

    /**
     * @dev Set the maximum number of tokens a user is allowed to bid for in total throughout the whole auction.
     */
    function setMaxTokensPerBid(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Invalid amount");
        maxTokensPerBid = _amount;
    }

    // Start & Pause

    function startAuction() external onlyOwner whenNotPaused {
        require(!_isAuctionActive, "Auction is active");
        startTime = block.timestamp;
        _isAuctionActive = true;
        stopReservations();
    }

    function pauseAuction() external onlyOwner {
        require(_isAuctionActive, "Auction is not active");
        _isAuctionActive = false;
    }

    // Bidding

    /**
     * @dev Get the maximum amount of tokens that can be auctioned.
     */
    function maxAuctionSupply() public view returns (uint256) {
        return maxSupply - claimed;
    }

    /**
     * @dev Get the amount of tokens that have been auctioned.
     */
    function tokensAuctioned() public view returns (uint256) {
        return currentSupply() - claimed;
    }

    /**
     * @dev Check is the auction is currently active.
     */
    function isAuctionActive() external view returns (bool) {
        return _isAuctionActive && tokensAuctioned() < maxAuctionSupply();
    }

    /**
     * @dev Bid for tokens.
     * @param _tokenAmount the amount of tokens to bid.
     */
    function bid(uint256 _tokenAmount) external payable whenNotPaused {
        require(_isAuctionActive, "Auction is not active");
        require(tokensAuctioned() < maxAuctionSupply(), "Auction completed");
        require(_tokenAmount <= maxTokensPerBid, "Bid limit exceeded");

        // Ensure that user can always buy the tokens closer to the end of the auction
        uint256 tokensRemaining = maxAuctionSupply().sub(tokensAuctioned());
        uint256 amountToBuy = Math.min(_tokenAmount, tokensRemaining);
        assert(amountToBuy <= tokensRemaining);

        // Ensure user can afford the tokens
        uint256 totalPrice = getCurrentPrice().mul(amountToBuy);
        require(totalPrice <= msg.value, "Not enough ETH");

        // Give them the tokens!
        for (uint256 i = 0; i < amountToBuy; i++) {
            _mintTo(msg.sender);
        }

        // Let the world know!
        emit BidSuccessful(msg.sender, amountToBuy, totalPrice);

        // Return the change
        uint256 change = msg.value.sub(totalPrice);
        payable(msg.sender).transfer(change);
    }

    /**
     * @dev Get the current price of a token.
     */
    function getCurrentPrice() public view returns (uint256) {
        if (!_isAuctionActive) {
            return maxPrice;
        }
        return _getCurrentPrice(startTime, block.timestamp, maxPrice, minPrice);
    }

    /**
     * @dev Get the current price of a token.
     * We make this virtual so we can override it in tests.
     * @param _startTime the starting timestamp.
     * @param _currentTime the current timestamp.
     * @param _maxPrice the maximum price of the token.
     * @param _minPrice the minimum price of the token.
     */
    function _getCurrentPrice(
        uint256 _startTime,
        uint256 _currentTime,
        uint256 _maxPrice,
        uint256 _minPrice
    ) internal view virtual returns (uint256) {
        require(_maxPrice > _minPrice, "Invalid max price");
        if (_currentTime < _startTime) {
            return _maxPrice;
        }
        // Drop by 0.05 eth every 10 minutes
        uint256 priceDiff = _currentTime.sub(_startTime).div(timeDelta).mul(
            priceDelta
        );
        priceDiff = Math.min(priceDiff, _maxPrice);
        return Math.max(_minPrice, _maxPrice.sub(priceDiff));
    }
}