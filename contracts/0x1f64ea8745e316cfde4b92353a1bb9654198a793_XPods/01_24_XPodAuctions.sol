/*
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@      @@@,    @@@@@(     @@@    @/   &#       @        .@@@@@@  *@@@@@@@@@@* %@@@
@@        V.    @@@@@      @@@     /    @       @         %@@@        @@,        @@
@@   @>   @.    @@@@@       @@          @    @@@@@@,    @@@@@@@    @@@     /@*  *@@
@@        ^.    @@@@        (@          @      /@@@,    @&     #&       %@@@@@@@@@@
@@       (@,    @@@@    %   (@          @      /@@@,    @      @&      .@@@@@@@@@@@
@@   ,@@@@@,    @@@#         @          @    @@@@@@,    @@@@@@@*    @      @@@  @@@
@@   ,@@@@@,       #   #%    @    @     @       @@@,    @@@@@@      /@@&         @@
@@   ,@@@@@,       #   #@,   @    @/    @       @@@,    @@@@@@@     @@@@@@@(    *@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

Planet-X X-Pods
playplanetx.com
Planet-X Ltd © 2023 | All rights reserved
cfec19b223b57f38d96f52994b515d455b5dd1bb3741b8791ada32f862e95879
*/

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: UNLICENCED

// #region ERRORS

error RefundToNullAddress();
error NoClaimsDuringBiddingStage();
error StageMustBeClaimsAndRefunds(AuctionStage currentStage);
error MinBidMustBeGreaterThanZero(uint256 minBidInput);

error FinalPriceMustMatchSetPrice();
error NoClaimsAllowedInCurrentStage(AuctionStage currentStage);

error InvalidStageForThisChange(AuctionStage currentStage);

error XDroidAddressChange();

error AlreadyRefunded(uint8 auctionId, address recipient);
error AlreadyClaimed(address claimaint);
error RevealsNotOpenYet();
error TokenNotMinted(uint16 tokenId);
error MustBeTokenOwner(address wallet, uint256 tokenId);

error ExceedsMaxTeamMint(uint256 requestedPods, uint256 maxPods);

error EmptyBaseURI();
error XDroidContractNotSet();

// #endregion

pragma solidity 0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../x-droids/Interfaces.sol";
import "../base/XNFTRoyaltyBase.sol";
import "../base/Withdrawer.sol";
import "../auctions/IXAuction.sol";
import "../auctions/AuctionStructs.sol";

contract XPods is XNFTRoyaltyBase, ReentrancyGuard, Withdrawer, IXAuction {
    using Math for uint256;
    using SafeCast for uint256;

    // the maximum pods that can be minted by this contract
    uint16 private constant TOTAL_SUPPLY = 10000;

    // The maximum pods that can be minted for the team and marketing purposes
    // set to 5% of the total supply
    // This is just an upper limit, any unspent pods from these will be available to be
    // distrubuted in auctions.
    uint16 public constant MAX_RESERVED_PODS = 500;

    // counter for the pods minted to the team
    uint16 public mintedReservedPods;

    // this is the total supply reserved in created auctions
    uint16 public auctionsReservedSupply;

    // the address of the XDroids contract
    address public xDroidsContractAddress;

    // an ID counter for auctions
    uint8 public auctionId;

    // the auctions data
    mapping(uint8 auctionId => Auction) public auctions;

    // users bids and refunds
    // auctionId -> userAddress -> User
    mapping(uint8 auctionId => mapping(address => Bidder)) public bidders;

    // a record of which auction each pod came from
    mapping(uint16 podId => uint8 auctionId) public podAuctionId;

    // when a pod is exchanged for an XDroid
    event XDroidRevealed(address owner, uint256 droidTokenId, uint256 burnedPodTokenId);
    event XDroidContractSet(address contractAddress);
    event RevealsOpen(uint8 auctionId);
    event MintedReserved(address recipient, uint256 podsCount);

    constructor() payable XNFTRoyaltyBase("X-Pod", "X-POD", 750, msg.sender) {}

    /**
     * @notice Modifier to ensure that the function is called from an external account
     */
    modifier onlyExternalAccounts() {
        _onlyExternalCallers();
        _;
    }

    // #region external functions
    function createAuction(
        uint16 _supply,
        uint8 _maxWinPerWallet,
        uint64 _minimumBid
    ) external onlyOwner {
        // validate auction params
        if (
            _supply == 0 ||
            _minimumBid == 0 ||
            _maxWinPerWallet == 0 ||
            _supply < _maxWinPerWallet
        ) {
            revert InvalidCreateAuctionParams();
        }

        // the supply requested must not exceed the total supply
        if (_supply + auctionsReservedSupply + mintedReservedPods > TOTAL_SUPPLY) {
            revert MaxSupplyExceeded();
        }

        // ensure any previous auction is active
        if (auctionId > 0) {
            Auction memory auction = currentAuction();

            if (auction.stage == AuctionStage.None) {
                revert MultipleAuctionsViolation();
            }
        }

        uint8 newAuctionId = auctionId + 1;

        auctions[newAuctionId] = Auction({
            id: newAuctionId,
            maxWinPerWallet: _maxWinPerWallet,
            supply: _supply,
            remainingSupply: _supply,
            minimumBid: _minimumBid,
            price: 0,
            stage: AuctionStage.None
        });

        // update the reserved supply
        // this is used to ensure the total supply is not exceeded
        // += consumes more gas
        auctionsReservedSupply = auctionsReservedSupply + _supply;

        emit AuctionCreated(newAuctionId, _supply, _maxWinPerWallet, _minimumBid);
    }

    /**
     * @notice begin a created auction
     */
    function startAuction() external onlyOwner {
        // the XDroid contract must be known and set before an auction starts
        if (xDroidsContractAddress == address(0)) {
            revert XDroidContractNotSet();
        }

        uint8 nextAuctionId = auctionId + 1;

        // ensure the auction exists
        Auction memory nextAuction = auctions[nextAuctionId];
        if (nextAuction.supply == 0) {
            revert AuctionDoesNotExist(nextAuctionId);
        }

        // ensure the current auction is closed
        if (auctionId > 0) {
            if (auctions[auctionId].stage < AuctionStage.Closed) {
                revert MultipleAuctionsViolation();
            }
        }

        // set the auction id
        auctionId = nextAuctionId;

        // ensure the auction is not already started
        if (nextAuction.stage != AuctionStage.None) {
            revert AuctionMustNotBeStarted();
        }

        // set the auction stage to active
        auctions[nextAuctionId].stage = AuctionStage.Active;

        emit AuctionStarted(nextAuctionId);
    }

    /**
     * @notice Starts the claims and refund stage for an auction.
     * if the price in Wei was not set correctly, there's a chance the claims and refunds
     * will start with the wrong price and then the will be no way of rectifying this mistake
     * therefore the price @param finalPrice must be sent again here to confirm the price
     */
    function startClaims(uint8 _auctionId, uint256 finalPrice) external onlyOwner {
        // read auction to memory
        Auction memory auction = auctions[_auctionId];

        // revert if the auction does not exist
        if (auction.supply == 0) {
            revert AuctionDoesNotExist(_auctionId);
        }

        // revert if the stage is not "bidding closed"
        if (auction.stage != AuctionStage.Closed) {
            revert StageMustBeBiddingClosed(auction.stage);
        }

        if (auction.price == 0) {
            revert PriceMustBeSet();
        }

        if (finalPrice != auction.price) {
            revert FinalPriceMustMatchSetPrice();
        }

        // write back to storage
        auctions[_auctionId].stage = AuctionStage.Claims;

        emit ClaimsAndRefundsStarted(_auctionId);
    }

    /**
     * @notice Start the reveals for an auction
     */
    function startReveals(uint8 _auctionId) external onlyOwner {
        // read auction to memory
        Auction memory auction = auctions[_auctionId];

        if (auction.supply == 0) {
            revert AuctionDoesNotExist(_auctionId);
        }

        if (auction.stage != AuctionStage.Claims) {
            revert StageMustBeClaimsAndRefunds(auction.stage);
        }

        auction.stage = AuctionStage.Reveals;

        // write back to storage
        auctions[_auctionId] = auction;

        emit RevealsOpen(_auctionId);
    }

    /**
     * @notice end the current auction
     * @dev a new auction cannot be started before the previous one is ended
     * hence there is no need to enable ending of a specific auction
     */
    function endAuction() external onlyOwner {
        if (auctions[auctionId].stage != AuctionStage.Active) {
            revert AuctionMustBeActive();
        }

        // write back to storage
        auctions[auctionId].stage = AuctionStage.Closed;
        emit AuctionEnded(auctionId);
    }

    function sendRefund(uint8 _auctionId, address payable _receiver) external onlyOwner {
        _sendRefund(_auctionId, _receiver);
    }

    /**
     * @notice send refunds to a batch of addresses.
     * @param _auctionId the auction id
     * @param addresses array of addresses to refund.
     */
    function sendRefundBatch(
        uint8 _auctionId,
        address[] calldata addresses
    ) external onlyOwner {
        uint256 length = addresses.length;
        uint8 i;
        do {
            _sendRefund(_auctionId, payable(addresses[i]));
            unchecked {
                ++i;
            }
        } while (i < length);
    }

    /**
     * @notice Place a bid or increase your existing bid.
     *  All bids placed are final and cannot be reversed.
     *
     * @dev there can only ever be one active auction at a time, so we don't
     *   need to pass the auction id as a parameter. A bid is always made on the current auction
     */
    function bid() external payable onlyExternalAccounts {
        // read auction to memory
        Auction memory auction = currentAuction();

        /**
        @dev the current auction remains current until the next auction is started, hence it can be 
        in stages other than active, e.g. bidding closed, claims and refunds, reveals open
         */
        if (auction.stage != AuctionStage.Active) {
            revert AuctionMustBeActive();
        }

        // @todo consider bidder caching
        // Bidder storage bidder = bidders[auction.id][msg.sender];
        uint256 userBid = bidders[auction.id][msg.sender].totalBid;

        uint64 minBid = auction.minimumBid; // storage to memory

        // increment the bid of the user
        userBid += msg.value;

        // if their new total bid is less than the current minimum bid
        // revert with an error
        // @dev we don't validate the current incoming bid increment against
        // the minimum bid, the requirement is bid (0 iniitally) + increment < minimim bid
        // rather than increment < minimum bid
        if (userBid < minBid) {
            revert BidLowerThanMinimum(userBid, minBid);
        }

        emit Bid(auction.id, msg.sender, msg.value, userBid);

        // reassign
        bidders[auction.id][msg.sender].totalBid = SafeCast.toUint120(userBid);
    }

    /**
     * @notice set the minimum contribution required to place a bid
     * @dev set this price in wei, not eth!
     * @param newMinimumBid new minimium bid in Wei
     */
    function setMinimumBid(uint64 newMinimumBid) external payable onlyOwner {
        // read auction to memory
        Auction memory auction = currentAuction();

        if (auction.stage > AuctionStage.Active) {
            revert InvalidStageForThisChange(auction.stage);
        }

        if (newMinimumBid == 0) {
            revert MinBidMustBeGreaterThanZero(newMinimumBid);
        }

        auctions[auction.id].minimumBid = newMinimumBid;

        emit MinimumBidChanged(auction.id, newMinimumBid);
    }

    function minimumBid() external view returns (uint64) {
        return auctions[auctionId].minimumBid;
    }

    function price(uint8 _auctionId) external view returns (uint64) {
        return auctions[_auctionId].price;
    }

    /**
     * @notice Claim pods and refunds for the current auction.
     */
    function claim() external nonReentrant {
        _internalClaim(msg.sender, auctionId);
    }

    /**
     * @notice Claim tokens and refund for a specific auction.
     */
    function claimForAuction(uint8 forAuctionId) external nonReentrant {
        _internalClaim(msg.sender, forAuctionId);
    }

    /**
     * @notice claim tokens and refund for an address.
     * @dev it is needed, since the withdraw function only allows to withdraw
     * funds for claimed pods
     * @param receiver the address to claim tokens for.
     */
    function claimOnBehalfOf(
        address receiver,
        uint8 forAuctionId
    ) external payable onlyOwner {
        _internalClaim(receiver, forAuctionId);
    }

    function claimOnBehalfOfBatch(
        address[] calldata addresses,
        uint8 forAuctionId
    ) external payable onlyOwner {
        uint16 i;
        uint16 length = uint16(addresses.length);

        do {
            _internalClaim(addresses[i], forAuctionId);
            unchecked {
                ++i;
            }
        } while (i < length);
    }

    /**
     * @notice reveal a pod to mint an XDroid
     * @param tokenId the token ID of the pod to reveal
     */
    function revealPod(uint16 tokenId) external nonReentrant returns (uint256) {
        // revert if the token does not exist
        if (!_exists(tokenId)) {
            revert TokenNotMinted(tokenId);
        }

        // revert if the sender is not the owner of the token
        if (ownerOf(tokenId) != msg.sender) {
            revert MustBeTokenOwner(msg.sender, tokenId);
        }

        // get the auction ID from the token ID
        uint8 _auctionId = podAuctionId[tokenId];

        // early revert if the auction is not in the right stage
        AuctionStage stage = auctions[_auctionId].stage;
        if (stage != AuctionStage.Reveals) {
            revert RevealsNotOpenYet();
        }

        // burning the pod for the minted droid
        _burn(tokenId, false);

        // droids contract interface set
        XDroidsInterface xdroidsContract = XDroidsInterface(xDroidsContractAddress);

        // get a droid in exchange
        uint256 droidId = xdroidsContract.mintFromXPod(msg.sender);

        // emit reveal event
        emit XDroidRevealed(msg.sender, droidId, tokenId);

        // Return the minted X-Droid token id
        return droidId;
    }

    /**
     * @notice Read the bid of the user for the current auction
     * @param bidder address of the bidder
     */
    function bidOf(address bidder) external view returns (uint216) {
        Bidder memory user = bidders[auctionId][bidder];
        return user.totalBid;
    }

    /**
     * @notice Read the bid of the user for an auction
     * @param bidder address of the bidder
     * @param _auctionId auction ID to read the bid for
     */
    function bidOfForAuction(
        address bidder,
        uint8 _auctionId
    ) external view returns (uint216) {
        Bidder memory user = bidders[_auctionId][bidder];
        return user.totalBid;
    }

    /**
     * @notice mint reserved tokens for the team
     * @param numberOfPods number of tokens to mint
     * @param receiver address to mint to
     */
    function mintReservedPods(uint8 numberOfPods, address receiver) external onlyOwner {
        uint16 newTotal = mintedReservedPods + numberOfPods;
        if (newTotal > MAX_RESERVED_PODS) {
            revert ExceedsMaxTeamMint(newTotal, MAX_RESERVED_PODS);
        }
        if (_totalMinted() + numberOfPods > TOTAL_SUPPLY) {
            revert MaxSupplyExceeded();
        }
        mintedReservedPods = newTotal;

        emit MintedReserved(receiver, numberOfPods);
        // mint the tokens
        _mint(receiver, numberOfPods);
    }

    /**
     * @dev sets the contract address of the X Droids contract,
     */
    function setXDroidsContract(address xDroidsAddressParam) external onlyOwner {
        if (xDroidsAddressParam == address(0)) {
            revert NullAddressParameter();
        }
        if (xDroidsContractAddress != address(0)) {
            revert XDroidAddressChange();
        }

        xDroidsContractAddress = xDroidsAddressParam;

        emit XDroidContractSet(xDroidsAddressParam);
    }

    /**
     * @notice set the clearing price after all bids have been placed.
     * @dev set this price in wei, not eth!
     * @param newPrice new price in Wei
     */
    function setPrice(uint8 _auctionId, uint64 newPrice) external payable onlyOwner {
        // read auction to memory
        Auction memory auction = auctions[_auctionId];

        if (auction.supply == 0) {
            revert AuctionDoesNotExist(_auctionId);
        }

        if (auction.stage != AuctionStage.Closed) {
            revert StageMustBeBiddingClosed(auction.stage);
        }

        uint64 minBid = auction.minimumBid; // storage to memory
        if (newPrice < minBid) {
            revert PriceIsLowerThanTheMinBid(newPrice, minBid);
        }
        auctions[_auctionId].price = newPrice;
        emit PriceSet(_auctionId, newPrice);
    }

    /**
     * @notice Withdraw function for the owner
     * @dev since only NFT sales funds can be withdrawn at any time
     * and users' funds need to be protected, this is marked as nonReentrant
     */
    function withdraw(address payable receiver) external onlyOwner nonReentrant {
        _withdraw(receiver);
    }

    // #endregion

    // #region public functions
    function currentAuction() public view returns (Auction memory) {
        if (auctionId == 0) {
            revert NoActiveAuction();
        }
        return auctions[auctionId];
    }

    // #endregion

    // #region internal functions
    function _onlyExternalCallers() internal view {
        if (msg.sender != tx.origin) {
            revert ContractCallersNotAllowed();
        }
    }

    /**
     * @notice send refund to an address. Refunds are unsuccessful bids or
     * an address's remaining eth after all their tokens have been paid for.
     * @dev can only be called after the price has been set
     * @param _auctionId the id of the auction for which the refund is sent
     * @param _receiver the address to refund to
     */
    function _sendRefund(uint8 _auctionId, address _receiver) internal {
        if (_receiver == address(0)) {
            revert RefundToNullAddress();
        }

        Auction memory auction = auctions[_auctionId]; // storage to memory

        if (auction.price == 0) {
            revert PriceMustBeSet();
        }

        Bidder memory bidder = bidders[_auctionId][_receiver]; // get user data in memory

        if (bidder.refundedFunds > 0) {
            revert AlreadyRefunded(_auctionId, _receiver);
        }

        uint256 refundValue = _refundAmount(
            bidder.totalBid,
            auction.price,
            auction.maxWinPerWallet
        );

        if (refundValue > 0) {
            bidders[_auctionId][_receiver].refundedFunds = SafeCast.toUint120(
                refundValue
            );

            // send the refund
            (bool success, ) = _receiver.call{value: refundValue}("");
            if (!success) {
                revert RefundFailed(_receiver, refundValue);
            }
            emit RefundSent(_receiver, refundValue);
        }
    }

    /**
     * @dev calculate the reufund for a bid and a price
     * @param userBid total bid
     * @param _price final price
     */
    function _refundAmount(
        uint256 userBid,
        uint256 _price,
        uint8 _maxPodsPerWallet
    ) internal pure returns (uint256) {
        // @dev taking the whole part only from the division and limiting to
        // the max pods number that can be won
        uint256 podsWon = Math.min(userBid / _price, _maxPodsPerWallet);

        // the refund is the difference between the bid and the price
        // to pay for the pods
        return userBid - (podsWon * _price);
    }

    /**
     * @notice claim function to be used both by the user and by the owner
     * @dev used by claim() and claimOnBehalfOf()
     * @param claimant the address to claim tokens for.
     */
    function _internalClaim(address claimant, uint8 _auctionId) internal {
        if (claimant == address(0)) {
            revert NullAddressParameter();
        }

        // early revert if the auction is not in the right stage
        Auction memory auction = auctions[_auctionId];

        if (auction.supply == 0) {
            revert AuctionDoesNotExist(_auctionId);
        }

        if (auction.stage < AuctionStage.Claims) {
            revert InvalidStageForOperation(auction.stage, AuctionStage.Claims);
        }

        // read user in memory
        // @todo consider caching: mapping(address => Bidder) storage _bidders = bidders[_auctionId];
        Bidder memory user = bidders[_auctionId][claimant];

        // revert if the user has already claimed
        if (user.claimed) {
            revert AlreadyClaimed(claimant);
        }

        // set the claim flag to true early (CEI)
        bidders[_auctionId][claimant].claimed = true;

        uint120 userTotalBid = user.totalBid;

        if (userTotalBid == 0) {
            revert ZeroBids(claimant);
        }

        // determine the split between tokens and refund
        // limit to the maximum tokens a wallet can win in the auction
        uint mintAmount = Math.min(
            // @dev no precision loss in division below, we only need the whole part
            Math.min(userTotalBid / auction.price, auction.maxWinPerWallet),
            auction.remainingSupply
        );

        uint128 podsMintCost = uint128(mintAmount) * auction.price;

        // if any pods are won
        // the mintAmount is adjusted for supply above,
        // hence it can be 0, if no supply has been left even if the bid is greater than the price
        if (mintAmount > 0) {
            unchecked {
                // does not overflow, mintAmount is limited to the supply left
                auctions[_auctionId].remainingSupply = uint16(
                    auction.remainingSupply - mintAmount
                );

                // increase the withdrawable amount
                withdrawableFunds = withdrawableFunds + podsMintCost;
            }

            uint16 nextTokenId = SafeCast.toUint16(_totalMinted() + 1);

            // update the pod id to auction id mapping
            uint8 i;
            do {
                podAuctionId[nextTokenId + i] = _auctionId;

                unchecked {
                    ++i;
                }
            } while (i < mintAmount);

            // mint the tokens
            _mint(claimant, mintAmount);
        }

        // send the refund to the user
        // if a previous refund has been sent, it will be substracted.
        // This can occur if the user has already been refunded by the owner
        // and they are due an extra refund, because the remaining supply is lower than
        uint128 refund = (userTotalBid - podsMintCost) - user.refundedFunds;
        if (refund > 0) {
            emit RefundSent(claimant, refund);

            // write the refund to state
            bidders[_auctionId][claimant].refundedFunds = SafeCast.toUint120(refund);

            (bool success, ) = claimant.call{value: refund}("");
            if (!success) {
                revert RefundFailed(claimant, refund);
            }
        }

        emit Claimed(claimant, userTotalBid, mintAmount, refund);
    }

    // #endregion
}