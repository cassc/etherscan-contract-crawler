// SPDX-License-Identifier: GPL-3.0

/// @title The Nouns referral system contract (by Social Nouns)

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { INounsToken } from './interfaces/INounsToken.sol';
import { IWETH } from './interfaces/IWETH.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { INounsAuctionHouse} from './interfaces/INounsAuctionHouse.sol';

contract NounsAuctionReferral {
    // The address of the WETH contract
    address public weth;
    // The address of the contract admin
    address public admin;
    // The address of the pendingAdmin
    address public pendingAdmin;
    // The address of Nouns DAO Treasury
    address payable public socialNounsDAO;
    // The Nouns Token
    INounsToken public socialNounsTokenInterface;
    // The Auction House
    INounsAuctionHouse internal immutable auction;
    
    // The Struct for last bid
    struct lastBid {
        // ID for the Noun (ERC721 token ID)
        uint256 nounId;
        // The current highest bid amount
        uint256 amount;
        // The address of the current highest bid
        address payable bidder;
        // Referall code for the recipient
        address payable referral;
    }
    // The last bid
    lastBid public LastBid;

    // auction house reserve price
    uint256 reservePrice;
    // min bid increment
    uint8 minBidIncrementPercentage;
    // share in % that the referals get
    uint8 share;
    // state of initialize
    bool init = false;
    

    /**
     * @notice constructor of the contract,
     * set admin and auction.
     * @dev This function can only be called once.
     */
    constructor(address _admin,INounsAuctionHouse _auction) {
        admin = _admin;
        auction = _auction;
    }


    /**
     * @notice Initialize the contract,
     * populate configuration values.
     * @dev This function can only be called once.
     */
    function initialize(address socialNounsToken_,address socialNounsDAO_,uint8 share_,address weth_,uint256 reservePrice_,uint8 minBidIncrementPercentage_) public virtual{
        require(init == false, 'NounsAuctionReferral::initialize: can only initialize once');
        require(msg.sender == admin, 'NounsAuctionReferral::initialize: admin only');
        require(socialNounsToken_ != address(0), 'NounsAuctionReferral::initialize: invalid nouns address');
        require(share_ > 0, 'NounsAuctionReferral::initialize: share cant be 0');
        socialNounsTokenInterface = INounsToken(socialNounsToken_);
        share = share_;
        weth = weth_;
        reservePrice = reservePrice_;
        minBidIncrementPercentage = minBidIncrementPercentage_;
        init = true;
        socialNounsDAO = payable(socialNounsDAO_);
    }


    /**
     * @notice Get the current auction.
     */
    function returnAuction() public view returns (uint256,uint256,uint256){
    (uint256 id, uint256 amount,, uint256 endTime,,) = auction.auction();
       return (id,amount,endTime);
    }


    /**
     * @notice Create a bid for a Noun, with a given amount.
     * @dev This contract only accepts payment in ETH, reverts if referralNounID is non existing
     */
    function createBid(uint256 nounId_,uint256 referralNounsID_) external payable {
        (uint256 nounid, uint256 amount,, uint256 endTime,,) = auction.auction();
        require(nounid == nounId_, 'Social Noun not up for auction');
        require(block.timestamp < endTime, 'Auction expired');
        require(referralNounsID_ < nounId_, 'Auction for this social noun has not ended yet');
        require(msg.value >= reservePrice, 'Must send at least reservePrice');
        require(address(this).balance >= ((msg.value * share) / 100), 'Contract balance to low');
        require(
            msg.value >= amount + ((amount * minBidIncrementPercentage) / 100),
            'Must send more than last bid by minBidIncrementPercentage amount'
        );
        
        if(nounId_ > LastBid.nounId && LastBid.nounId != 0){
            if(socialNounsTokenInterface.balanceOf(address(this)) > 0){
                withdrawNoun();
            }
        }

        address payable lastBidder = LastBid.bidder;

        if (lastBidder != payable(0)) {
            _safeTransferETHWithFallback(lastBidder, LastBid.amount);
        }    
        
        address payable referral = payable(socialNounsTokenInterface.ownerOf(referralNounsID_));

        try auction.createBid{value: msg.value}(nounId_) {
                LastBid.nounId = nounId_;
                LastBid.amount = msg.value;
                LastBid.bidder = payable(msg.sender);
                LastBid.referral = referral;
        }catch Error(string memory) {
                
        }
    }


    /**
     * @notice Transfer Noun. If the auction pauses or noone bids use this function to withdraw Noun
     */
    function withdrawNoun() public{
        require(socialNounsTokenInterface.balanceOf(address(this)) > 0, 'Nothing to withdraw');
        require(LastBid.nounId != 0, 'Last Bid is empty');

        socialNounsTokenInterface.transferFrom(address(this), LastBid.bidder, LastBid.nounId);

        address payable referral = LastBid.referral;

        if (referral != payable(0)) {
            _safeTransferETHWithFallback(referral, ((LastBid.amount * share) / 100));
        }
        LastBid.nounId = 0;
        LastBid.amount = 0;
        LastBid.bidder = payable(0);
        LastBid.referral = payable(0);
    }
    /**
     * @notice Transfer contract fund to Social Nouns DAO
     */
    function transferFundsToNounsDAO() public {
         require(msg.sender == admin, 'NounsAuctionReferral::initialize: admin only');
         require(address(this).balance > 0, 'NounsAuctionReferral::initialize: Balance is to low');
         _safeTransferETHWithFallback(socialNounsDAO, address(this).balance);
    }

    /**
     * @notice Settle auction and transfer noun
     */
    function settleCurrentAndCreateNewAuction() public{
        (,,, uint256 endTime,,) = auction.auction();
        require(block.timestamp >= endTime, "Auction hasn't completed");
        try auction.settleCurrentAndCreateNewAuction(){
        if(socialNounsTokenInterface.balanceOf(address(this)) > 0 && LastBid.nounId != 0){
            withdrawNoun();
        }} catch Error(string memory){

        }
    }


    /**
     * @notice Transfer ETH. If the ETH transfer fails, wrap the ETH and try send it as WETH.
     */
    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            IWETH(weth).deposit{ value: amount }();
            IERC20(weth).transfer(to, amount);
        }
    }
    /**
     * @notice Transfer ETH and return the success status.
     * @dev This function only forwards 30,000 gas to the callee.
     */
    function _safeTransferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{ value: value, gas: 30_000 }(new bytes(0));
        return success;
    }
    /**
     * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @param newPendingAdmin New pending admin.
     */
    function _setPendingAdmin(address newPendingAdmin) external {
        // Check caller = admin
        require(msg.sender == admin, 'NounsAuctionReferral::_setPendingAdmin: admin only');
        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;
    }

    /**
     * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
     * @dev Admin function for pending admin to accept role and update admin
     */
    function _acceptAdmin() external {
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
        require(msg.sender == pendingAdmin && msg.sender != address(0), 'NounsAuctionReferral::_acceptAdmin: pending admin only');

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);
    }
    receive() external payable {}
}