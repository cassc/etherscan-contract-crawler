// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// set MINTED as true on candyShop -- and check if user has already minted.

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/interfaces/IERC1363.sol";
import "@openzeppelin/contracts/interfaces/IERC1363Receiver.sol";

interface CandiesNFT {
    function mint(address _to) external;
    function remaining() external view returns (uint256);
}

interface ICandyShop {
    function maxMints() external view returns (uint);
    function numMinted(address _addr) external view returns (uint);
    function increaseMintedCount(address _addr, uint _count) external;
}

contract CandyAuction is Ownable, Pausable {

    struct Bid {
        address wallet;
        uint value;
    }

    IERC1363 public immutable token;
    CandiesNFT public candies;
    ICandyShop public candyshop;

    uint public duration = 1 weeks;
    uint public maxWinners = 10;
    uint public startTime;
    Bid[] public bids;

    address beneficiary;   

    event NewHighBidder(address, uint amount);
    event UpdatedOrder(address, uint amount);
    event Claimed(address, uint amount);

    constructor() {
        // Goerli
        // candies = CandiesNFT(0xA3FF22Df8905CC93B741f7C7B45390B2E834B019);   
        // token = IERC1363(0xf46AbB1865Fbef39c2a02B33C0EBAE2Fb9E897AB);     
        // candyshop = ICandyShop(0x9037c7fcF8af61D11Bb6F6Fb132997A4B992bb7c);
         // Mainnet
        candies = CandiesNFT(0x832DE117D8fA309B55F9C187475a17B87b9dFc85);  
        token = IERC1363(0x78b5C6149C87c82EDCffC73C230395abbc56DdD5);    
        candyshop = ICandyShop(0xB9Fc2B1631c6b911D2f06FF790881A23AF93CE8f);  
        beneficiary = msg.sender; 
        startNow(); // for testing
    }

    function claim(address _to) public whenNotPaused {
        require(ended(), "Auction not done");
        require(isHighBidder(_to), "Not high bidder");
        uint _index = highBidderIndex(_to);
        uint _winningBid = bids[_index].value;
        bids[_index] = Bid(address(0), 0);
        candyshop.increaseMintedCount(_to,1);
        candies.mint(_to);
        emit Claimed(_to, _winningBid);
    }

    function onTransferReceived(address operator, address from, uint256 value, bytes memory data) external whenNotPaused returns (bytes4) {
        require(msg.sender == address(token), "not correct sender");
        require(started(), "Auction not started");
        require(!ended(), "Auction over");
        require(value > bids[0].value, "Bid not high enough");
        require(candyshop.numMinted(from) < candyshop.maxMints(), "Already minted max candies");
        if (isHighBidder(from)) {           // User is already top bidder
            uint _index = highBidderIndex(from);
            require(value > bids[_index].value, "New bid is not higher than old bid");
            uint _oldBid = bids[_index].value;
            bids[_index].value = value;
            updateOrder();
            token.transfer(from, _oldBid);  // REFUND old amount
        } else {                            // User is new top bidder
            if (bids[0].value > 0) {
                token.transfer(bids[0].wallet, bids[0].value); // Refund low bidder
            }
            bids[0] = Bid(from,value);
            updateOrder();
            emit NewHighBidder(from, value);
        }
        return IERC1363Receiver.onTransferReceived.selector; // Return magic value
    }

    function updateOrder() public {
        for (uint i = 0; i < maxWinners - 1;i++) {
            if (bids[i].value > bids[i + 1].value) {
                Bid memory _temp = bids[i];
                bids[i] = bids[i+1];
                bids[i+1] = _temp;
            }
        }
    }

    function check(uint _index) public view returns (bool) {
        return bids[_index].value > 0;
    }

// View

    function timeNow() public view returns (uint) {
        return block.timestamp;
    }

    function endTime() public view returns (uint) {
        return startTime + duration;
    }

    function allHighBidders() public view returns (Bid[] memory) {
        Bid[] memory _bids = new Bid[](maxWinners);
        for (uint i = 0; i < maxWinners;i++) {
            _bids[i] = bids[i];
        }
        return _bids;
    }

    function started() public view returns (bool) {
        return startTime == 0 ? false : block.timestamp > startTime;
    }

    function ended() public view returns (bool) {
        return (block.timestamp > startTime + duration);
    }

    function isHighBidder(address _addr) public view returns (bool) {
        for (uint i = 0; i < maxWinners; i++) {
            if (bids[i].wallet == _addr)
                return true;
        }
        return false;
    }

    function highBidderIndex(address _addr) public view returns (uint) {
        for (uint i = 0; i < maxWinners; i++) {
            if (bids[i].wallet == _addr)
                return i;
        }
        revert(string(abi.encodePacked(_addr, " not found in high bidders.")));
    }

// Admin

    function reset(uint _maxWinners) public onlyOwner {
        resetArray();
        maxWinners = _maxWinners;
        startTime = 0;
    }

    function startNow() public onlyOwner {
        resetArray();
        startTime = block.timestamp;
    }

    function setDuration(uint _timeInSeconds) public onlyOwner {
        duration = _timeInSeconds;
    }

    function setEndTime(uint _endtime) public onlyOwner {
        duration = _endtime - startTime;
    }

    function setMaxWinners(uint _max) public onlyOwner {
        require(!started(), "Already started");
        maxWinners = _max;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setCandyShop(address _addr) public onlyOwner {
        candyshop = ICandyShop(_addr);
    }

// Internal

    function resetArray() internal {
        Bid memory _empty = Bid(address(0), 0);
        for (uint i = 0; i < maxWinners; i++) {
            bids.push(_empty); 
        }
    }

}