//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

import "./interfaces/ITermAuction.sol";
import "./interfaces/ITermAuctionBidLocker.sol";
import "./interfaces/ITermAuctionBidLockerErrors.sol";
import "./interfaces/ITermEventEmitter.sol";
import "./interfaces/ITermPriceOracle.sol";
import "./interfaces/ITermRepoCollateralManager.sol";
import "./interfaces/ITermRepoServicer.sol";

import "./lib/ExponentialNoError.sol";
import "./lib/TermAuctionBid.sol";
import "./lib/TermAuctionBidSubmission.sol";
import "./lib/TermAuctionRevealedBid.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/// @author TermLabs
/// @title Term Bid Locker
/// @notice This contract handles and proceesses Term Auction bid submissions
/// @dev This contract belongs to the Term Auction group of contracts and is specific to a Term Repo deployment
contract TermAuctionBidLocker is
    ITermAuctionBidLocker,
    ITermAuctionBidLockerErrors,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    ExponentialNoError,
    ReentrancyGuardUpgradeable
{
    // ========================================================================
    // = Constants  ===========================================================
    // ========================================================================

    uint256 public constant MAX_BID_PRICE = 10000e16; // 10,000%

    uint256 public constant MAX_BID_COUNT = 150;

    uint256 public constant THREESIXTY_DAYCOUNT_SECONDS = 360 days;

    // ========================================================================
    // = Access Roles  ========================================================
    // ========================================================================
    bytes32 public constant AUCTIONEER_ROLE = keccak256("AUCTIONEER_ROLE");

    bytes32 public constant ROLLOVER_MANAGER = keccak256("ROLLOVER_MANAGER");

    bytes32 public constant INITIALIZER_ROLE = keccak256("INITIALIZER_ROLE");

    // ========================================================================
    // = State Variables  =====================================================
    // ========================================================================

    // Auction configuration.
    bytes32 public termRepoId;
    bytes32 public termAuctionId;
    uint256 public auctionStartTime;
    uint256 public revealTime;
    uint256 public auctionEndTime;
    uint256 public minimumTenderAmount;
    uint256 public dayCountFractionMantissa;
    address public purchaseToken;
    mapping(IERC20Upgradeable => bool) public collateralTokens;
    ITermRepoCollateralManager public termRepoCollateralManager;
    ITermRepoServicer public termRepoServicer;
    ITermPriceOracle internal termPriceOracle;
    ITermEventEmitter internal emitter;
    ITermAuction internal termAuction;

    // Auction in-progress state
    mapping(bytes32 => TermAuctionBid) internal bids;
    uint256 public bidCount;
    bool internal termContractPaired;
    bool public lockingPaused;
    bool public unlockingPaused;

    // ========================================================================
    // = Modifiers  ===========================================================
    // ========================================================================
    modifier onlyWhileAuctionOpen() {
        if (
            // solhint-disable-next-line not-rely-on-time
            block.timestamp > revealTime || block.timestamp < auctionStartTime
        ) {
            revert AuctionNotOpen();
        }
        _;
    }
    modifier onlyWhileAuctionRevealing() {
        if (
            // solhint-disable-next-line not-rely-on-time
            block.timestamp < revealTime
        ) {
            revert AuctionNotRevealing();
        }
        _;
    }

    modifier onlyBidder(address bidder, address authedUser) {
        if (authedUser != bidder) {
            revert BidNotOwned();
        }
        _;
    }

    modifier whenLockingNotPaused() {
        if (lockingPaused) {
            revert LockingPaused();
        }
        _;
    }

    modifier whenUnlockingNotPaused() {
        if (unlockingPaused) {
            revert UnlockingPaused();
        }
        _;
    }

    modifier notTermContractPaired() {
        if (termContractPaired) {
            revert AlreadyTermContractPaired();
        }
        termContractPaired = true;
        _;
    }

    // ========================================================================
    // = Deploy (https://docs.openzeppelin.com/contracts/4.x/upgradeable) =====
    // ========================================================================

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string calldata termRepoId_,
        string calldata auctionId_,
        uint256 auctionStartTime_,
        uint256 revealTime_,
        uint256 auctionEndTime_,
        uint256 redemptionTimestamp_,
        uint256 minimumTenderAmount_,
        address purchaseToken_,
        IERC20Upgradeable[] memory collateralTokens_
    ) external initializer {
        UUPSUpgradeable.__UUPSUpgradeable_init();
        AccessControlUpgradeable.__AccessControl_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(INITIALIZER_ROLE, msg.sender);

        termRepoId = keccak256(abi.encodePacked(termRepoId_));
        termAuctionId = keccak256(abi.encodePacked(auctionId_));

        if (auctionStartTime_ > revealTime_) {
            revert AuctionStartsAfterReveal(auctionStartTime_, revealTime_);
        }

        auctionStartTime = auctionStartTime_;
        revealTime = revealTime_;
        auctionEndTime = auctionEndTime_;
        minimumTenderAmount = minimumTenderAmount_;
        dayCountFractionMantissa =
            ((redemptionTimestamp_ - auctionEndTime_) * expScale) /
            THREESIXTY_DAYCOUNT_SECONDS;
        purchaseToken = purchaseToken_;
        for (uint8 i = 0; i < collateralTokens_.length; ++i) {
            collateralTokens[collateralTokens_[i]] = true;
        }

        bidCount = 0;
        termContractPaired = false;
    }

    function pairTermContracts(
        address termAuction_,
        ITermRepoServicer termRepoServicer_,
        ITermEventEmitter emitter_,
        ITermRepoCollateralManager termRepoCollateralManager_,
        ITermPriceOracle termPriceOracle_
    ) external onlyRole(INITIALIZER_ROLE) notTermContractPaired {
        if (address(termRepoServicer_) == address(0)) {
            revert InvalidTermRepoServicer();
        }
        termRepoServicer = termRepoServicer_;
        termAuction = ITermAuction(termAuction_);
        _grantRole(AUCTIONEER_ROLE, termAuction_);

        emitter = emitter_;

        termRepoCollateralManager = termRepoCollateralManager_;
        termPriceOracle = termPriceOracle_;

        emitter.emitTermAuctionBidLockerInitialized(
            termRepoId,
            termAuctionId,
            address(this),
            auctionStartTime,
            revealTime,
            MAX_BID_PRICE,
            minimumTenderAmount,
            dayCountFractionMantissa
        );
    }

    /// @param rolloverManager The address of the TermRepoRolloverManager contract
    function pairRolloverManager(
        address rolloverManager
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(ROLLOVER_MANAGER, rolloverManager);
    }

    // ========================================================================
    // = Interface/API ========================================================
    // ========================================================================

    /// @param bidSubmissions An array of Term Auction bid submissions to borrow an amount of money at rate up to but not exceeding the bid rate
    /// @param referralAddress A user address that referred the submitter of this bid
    /// @return A bytes32 array of unique on chain bid ids.
    function lockBidsWithReferral(
        TermAuctionBidSubmission[] calldata bidSubmissions,
        address referralAddress
    )
        external
        onlyWhileAuctionOpen
        whenLockingNotPaused
        nonReentrant
        returns (bytes32[] memory)
    {
        if (msg.sender == referralAddress) {
            revert InvalidSelfReferral();
        }

        bytes32[] memory bidIds = new bytes32[](bidSubmissions.length);

        for (uint256 i = 0; i < bidSubmissions.length; ++i) {
            TermAuctionBid storage bid = _lock(bidSubmissions[i], msg.sender);
            bidIds[i] = bid.id;
            emitter.emitBidLocked(termAuctionId, bid, referralAddress);
        }
        return bidIds;
    }

    /// @param bid A struct containing details of the bid
    /// @return A bool representing whether the bid was locked or not
    function lockRolloverBid(
        TermAuctionBid calldata bid
    )
        external
        onlyWhileAuctionOpen
        whenLockingNotPaused
        onlyRole(ROLLOVER_MANAGER)
        nonReentrant
        returns (bool)
    {
        return _lockRolloverBid(bid);
    }

    /// @param bidSubmissions An array of bid submissions
    /// @return A bytes32 array of unique on chain bid ids.
    function lockBids(
        TermAuctionBidSubmission[] calldata bidSubmissions
    )
        external
        onlyWhileAuctionOpen
        whenLockingNotPaused
        nonReentrant
        returns (bytes32[] memory)
    {
        bytes32[] memory bidIds = new bytes32[](bidSubmissions.length);
        for (uint256 i = 0; i < bidSubmissions.length; ++i) {
            TermAuctionBid storage bid = _lock(bidSubmissions[i], msg.sender);
            bidIds[i] = bid.id;
            emitter.emitBidLocked(termAuctionId, bid, address(0));
        }
        return bidIds;
    }

    /// @param id A bid Id
    /// @return A struct containing details of the locked bid
    function lockedBid(
        bytes32 id
    ) external view returns (TermAuctionBid memory) {
        return bids[id];
    }

    /// @param ids An array of bid ids of the bids to reveal
    /// @param prices An array of the bid prices to reveal
    /// @param nonces An array of nonce values to generate bid price hashes
    function revealBids(
        bytes32[] calldata ids,
        uint256[] calldata prices,
        uint256[] calldata nonces
    ) external onlyWhileAuctionRevealing {
        for (uint256 i = 0; i < ids.length; ++i) {
            _revealBid(ids[i], prices[i], nonces[i]);
        }
    }

    /// @notice unlockBids unlocks multiple bids and returns funds to the bidder
    /// @param ids An array of ids to unlock
    function unlockBids(
        bytes32[] calldata ids
    ) external whenUnlockingNotPaused nonReentrant {
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp < auctionStartTime) {
            revert AuctionNotOpen();
        }
        // solhint-disable-next-line not-rely-on-time
        if (
            block.timestamp > revealTime &&
            !termAuction.auctionCancelledForWithdrawal()
        ) {
            revert AuctionNotOpen();
        }

        for (uint256 i = 0; i < ids.length; ++i) {
            _unlock(
                ids[i],
                msg.sender,
                bids[ids[i]].collateralTokens,
                bids[ids[i]].collateralAmounts
            );
        }
    }

    // ========================================================================
    // = Auction Interface/API ===============================================
    // ========================================================================

    /// @param revealedBids An array of the revealed offer ids
    /// @param expiredRolloverBids An array of the expired rollover bid ids
    /// @param unrevealedBids An array of the unrevealed offer ids
    /// @return An array of TermAuctionRevealedBid structs containing details of the revealed bids
    /// @return An array of TermAuctionBid structs containing details of the unrevealed bids
    function getAllBids(
        bytes32[] calldata revealedBids,
        bytes32[] calldata expiredRolloverBids,
        bytes32[] calldata unrevealedBids
    )
        external
        onlyRole(AUCTIONEER_ROLE)
        returns (TermAuctionRevealedBid[] memory, TermAuctionBid[] memory)
    {
        return _getAllBids(revealedBids, expiredRolloverBids, unrevealedBids);
    }

    /// @param id A bytes32 bid id
    /// @param bidder The address of the bidder
    /// @param bidCollateralTokens The addresses of the token used as collateral
    /// @param amounts The amounts of collateral tokens to unlock
    function auctionUnlockBid(
        bytes32 id,
        address bidder,
        address[] calldata bidCollateralTokens,
        uint256[] calldata amounts
    ) external onlyRole(AUCTIONEER_ROLE) {
        if (bids[id].isRollover) {
            revert RolloverBid();
        }

        emitter.emitBidUnlocked(termAuctionId, id);

        for (uint256 i = 0; i < bidCollateralTokens.length; ++i) {
            // 0 amount is a default for unlocking entire bid
            termRepoCollateralManager.auctionUnlockCollateral(
                bidder,
                bidCollateralTokens[i],
                amounts[i]
            );
        }
    }

    // ========================================================================
    // = Helpers ==============================================================
    // ========================================================================

    function _lock(
        TermAuctionBidSubmission memory bidSubmission,
        address authedUser
    )
        internal
        onlyBidder(bidSubmission.bidder, authedUser)
        returns (TermAuctionBid storage)
    {
        if (bidCount >= MAX_BID_COUNT) {
            revert MaxBidCountReached();
        }
        bool bidExists = bids[bidSubmission.id].amount != 0;
        bytes32 bidId;
        if (bidExists) {
            if (bids[bidSubmission.id].bidder != bidSubmission.bidder) {
                revert BidNotOwned();
            }
            bidId = bidSubmission.id;
        } else {
            bidId = _generateBidId(bidSubmission.id, authedUser);
        }
        if (purchaseToken != bidSubmission.purchaseToken) {
            revert PurchaseTokenNotApproved(bidSubmission.purchaseToken);
        }
        for (uint256 i = 0; i < bidSubmission.collateralTokens.length; ++i) {
            if (
                !collateralTokens[
                    IERC20Upgradeable(bidSubmission.collateralTokens[i])
                ]
            ) {
                revert CollateralTokenNotApproved(
                    bidSubmission.collateralTokens[i]
                );
            }
        }
        if (bidSubmission.amount < minimumTenderAmount) {
            revert BidAmountTooLow(bidSubmission.amount);
        }
        if (
            /// @dev check to see if bid has enough collateral to meet initial ratio for purchase price
            _isInInitialCollateralShortFall(
                bidSubmission.amount,
                bidSubmission.collateralTokens,
                bidSubmission.collateralAmounts
            )
        ) {
            revert CollateralAmountTooLow();
        }

        uint256 oldCollateralAmount;

        for (uint256 i = 0; i < bidSubmission.collateralTokens.length; ++i) {
            // Calculate the amount of collateral tokens to lock/unlock.
            if (bidExists) {
                oldCollateralAmount = bids[bidId].collateralAmounts[i];
                if (oldCollateralAmount < bidSubmission.collateralAmounts[i]) {
                    termRepoCollateralManager.auctionLockCollateral(
                        bidSubmission.bidder,
                        address(bidSubmission.collateralTokens[i]),
                        bidSubmission.collateralAmounts[i] - oldCollateralAmount
                    );
                } else if (
                    oldCollateralAmount > bidSubmission.collateralAmounts[i]
                ) {
                    termRepoCollateralManager.auctionUnlockCollateral(
                        bidSubmission.bidder,
                        address(bidSubmission.collateralTokens[i]),
                        oldCollateralAmount - bidSubmission.collateralAmounts[i]
                    );
                }
            } else {
                termRepoCollateralManager.auctionLockCollateral(
                    bidSubmission.bidder,
                    address(bidSubmission.collateralTokens[i]),
                    bidSubmission.collateralAmounts[i]
                );
            }
        }

        // slither-disable-start reentrancy-no-eth
        bids[bidId] = TermAuctionBid({
            id: bidId,
            bidder: bidSubmission.bidder,
            bidPriceRevealed: 0,
            bidPriceHash: bidSubmission.bidPriceHash,
            amount: bidSubmission.amount,
            collateralAmounts: bidSubmission.collateralAmounts,
            purchaseToken: bidSubmission.purchaseToken,
            collateralTokens: bidSubmission.collateralTokens,
            isRollover: false,
            rolloverPairOffTermRepoServicer: address(0),
            isRevealed: false
        });
        // slither-disable-end reentrancy-no-eth

        if (!bidExists) {
            bidCount += 1;
        }

        return bids[bidId];
    }

    function _lockRolloverBid(
        TermAuctionBid memory bid
    ) internal returns (bool) {
        // reject rollover bid if auction is full
        if (bidCount >= MAX_BID_COUNT) {
            return false;
        }

        if (!bid.isRollover) {
            return false;
        }
        bool bidExists = bids[bid.id].amount != 0;
        if (bidExists) {
            return false;
        }
        if (purchaseToken != bid.purchaseToken) {
            return false;
        }

        bool isInShortfall = _isInMaintenanceCollateralShortFall(
            bid.amount,
            bid.bidPriceRevealed,
            bid.collateralTokens,
            bid.collateralAmounts
        );

        if (isInShortfall) {
            return false;
        }

        // Store bid in auction contract.
        bids[bid.id] = bid;
        bidCount += 1;

        emitter.emitBidLocked(termAuctionId, bid, address(0));
        return true;
    }

    function _unlock(
        bytes32 id,
        address bidder,
        address[] storage bidCollateralTokens,
        uint256[] storage amounts
    ) internal {
        if (bids[id].amount == 0) {
            revert NonExistentBid(id);
        }

        if (bidder != bids[id].bidder) {
            revert BidNotOwned();
        }

        if (bids[id].isRollover) {
            revert RolloverBid();
        }

        // Remove bid from auction contract.
        delete bids[id];
        bidCount -= 1;

        emitter.emitBidUnlocked(termAuctionId, id);

        for (uint256 i = 0; i < bidCollateralTokens.length; ++i) {
            // 0 amount is a default for unlocking entire bid
            termRepoCollateralManager.auctionUnlockCollateral(
                bidder,
                bidCollateralTokens[i],
                amounts[i]
            );
        }
    }

    function _revealBid(bytes32 id, uint256 price, uint256 nonce) internal {
        // Check that price hasn't been modified/revealed.
        if (keccak256(abi.encode(price, nonce)) != bids[id].bidPriceHash) {
            revert BidPriceModified(id);
        }
        if (price > MAX_BID_PRICE) {
            revert TenderPriceTooHigh(id, MAX_BID_PRICE);
        }
        bids[id].bidPriceRevealed = price;
        bids[id].isRevealed = true;

        emitter.emitBidRevealed(termAuctionId, id, price);
    }

    /// @param revealedBids An array of the revealed offer ids
    /// @param expiredRolloverBids An array of the expired rollover bid ids
    /// @param unrevealedBids An array of the unrevealed offer ids
    /// @return An array of TermAuctionRevealedBid structs containing details of the revealed bids
    /// @return An array of TermAuctionBid structs containing details of the unrevealed bids
    function _getAllBids(
        bytes32[] calldata revealedBids,
        bytes32[] calldata expiredRolloverBids,
        bytes32[] calldata unrevealedBids
    )
        internal
        returns (TermAuctionRevealedBid[] memory, TermAuctionBid[] memory)
    {
        if (
            revealedBids.length +
                expiredRolloverBids.length +
                unrevealedBids.length !=
            bidCount
        ) {
            revert BidCountIncorrect(bidCount);
        }

        uint256 i;

        for (i = 0; i < expiredRolloverBids.length; ++i) {
            TermAuctionBid storage expiredRolloverBid = bids[
                expiredRolloverBids[i]
            ];
            if (expiredRolloverBid.amount == 0) {
                revert NonExistentBid(expiredRolloverBids[i]);
            }
            if (!expiredRolloverBid.isRollover) {
                revert NonRolloverBid(expiredRolloverBids[i]);
            }
            ITermRepoServicer pairOffServicer = ITermRepoServicer(
                expiredRolloverBid.rolloverPairOffTermRepoServicer
            );
            // NOTE: Include bid for assignment only if term repurchase window hasn't expired.
            // solhint-disable-next-line not-rely-on-time
            if (block.timestamp > pairOffServicer.endOfRepurchaseWindow()) {
                _processBidForAuction(expiredRolloverBid.id);
            } else {
                revert NonExpiredRolloverBid(expiredRolloverBid.id);
            }
        }

        TermAuctionBid[] memory revealedBidsInShortfall;
        uint256 auctionBidCount;
        uint256 unlockBidCount;
        uint256 revealedBidsInShortfallCount;

        (
            revealedBidsInShortfall,
            auctionBidCount,
            unlockBidCount,
            revealedBidsInShortfallCount
        ) = _processRevealedBidsForValidity(
            revealedBids,
            unrevealedBids.length
        );

        TermAuctionRevealedBid[]
            memory bidsForAuction = _fillRevealedBidsForAuctionClearing(
                revealedBids,
                auctionBidCount
            );
        TermAuctionBid[] memory bidsForUnlocking = new TermAuctionBid[](
            unlockBidCount
        );

        // Add unrevealed bids to bid array for unlocking
        uint256 bidsForUnlockingCounter = 0;
        for (i = 0; i < unrevealedBids.length; ++i) {
            TermAuctionBid storage unrevealedBid = bids[unrevealedBids[i]];
            if (unrevealedBid.amount == 0) {
                revert NonExistentBid(unrevealedBids[i]);
            }
            if (unrevealedBid.isRevealed) {
                revert BidRevealed(unrevealedBids[i]);
            }
            bidsForUnlocking[bidsForUnlockingCounter] = unrevealedBid;
            ++bidsForUnlockingCounter;
            _processBidForAuction(unrevealedBid.id);
        }

        for (i = 0; i < revealedBidsInShortfallCount; ++i) {
            bidsForUnlocking[bidsForUnlockingCounter] = revealedBidsInShortfall[
                i
            ];
            ++bidsForUnlockingCounter;
        }

        assert(bidCount == 0);

        return (bidsForAuction, bidsForUnlocking);
    }

    /// @param bid The TermAuctionBid to convert to TermAuctionRevealedBid
    /// @dev This does not check the hash of the revealed bid price
    function _truncateBidStruct(
        TermAuctionBid memory bid
    ) internal pure returns (TermAuctionRevealedBid memory revealed) {
        return
            TermAuctionRevealedBid({
                id: bid.id,
                bidder: bid.bidder,
                bidPriceRevealed: bid.bidPriceRevealed,
                amount: bid.amount,
                collateralAmounts: bid.collateralAmounts,
                purchaseToken: bid.purchaseToken,
                collateralTokens: bid.collateralTokens,
                isRollover: bid.isRollover,
                rolloverPairOffTermRepoServicer: bid
                    .rolloverPairOffTermRepoServicer
            });
    }

    function _processRevealedBidsForValidity(
        bytes32[] calldata revealedBids,
        uint256 unrevealedBidCount
    ) internal returns (TermAuctionBid[] memory, uint256, uint256, uint256) {
        uint256 auctionBidCount = revealedBids.length;
        uint256 unlockBidCount = unrevealedBidCount;

        TermAuctionBid[] memory revealedBidsInShortFall = new TermAuctionBid[](
            auctionBidCount
        );

        uint256 revealedBidsInShortFallCounter = 0;
        uint256 previousBidPrice = 0;

        for (uint256 i = 0; i < revealedBids.length; ++i) {
            TermAuctionBid storage revealedBid = bids[revealedBids[i]];
            if (revealedBid.amount == 0) {
                revert NonExistentBid(revealedBids[i]);
            }
            if (previousBidPrice > revealedBid.bidPriceRevealed) {
                revert RevealedBidsNotSorted();
            } else {
                previousBidPrice = revealedBid.bidPriceRevealed;
            }
            if (revealedBid.isRollover) {
                ITermRepoServicer pairOffServicer = ITermRepoServicer(
                    revealedBid.rolloverPairOffTermRepoServicer
                );
                // NOTE: Include bid for assignment only if term repurchase window hasn't expired.
                if (
                    // solhint-disable-next-line not-rely-on-time
                    block.timestamp > pairOffServicer.endOfRepurchaseWindow()
                ) {
                    revert RolloverBidExpired(revealedBid.id);
                }

                if (!_isRolloverStillValid(revealedBid, pairOffServicer)) {
                    ++unlockBidCount;
                    revealedBidsInShortFall[
                        revealedBidsInShortFallCounter
                    ] = revealedBid;
                    ++revealedBidsInShortFallCounter;
                    --auctionBidCount;
                    _processBidForAuction(revealedBid.id);
                    continue;
                }
            } else {
                if (!revealedBid.isRevealed) {
                    revert BidNotRevealed(revealedBid.id);
                }
            }

            // If bid is in shortfall, mark for unlocking if not a rollover
            if (
                _isInMaintenanceCollateralShortFall(
                    revealedBid.amount,
                    revealedBid.bidPriceRevealed,
                    revealedBid.collateralTokens,
                    revealedBid.collateralAmounts
                )
            ) {
                emitter.emitBidInShortfall(termAuctionId, revealedBid.id);

                ++unlockBidCount;
                revealedBidsInShortFall[
                    revealedBidsInShortFallCounter
                ] = revealedBid;
                ++revealedBidsInShortFallCounter;
                --auctionBidCount;
                _processBidForAuction(revealedBid.id);
            }
        }
        return (
            revealedBidsInShortFall,
            auctionBidCount,
            unlockBidCount,
            revealedBidsInShortFallCounter
        );
    }

    function _isRolloverStillValid(
        TermAuctionBid storage revealedBid,
        ITermRepoServicer pairOffServicer
    ) internal returns (bool) {
        uint256 borrowerRepurchaseObligation = pairOffServicer
            .getBorrowerRepurchaseObligation(revealedBid.bidder);
        if (borrowerRepurchaseObligation == 0) {
            return false;
        }

        uint256 servicingFeeProRatedMantissa = mul_(
            Exp({mantissa: dayCountFractionMantissa}),
            Exp({mantissa: termRepoServicer.servicingFee()})
        ).mantissa;

        uint256 maxRolloverAmount = truncate(
            div_(
                Exp({mantissa: borrowerRepurchaseObligation * expScale}),
                Exp({mantissa: expScale - servicingFeeProRatedMantissa})
            )
        );
        if (maxRolloverAmount < revealedBid.amount) {
            revealedBid.amount = maxRolloverAmount;
            emitter.emitBidLocked(termAuctionId, revealedBid, address(0));
        }

        return true;
    }

    function _isInInitialCollateralShortFall(
        uint256 bidAmount,
        address[] memory collateralTokens_,
        uint256[] memory collateralAmounts
    ) internal view returns (bool) {
        Exp memory bidAmountUSDValue = termPriceOracle.usdValueOfTokens(
            purchaseToken,
            bidAmount
        );
        Exp memory haircutUSDTotalCollateralValue = Exp({mantissa: 0});
        for (uint256 i = 0; i < collateralTokens_.length; ++i) {
            address collateralToken = collateralTokens_[i];
            uint256 initialCollateralRatio = termRepoCollateralManager
                .initialCollateralRatios(collateralToken);
            if (collateralAmounts[i] == 0) {
                continue;
            }
            Exp memory additionalHairCutUSDCollateralValue = div_(
                termPriceOracle.usdValueOfTokens(
                    collateralToken,
                    collateralAmounts[i]
                ),
                Exp({mantissa: initialCollateralRatio})
            );
            haircutUSDTotalCollateralValue = add_(
                additionalHairCutUSDCollateralValue,
                haircutUSDTotalCollateralValue
            );
        }
        if (lessThanExp(haircutUSDTotalCollateralValue, bidAmountUSDValue)) {
            return true;
        }
        return false;
    }

    function _isInMaintenanceCollateralShortFall(
        uint256 bidAmount,
        uint256 bidPrice,
        address[] memory collateralTokens_,
        uint256[] memory collateralAmounts
    ) internal view returns (bool) {
        uint256 repurchasePrice;
        if (bidPrice == 0) {
            repurchasePrice = bidAmount;
        } else {
            Exp memory repurchaseFactor = add_(
                Exp({mantissa: expScale}),
                mul_(
                    Exp({mantissa: dayCountFractionMantissa}),
                    Exp({mantissa: bidPrice})
                )
            );

            repurchasePrice = truncate(
                mul_(Exp({mantissa: bidAmount * expScale}), repurchaseFactor)
            );
        }

        Exp memory repurchasePriceUSDValue = termPriceOracle.usdValueOfTokens(
            purchaseToken,
            repurchasePrice
        );
        Exp memory haircutUSDTotalCollateralValue = Exp({mantissa: 0});
        for (uint256 i = 0; i < collateralTokens_.length; ++i) {
            address collateralToken = collateralTokens_[i];
            uint256 maintenanceCollateralRatio = termRepoCollateralManager
                .maintenanceCollateralRatios(collateralToken);
            if (collateralAmounts[i] == 0) {
                continue;
            }
            Exp memory additionalHairCutUSDCollateralValue = div_(
                termPriceOracle.usdValueOfTokens(
                    collateralToken,
                    collateralAmounts[i]
                ),
                Exp({mantissa: maintenanceCollateralRatio})
            );
            haircutUSDTotalCollateralValue = add_(
                additionalHairCutUSDCollateralValue,
                haircutUSDTotalCollateralValue
            );
        }
        if (
            lessThanExp(haircutUSDTotalCollateralValue, repurchasePriceUSDValue)
        ) {
            return true;
        }
        return false;
    }

    function _fillRevealedBidsForAuctionClearing(
        bytes32[] calldata revealedBids,
        uint256 auctionBidCount
    ) internal returns (TermAuctionRevealedBid[] memory) {
        TermAuctionRevealedBid[]
            memory bidsForAuction = new TermAuctionRevealedBid[](
                auctionBidCount
            );

        // fill auction bids array
        uint256 bidsForAuctionCounter = 0;
        for (uint256 i = 0; i < revealedBids.length; ++i) {
            TermAuctionBid storage revealedBid = bids[revealedBids[i]];

            if (revealedBid.amount == 0) {
                continue;
            }

            bidsForAuction[bidsForAuctionCounter] = _truncateBidStruct(
                revealedBid
            );

            bidsForAuctionCounter++;
            _processBidForAuction(revealedBid.id);
        }
        return bidsForAuction;
    }

    function _generateBidId(
        bytes32 id,
        address user
    ) internal view returns (bytes32) {
        bytes32 generatedId = keccak256(
            abi.encodePacked(id, user, address(this))
        );
        if (bids[generatedId].amount != 0) {
            revert GeneratingExistingBid(generatedId);
        }
        return generatedId;
    }

    function _processBidForAuction(bytes32 id) internal {
        delete bids[id];
        bidCount -= 1;
    }

    // ========================================================================
    // = Pausable =============================================================
    // ========================================================================

    function pauseLocking() external onlyRole(DEFAULT_ADMIN_ROLE) {
        lockingPaused = true;
        emitter.emitBidLockingPaused(termAuctionId, termRepoId);
    }

    function unpauseLocking() external onlyRole(DEFAULT_ADMIN_ROLE) {
        lockingPaused = false;
        emitter.emitBidLockingUnpaused(termAuctionId, termRepoId);
    }

    function pauseUnlocking() external onlyRole(DEFAULT_ADMIN_ROLE) {
        unlockingPaused = true;
        emitter.emitBidUnlockingPaused(termAuctionId, termRepoId);
    }

    function unpauseUnlocking() external onlyRole(DEFAULT_ADMIN_ROLE) {
        unlockingPaused = false;
        emitter.emitBidUnlockingUnpaused(termAuctionId, termRepoId);
    }

    // solhint-disable no-empty-blocks
    ///@dev required override by the OpenZeppelin UUPS module
    function _authorizeUpgrade(
        address
    ) internal view override onlyRole(DEFAULT_ADMIN_ROLE) {}
    // solhint-enable no-empty-blocks
}