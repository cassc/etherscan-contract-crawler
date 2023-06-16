// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./GenkiMint.sol";

/**
* @author @inetdave
* @dev v.01.00.00
*/
contract GenkiBid is GenkiMint{

    uint256 public constant MIN_BID = 0.04 ether;

    event Bid(
        address bidder,
        uint256 bidAmount,
        uint256 bidderTotal,
        uint256 biddingTotal
    );
  
    
    struct Bidder {
        /**
        * @dev  cumulative sum of ETH bids. this is useful incase bidders are increasing their bid
        */
        uint224 contribution; 
        /**
        * @dev  tracker for claimed tokens
        */
        uint16 tokensClaimed; 
        /**
        * @dev  has user been refunded yet
        */
        bool refundClaimed; 
        /**
        * @dev  process winning bid offchain and set with setWinningBids
        */
        bool winningBid;
    }

    /**
    * @dev  store the bidder per address.
    */
    mapping(address => Bidder) public bidderData;

    /**
     * @notice place a bid in ETH or add to your existing bid. Calling this
     *   multiple times will increase your bid amount. All bids placed are final
     *   and cannot be reversed.
     */
    function bid() external payable {
        require(contractState == ContractState.BID, "Bid not active");
        Bidder storage bidder = bidderData[msg.sender]; 
        uint256 contribution = bidder.contribution; // get user's current bid total
        unchecked {
            // does not overflow
            contribution += msg.value;
        }
        require(contribution >= MIN_BID, "Bid low");
        bidder.contribution = uint224(contribution);
        emit Bid(msg.sender, msg.value, contribution, address(this).balance);
    }

    /**
     * @notice process a bidder based on an address
     * @dev after bidding is stopped and price is set. run processBiddersFromBatch to handle the airdrop and refund from a array of addresses
     * calldata is used.
     * if for some reason the refund fails you will need to manually call send tokens to address
     * the algorithm must take into account timing of the bid incase there are duplicate bids and maxBidSupply is exceeded
     * if the bidder has a winning bid but the max supply is already out then we need to refund them their full contribution
     *
     * there is no max on bids. 
     * step 0: off-chain we will calculate the winning bid amount and winners
     * step 1: update bidderData if the user is a winner
     * step 2: process based on the winner flag
     * step 3: continue in this way until maxBidSupply is met
     * @param _address address to process
     */

    function _processBidder(address _address) internal virtual{

        //process refunds first
        Bidder storage bidder = bidderData[_address];

        uint256 totalWon = _totalWonFromBidding(bidder.contribution, bidder.winningBid);
        require(maxBidSupply >= _totalMinted()+totalWon, "Exceeded mint bid supply");
        require(!bidderData[_address].refundClaimed, "Already refunded");
        bidder.refundClaimed = true;

        uint256 refundValue = _refundAmount(_address);

        //if the bidder is not a winning bid then refund completely
        if (!bidder.winningBid){
            refundValue = bidder.contribution;
        }

        (bool success, ) = _address.call{value: refundValue}("");
        require(success, "Refund failed");
            
        //airdrop tokens
        if (totalWon > 0) {
            require(bidder.tokensClaimed == 0, "Already airdropped");
            bidder.tokensClaimed = uint16(totalWon);
            _airdropMint(_address, totalWon);
        }
    }

   /**
     * @notice process refunds incase the refunds from processBidders was unsuccessful
     */
    function _processBidderRefunds(address _address, uint256 _sendRefundAmount) internal{
        Bidder storage bidder = bidderData[_address];
        bidder.refundClaimed = true;

        (bool success, ) = _address.call{value: _sendRefundAmount}("");

        require(success, "Refund failed");
    }
    /**
     * @notice get the refund amount for an account, after the clearing price
     *   has been set.
     * @dev helper function. 
     * @param _bidderAddress address to query.
     */
    function _refundAmount(address _bidderAddress) internal view
        returns (uint256)
    {
        return bidderData[_bidderAddress].contribution % price;
    }

    /**
     * @notice based on the price set figure out how many tokens the user gets.
     * @dev helper function
     */
    function _totalWonFromBidding(uint256 _contribution, bool _winningBid ) internal view
        returns (uint256)
    {
        if (_winningBid)
            return _contribution / price;
        else{
            return 0;
        }
    }
}