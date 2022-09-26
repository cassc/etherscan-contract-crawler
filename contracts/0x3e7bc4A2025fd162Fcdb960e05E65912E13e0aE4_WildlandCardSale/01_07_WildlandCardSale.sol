// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IWildlandCards.sol";

/**
 *  @title Wildland's Cards Sale
 *  Copyright @ Wildlands
 *  App: https://wildlands.me
 */

contract WildlandCardSale is Ownable {
    using SafeMath for uint256;
    // prices
    uint256 public wildPrice = 2 * 10 ** 16;
    uint256 public blackPrice = 8 * 10 ** 16;
    uint256 public goldPrice = 16 * 10 ** 16;
    uint256 public bitPrice = 48 * 10 ** 16;
    uint256 public salesStartTimestamp;
    uint256 public interval;
    uint256 public offset;

    IWildlandCards public wmc;
    address payable public sale_1;
    address payable public sale_2;
    
    mapping (uint256 => uint256) public affiliateCount;
    mapping (uint256 => uint256) public cardEarnings;
    
    event Interval(uint256 interval);
    event Offset(uint256 interval);
    
    /**
     * @notice Constructor
     */
    constructor(
        IWildlandCards _wmc,
        address payable _sale_1,
        address payable _sale_2
    ) {
        wmc = _wmc;
        sale_1 = _sale_1;
        sale_2 = _sale_2;
        salesStartTimestamp = 1665014400;
        interval = 7 days;
        offset = 24 hours;
    }

    function isCardAvailable(uint256 cardId) public view returns (bool) {
        return wmc.isCardAvailable(cardId);
    }

    function isSalesManAround() public view returns (bool) {
        if (block.timestamp < salesStartTimestamp)
            return false;
        // > block.timestamp

        // current sale index
        uint256 saleIndex = block.timestamp.sub(salesStartTimestamp).div(interval);
        // timestamp + interval * index + offset
        uint256 maxTimestampOpen = salesStartTimestamp.add(saleIndex.mul(interval)).add(offset);
        // check if max timestamp is greater than block timestamp
        return maxTimestampOpen >= block.timestamp;
    }    

    function saleOpenTimestamp() public view returns (uint256) {
        if (block.timestamp < salesStartTimestamp)
            return salesStartTimestamp;
        // current index
        uint256 saleIndex = block.timestamp.sub(salesStartTimestamp).div(interval);
        // return salesStartTimestamp + (saleIndex + 1) * interval (-> next sale at tis timestamp)
        return salesStartTimestamp.add(saleIndex.add(1).mul(interval));
    }

    function saleCloseTimestamp() public view returns (uint256) {
        if (block.timestamp < salesStartTimestamp){
            return 0;
        }
        // current index
        uint256 saleIndex = block.timestamp.sub(salesStartTimestamp).div(interval);
        // return salesStartTimestamp + (saleIndex + 1) * interval (-> next sale at tis timestamp)
        return salesStartTimestamp.add(saleIndex.mul(interval)).add(offset);
    }

    function timerToOpen() external view returns (uint256) {
        if (isSalesManAround())
            return 0;
        return saleOpenTimestamp().sub(block.timestamp);
    }

    function timerToClose() external view returns (uint256) {
        if (!isSalesManAround())
            return 0;
        return saleCloseTimestamp().sub(block.timestamp);
    }
    
    function setInterval(uint256 _interval) external onlyOwner {
        interval = _interval;
        emit Interval(_interval);
    }

    function setOffset(uint256 _offset) external onlyOwner {
        offset = _offset;
        emit Offset(_offset);
    }

    /// BUY Section

    fallback() external payable{
        buyCard(0, 0);
    }
    
    receive() external payable{
        buyCard(0, 0);
    }

    function buyCard(uint256 _cardId, bytes4 _code) public payable {
        require(isCardAvailable(_cardId), "buy: requested wmc card is sold out");
        require(_code == 0x0 || wmc.existsCode(_code), "affiliate: Invalid token id for non existing token");
        // check timestamp condition (true if timestamp was not set but fct did not return)
        require(isSalesManAround(), "Mint: The salesman of Wildlands is not around");
        // mint card and increment respective token id
        if (_code != 0x0 && wmc.existsCode(_code)) {
            // if valid affiliate code was 
            if (_cardId == 0)
                require (msg.value == wildPrice.mul(95).div(100), "buy 0: invalid purchase price");
            else if (_cardId == 1)
                require (msg.value == blackPrice.mul(95).div(100), "buy 1: invalid purchase price");
            else if (_cardId == 2)
                require (msg.value == goldPrice.mul(95).div(100), "buy 2: invalid purchase price");
            else if (_cardId == 3)
                require (msg.value == bitPrice.mul(95).div(100), "buy 3: invalid purchase price");
        }
        else {
            if (_cardId == 0)
                require (msg.value == wildPrice, "buy 0: invalid purchase price");
            else if (_cardId == 1)
                require (msg.value == blackPrice, "buy 1: invalid purchase price");
            else if (_cardId == 2)
                require (msg.value == goldPrice, "buy 2: invalid purchase price");
            else if (_cardId == 3)
                require (msg.value == bitPrice, "buy 3: invalid purchase price");
        }

        uint256 affiliateAmount = 0;
        // transfer sale + affiliate fee if applicable
        if (_code != 0x0) {
            uint256 tokenId = wmc.getTokenIdByCode(_code);
            uint256 feeBP = getAffiliateBasePoints(tokenId);
            affiliateAmount = msg.value.mul(feeBP).div(100);
            // transfer affiliate amount to owner of nft
            address payable addr = payable(wmc.ownerOf(tokenId));
            addr.transfer(affiliateAmount);
            // update earnings + affiliate counter
            cardEarnings[tokenId] = cardEarnings[tokenId].add(affiliateAmount);
            affiliateCount[tokenId] = affiliateCount[tokenId].add(1);
        }
        // remaining sale price to be transferred
        uint256 salePrice = msg.value.sub(affiliateAmount);
        // 50% of sale price goes to ...
        uint256 salePrice_1 = salePrice.div(2);
        sale_1.transfer(salePrice_1);
        // rest goes to
        sale_2.transfer(salePrice.sub(salePrice_1));
        // mint card id
        wmc.mint(msg.sender, _cardId);
    }

    function setPurchasePrice(uint256 _wildPrice, uint256 _blackPrice, uint256 _goldPrice, uint256 _bitPrice) public onlyOwner {
        require (_wildPrice > 0 && _blackPrice > 0 && _goldPrice > 0 && _bitPrice > 0, "setPrice: invalid price - cannot be zero");
        wildPrice = _wildPrice;
        blackPrice = _blackPrice;
        goldPrice = _goldPrice;
        bitPrice = _bitPrice;
    }

    function setSale(address payable _sale_1, address payable _sale_2) public onlyOwner {
        require (_sale_1 != address(0), "setSale: invalid address 1");
        require (_sale_2 != address(0), "setSale: invalid address 2");
        sale_1 = _sale_1;
        sale_2 = _sale_2;
    }

    function getCardIndex(uint256 _cardID) public view returns (uint256) {
        return wmc.cardIndex(_cardID);
    }

    function getCardPrice(uint256 _cardID) public view returns (uint256) {
        if (_cardID == 0)
            return wildPrice;
        else if (_cardID == 1) {
            // BIT CARD MEMBER
            return blackPrice;
        }
        else if (_cardID == 2) {
            // GOLD CARD MEMBER
            return goldPrice;
        }
        else if (_cardID == 3) {
            // BLACK CARD MEMBER
            return bitPrice;
        }
        return 0;
    }

    // the affilite mechansims has 4 levels (3 VIP WMC and 1 standard). 
    // affiliates get a portion of the fees based on the member level. 
    // there are 1000 VIP VMC MEMBER CARDS (id 1 - 1000) and INFINTITY STANDARD MEMBER CARDS (1001+)
    function getAffiliateBasePoints(uint256 _tokenId) public pure returns (uint256) {
        // check affiliate id
        if (_tokenId == 0)
            return 0;
        else if (_tokenId <= 100) {
            // BIT CARD MEMBER
            return 20; // 20 %
        }
        else if (_tokenId <= 400) {
            // GOLD CARD MEMBER
            return 15; // 15 %
        }
        else if (_tokenId <= 1000) {
            // BLACK CARD MEMBER
            return 10; // 10 %
        }
        // WILD LANDS MEMBER CARD
        return 5; // 5 %
    }
}