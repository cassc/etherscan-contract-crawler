// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { SafeERC20 } from "../../lib/openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { FixedPointMathLib } from "../../lib/solmate/src/utils/FixedPointMathLib.sol";
import { IERC1155 } from "../../lib/openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { Ownable } from "../../lib/openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "../../lib/openzeppelin/contracts/security/ReentrancyGuard.sol";

import { IWhitelist } from "../interfaces/IWhitelist.sol";
import { IBatchAuctionSeller } from "../interfaces/IBatchAuctionSeller.sol";
import { IERC20 } from "../interfaces/IERC20.sol";
import "../interfaces/IBatchAuction.sol";

import "../libraries/BatchAuctionQ.sol";
import "../libraries/Errors.sol";

/**
 * @title HashnoteBatchAuction
 * @notice The batch auction is designed for a seller to be able to list and sell multiple options at once as a structure. An auction is created for some period
 * in which bidders will be able to place bids on the available structures. Placing a bid may require the bidder to pay or receive a premium and post collateral, depending on the price.
 * When the auction has ended and has been settled, the premium and collateral collected is transferred to the seller, which will then be used to mint the various options within each of the structures sold.
 *
 * After settlement, any users who had successful bids will be able to claim the options their entitled to within each structure, and a partial premium refund paying the difference between their bid price
 * and the clearing price. Those users who only had partly successful bids, or completely unsuccessful bids will have those bids premium & collateral returned.
 */
contract HashnoteBatchAuction is Ownable, ReentrancyGuard {
    using FixedPointMathLib for uint256;
    using BatchAuctionQ for BatchAuctionQ.Queue;
    using SafeERC20 for IERC20;

    /*///////////////////////////////////////////////////////////////
                                Constants
    //////////////////////////////////////////////////////////////*/

    // Each option token within grappa has a precision of 10^6
    uint256 internal constant UNIT = 10 ** 6;

    /*///////////////////////////////////////////////////////////////
                                Storage
    //////////////////////////////////////////////////////////////*/

    // Counter to keep track number of auctions
    uint256 public auctionsCounter;

    // Mapping of auction details for a given auctionId
    mapping(uint256 => IBatchAuction.Auction) public auctions;

    // Mapping of auction bid queue for a given auctionId
    mapping(uint256 => BatchAuctionQ.Queue) internal queues;

    IWhitelist public whitelist;

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    event NewAuction(
        uint256 auctionId,
        address seller,
        address optionTokenAddr,
        uint256[] optionTokens,
        address biddingToken,
        IBatchAuction.Collateral[] collaterals,
        int256 minPrice,
        uint256 minBidSize,
        uint256 totalSize,
        uint256 endTime
    );

    event NewBid(uint256 indexed auctionId, address indexed bidder, uint256 bidId, uint256 quantity, int256 price);

    event CanceledBid(uint256 indexed auctionId, address indexed bidder, uint256 bidId, uint256 quantity, int256 price);

    event Settled(uint256 auctionId, uint256 totalSold, int256 clearingPrice);

    event Claimed(uint256 indexed auctionId, address indexed bidder, uint256 bidId, uint256 quantity, int256 price);

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor() { }

    /*///////////////////////////////////////////////////////////////
                        External Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the whitelist contract
     * @param _whitelist is the address of the new whitelist
     */
    function setWhitelist(address _whitelist) external {
        _onlyOwner();

        whitelist = IWhitelist(_whitelist);
    }

    /**
     *  @notice Allows a seller to create an auction with the given parameters
     *  @param _optionTokenAddr the option token address
     *  @param _optionTokens list of tokens ids within the structure being minted. Each id contains serialized information about the option
     *  @param _biddingToken in which premiums will be paid for the structure
     *  @param _collaterals that may be required to be posted by the bidder in order to mint the structures
     *  @param _minPrice which a bid will be accepted by the auction. If the bid is positive, the bidder will pay the premium, if it's negative, the seller will pay the premium
     *  @param _minBidSize minimum amount of structures a user can bid for
     *  @param _totalSize amount of structures being listed for auction
     *  @param _endTime end of the auction
     *  @param _whitelist only approved bidders can enter and claim their proceeds
     *  @return auctionId generated for this auction
     */
    function createAuction(
        address _optionTokenAddr,
        uint256[] calldata _optionTokens,
        address _biddingToken,
        IBatchAuction.Collateral[] calldata _collaterals,
        int256 _minPrice,
        uint256 _minBidSize,
        uint256 _totalSize,
        uint256 _endTime,
        address _whitelist
    ) external returns (uint256 auctionId) {
        _checkSellerPermissions();

        if (_optionTokenAddr == address(0)) revert BA_BadOptionAddress();
        if (_optionTokens.length == 0) revert BA_BadOptions();
        if (_biddingToken == address(0)) revert BA_BadBiddingAddress();
        if (_minBidSize > _totalSize) revert BA_BadSize();
        if (_endTime <= block.timestamp) revert BA_BadTime();
        if (_totalSize == 0) revert BA_BadSize();
        if (_minBidSize == 0) revert BA_BadSize();

        auctionId = auctionsCounter += 1;

        for (uint256 i; i < _collaterals.length;) {
            if (_collaterals[i].addr == address(0)) revert BA_BadCollateral();
            if (_collaterals[i].amount == 0) revert BA_BadAmount();

            // No duplicate collaterals
            for (uint256 j = i + 1; j < _collaterals.length;) {
                if (_collaterals[i].addr == _collaterals[j].addr) {
                    revert BA_BadCollateral();
                }

                unchecked {
                    ++j;
                }
            }

            auctions[auctionId].collaterals.push(_collaterals[i]);

            unchecked {
                ++i;
            }
        }

        auctions[auctionId].seller = msg.sender;
        auctions[auctionId].optionTokenAddr = _optionTokenAddr;
        auctions[auctionId].optionTokens = _optionTokens;
        auctions[auctionId].biddingToken = _biddingToken;
        auctions[auctionId].minPrice = _minPrice;
        auctions[auctionId].minBidSize = _minBidSize;
        auctions[auctionId].totalSize = _totalSize;
        auctions[auctionId].availableSize = _totalSize;
        auctions[auctionId].endTime = _endTime;
        auctions[auctionId].whitelist = _whitelist;

        emit NewAuction(
            auctionId,
            msg.sender,
            _optionTokenAddr,
            _optionTokens,
            _biddingToken,
            _collaterals,
            _minPrice,
            _minBidSize,
            _totalSize,
            _endTime
            );
    }

    /**
     * @notice Allows a user to bid on a structure listed at a particular auction. Any collaterals and premiums will be withdrew from the bidder depending upon the quantity. If the price is negative,
     * then only collaterals will be taken as it will be the seller paying the premium instead.
     * @param auctionId of the auction they wish to place the bid
     * @param quantity quantity The number of structures the user wishes to bid for
     * @param price The positive price is how much the bidder is willing to pay, the negative price how much the bidder is willing to be paid
     */
    function placeBid(uint256 auctionId, uint256 quantity, int256 price) external nonReentrant {
        // Only whitelisted accounts can place a bid
        _checkBidderPermissions(auctionId);

        IBatchAuction.Auction storage auction = auctions[auctionId];

        if (auction.totalSize == 0) revert BA_Uninitialized();
        if (block.timestamp >= auction.endTime) revert BA_AuctionClosed();
        if (quantity < auction.minBidSize) revert BA_BadAmount();
        if (price < auction.minPrice) revert BA_BadPrice();

        BatchAuctionQ.Queue storage queue = queues[auctionId];

        uint256 bidId = queue.insert(msg.sender, price, quantity);

        // transfer collateral to auction if the bid is positive, any premiums from successful negative price bids will be paid upon claiming after the auction has settled
        if (price > 0) {
            _transferPremium(auction.biddingToken, msg.sender, address(this), price, quantity);
        }

        // transfer total collateral for the required structures to the auction
        _transferCollateral(auction.collaterals, address(this), quantity);

        emit NewBid(auctionId, msg.sender, bidId, quantity, price);
    }

    /**
     * @notice Allows a user to cancel their bid within an auction and receive the initial premium & collateral paid
     * @param auctionId the auction to remove the bid
     * @param bidId to be canceled
     */
    function cancelBid(uint256 auctionId, uint256 bidId) external {
        // Only whitelisted accounts can remove bid
        _checkBidderPermissions(auctionId);

        IBatchAuction.Auction storage auction = auctions[auctionId];
        BatchAuctionQ.Queue storage queue = queues[auctionId];

        // check sender is the owner
        if (msg.sender != queue.bidOwnerList[bidId]) revert BA_Unauthorized();
        // check if auction already closed
        if (block.timestamp >= auction.endTime) revert BA_AuctionClosed();

        // grab these values into memory before wiping them
        uint256 quantity = queue.bidQuantityList[bidId];
        int256 price = queue.bidPriceList[bidId];

        // remove from queue, delets from bidOwnerList, so can not be repeated
        queue.remove(bidId);

        // refund premium
        if (price > 0) {
            _transferPremium(auction.biddingToken, address(this), msg.sender, price, quantity);
        }

        // refund collateral
        _transferCollateral(auction.collaterals, msg.sender, quantity);

        emit CanceledBid(auctionId, msg.sender, bidId, quantity, price);
    }

    /**
     * @notice Allows auction to be settled, transferring any premiums and collaterals collected to the seller
     * @param auctionId of the auction to to be settled
     * @return clearingPrice the auction was cleared at, which is the cheapest filled bid price
     * @return totalSold the total number of structures sold
     */
    function settleAuction(uint256 auctionId) external nonReentrant returns (int256 clearingPrice, uint256 totalSold) {
        IBatchAuction.Auction storage auction = auctions[auctionId];

        uint256 totalSize = auction.availableSize;

        if (totalSize == 0) revert BA_EmptyAuction();
        if (block.timestamp < auction.endTime) revert BA_AuctionNotClosed();
        if (auction.settled) revert BA_AuctionSettled();

        BatchAuctionQ.Queue storage queue = queues[auctionId];

        auction.settled = true;

        address seller = auction.seller;

        if (queue.bidOwnerList.length > 0) {
            (totalSold, clearingPrice) = queue.computeFills(totalSize);
        }

        if (totalSold > 0) {
            auction.availableSize -= totalSold;

            address sender = address(this);
            address recipient = seller;

            if (clearingPrice < 0) {
                sender = seller;
                recipient = address(this);
            }

            // proceeds are equal to fill amount times clearing price
            if (clearingPrice != 0) {
                _transferPremium(auction.biddingToken, sender, recipient, clearingPrice, totalSold);
            }

            //transfer the collateral from the successfully filled bids to the seller
            _transferCollateral(auction.collaterals, seller, totalSold);
        }

        emit Settled(auctionId, totalSold, clearingPrice);

        IBatchAuctionSeller(auction.seller).settledAuction(auctionId, totalSold, clearingPrice);
    }

    /**
     *  @notice Claims any proceeds and refunds from the auction
     *  @param auctionId the auction to claim the proceeds
     */
    function claim(uint256 auctionId) external nonReentrant {
        // Only whitelisted accounts can claim winnings
        _checkBidderPermissions(auctionId);

        IBatchAuction.Auction storage auction = auctions[auctionId];

        if (!auction.settled) revert BA_AuctionUnsettled();

        BatchAuctionQ.Queue storage queue = queues[auctionId];

        int256 clearingPrice = queue.clearingPrice;

        uint256 totalPremiumRefund;
        uint256 totalCollateralRefund;
        uint256 totalFilled;

        uint256 bidOwnerListLength = queue.bidOwnerList.length;

        for (uint256 i; i < bidOwnerListLength;) {
            // only loop through this user's bids
            if (queue.bidOwnerList[i] == msg.sender) {
                int256 price = queue.bidPriceList[i];
                uint256 quantity = queue.bidQuantityList[i];
                uint256 fill = queue.filledAmount[i];

                // if bid wins
                if (fill > 0) {
                    // get premium refund if applicable
                    // note: price >= clearingPrice always because fill>0
                    uint256 refundPremium = _computePremium(price - clearingPrice, fill);

                    // for bubble bidder, return premium for amount not won
                    if (fill < quantity) {
                        uint256 unfilledQuantity;

                        unchecked {
                            unfilledQuantity = quantity - fill;
                        }

                        // refund premium
                        refundPremium += _computePremium(price, unfilledQuantity);

                        // refund collateral
                        totalCollateralRefund += unfilledQuantity;
                    }

                    // if bid.price positive issue refund, if negative pay bidder premium for all the structures they got filled on
                    if (price > 0) {
                        totalPremiumRefund += refundPremium;
                    } else if (price < 0) {
                        totalPremiumRefund += _computePremium(clearingPrice, fill);
                    }

                    // add to total filled to novate at the end
                    totalFilled += fill;
                } else {
                    // if did not win, refund entre bid
                    if (price > 0) {
                        totalPremiumRefund += _computePremium(price, quantity);
                    }

                    // get collateral refund
                    totalCollateralRefund += quantity;
                }

                // remove bid from queue
                queue.remove(i);

                emit Claimed(auctionId, msg.sender, i, quantity, price);
            }

            unchecked {
                ++i;
            }
        }

        IBatchAuction.Collateral[] memory collaterals = auction.collaterals;

        // assign options and collateral from vault subAccount to user subAccount in Grappa
        if (totalFilled != 0) {
            IBatchAuctionSeller(auction.seller).novate(
                msg.sender, totalFilled, auction.optionTokens, _getCollateralPerShareAmounts(collaterals)
            );
        }

        // after checking all bids, refund totaled premium
        if (totalPremiumRefund != 0) {
            IERC20(auction.biddingToken).safeTransfer(msg.sender, totalPremiumRefund);
        }

        // after checking all bids, refund totaled collateral(s)
        if (totalCollateralRefund != 0) {
            _transferCollateral(collaterals, msg.sender, totalCollateralRefund);
        }
    }

    receive() external payable {
        revert();
    }

    fallback() external payable {
        revert();
    }

    /*///////////////////////////////////////////////////////////////
                                Getters
    //////////////////////////////////////////////////////////////*/

    /**
     * @param auctionId of the auction
     * @return bidPriceList the list of prices
     * @return bidQuantityList the list of quantities
     * @return bidOwnerList the list of owners
     * @return filledAmount the list of filled
     */
    function getBids(uint256 auctionId)
        external
        view
        returns (
            int256[] memory bidPriceList,
            uint256[] memory bidQuantityList,
            address[] memory bidOwnerList,
            uint256[] memory filledAmount
        )
    {
        BatchAuctionQ.Queue storage queue = queues[auctionId];

        return (queue.bidPriceList, queue.bidQuantityList, queue.bidOwnerList, queue.filledAmount);
    }

    /**
     * @notice gets the list of filled amounts
     * @param auctionId of the auction
     * @return filledAmount the list of bids which were filled and their amounts
     */
    function getFills(uint256 auctionId) external view returns (uint256[] memory filledAmount) {
        BatchAuctionQ.Queue storage queue = queues[auctionId];

        filledAmount = queue.filledAmount;
    }

    /**
     * @notice gets the clearing price
     * @param auctionId of the auction
     * @return clearingPrice of the auction, which is equal to the lowest priced bid that was filled
     */
    function getClearingPrice(uint256 auctionId) external view returns (int256 clearingPrice) {
        IBatchAuction.Auction storage auction = auctions[auctionId];
        BatchAuctionQ.Queue storage queue = queues[auctionId];

        if (!auction.settled) revert BA_AuctionSettled();
        clearingPrice = queue.clearingPrice;
    }

    /**
     * @notice gets the options within each structure being auctioned
     * @param auctionId of the auction
     * @return optionTokens that make up the structure being auctioned
     */
    function getOptionTokens(uint256 auctionId) external view returns (uint256[] memory optionTokens) {
        IBatchAuction.Auction storage auction = auctions[auctionId];

        optionTokens = auction.optionTokens;
    }

    /**
     * @param auctionId of the auction
     * @return collaterals that the bidder has deposited
     */
    function getBidderCollaterals(uint256 auctionId) external view returns (IBatchAuction.Collateral[] memory collaterals) {
        IBatchAuction.Auction storage auction = auctions[auctionId];

        collaterals = auction.collaterals;
    }

    function getSecondsRemaining(uint256 auctionId) external view returns (uint256) {
        uint256 endTime = auctions[auctionId].endTime;

        if (block.timestamp > endTime) return 0;

        return endTime - block.timestamp;
    }

    /*///////////////////////////////////////////////////////////////
                        Internal Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Throws if called by any account other than the owner.
     */
    function _onlyOwner() internal view {
        if (msg.sender != owner()) revert BA_Unauthorized();
    }

    /**
     * @notice checks if seller approved to auction off structures
     */
    function _checkSellerPermissions() internal view {
        if (address(whitelist) != address(0)) {
            //Revert tx if seller is not a registered vault
            if (!whitelist.isVault(msg.sender)) {
                revert BA_Unauthorized();
            }
        }
    }

    /**
     * @param auctionId required to look up the whitelist address attached to that auction
     */
    function _checkBidderPermissions(uint256 auctionId) internal view {
        address _whitelist = auctions[auctionId].whitelist;
        if (_whitelist != address(0)) {
            //Revert tx if user is not whitelisted
            if (!IWhitelist(_whitelist).isLP(msg.sender)) {
                revert BA_Unauthorized();
            }
        }
    }

    /**
     * @param price of each structure
     * @param quantity of structures
     * @return premium required
     */
    function _computePremium(int256 price, uint256 quantity) internal pure returns (uint256 premium) {
        premium = _toUint256(price).mulDivDown(quantity, UNIT);
    }

    /**
     * @notice Calculates and transfers the premium from a user to the contract if depositing, or from the contract to a user when withdrawing
     * @param tokenAddr of the premium to transfer
     * @param recipient the receiver of the premium
     * @param price to calculate how much to transfer
     * @param quantity to calculate how much to transfer
     */
    function _transferPremium(address tokenAddr, address sender, address recipient, int256 price, uint256 quantity) internal {
        bool isWithdraw = recipient != address(this);

        uint256 premium;

        if (isWithdraw) premium = _toUint256(price).mulDivDown(quantity, UNIT);
        else premium = _toUint256(price).mulDivUp(quantity, UNIT);

        IERC20 token = IERC20(tokenAddr);

        if (isWithdraw) token.safeTransfer(recipient, premium);
        else token.safeTransferFrom(sender, recipient, premium);
    }

    /**
     * @notice Transfers the collateral from a user to the contract if depositing, or from the contract to a user when withdrawing
     * @param collaterals to transfer
     * @param recipient the receiver
     * @param quantity how many to transfer
     */
    function _transferCollateral(IBatchAuction.Collateral[] memory collaterals, address recipient, uint256 quantity) internal {
        bool isWithdraw = recipient != address(this);

        //Transfer the collateral from the bidder to the auction
        for (uint256 i = 0; i < collaterals.length;) {
            // collateral per token * quantity
            // this disourages bidding for "too much size" but we can allow it for simplicity sake
            uint256 amount;

            if (isWithdraw) {
                amount = quantity.mulDivDown(collaterals[i].amount, UNIT);
            } else {
                amount = quantity.mulDivUp(collaterals[i].amount, UNIT);
            }

            if (amount > 0) {
                IERC20 token = IERC20(collaterals[i].addr);

                if (isWithdraw) token.safeTransfer(recipient, amount);
                else token.safeTransferFrom(msg.sender, address(this), amount);
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Retrieves all the amounts from the list of collaterals required per share
     * @param collaterals to retrieve the amounts from
     * @return amounts collateral amounts
     */
    function _getCollateralPerShareAmounts(IBatchAuction.Collateral[] memory collaterals)
        internal
        pure
        returns (uint256[] memory amounts)
    {
        amounts = new uint256[](collaterals.length);

        for (uint256 i; i < collaterals.length;) {
            amounts[i] = collaterals[i].amount;

            unchecked {
                ++i;
            }
        }
    }

    function _toUint256(int256 variable) internal pure returns (uint256) {
        return (variable < 0) ? uint256(-variable) : uint256(variable);
    }
}