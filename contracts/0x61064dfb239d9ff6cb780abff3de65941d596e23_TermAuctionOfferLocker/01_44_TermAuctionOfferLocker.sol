//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

import "./interfaces/ITermAuction.sol";
import "./interfaces/ITermAuctionOfferLocker.sol";
import "./interfaces/ITermAuctionOfferLockerErrors.sol";
import "./interfaces/ITermEventEmitter.sol";
import "./interfaces/ITermRepoServicer.sol";

import "./lib/TermAuctionOffer.sol";
import "./lib/TermAuctionOfferSubmission.sol";
import "./lib/TermAuctionRevealedOffer.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/// @author TermLabs
/// @title Term Offer Locker
/// @notice This contract handles and proceesses Term Auction offer submissions
/// @dev This contract belongs to the Term Auction group of contracts and is specific to a Term Repo deployment
contract TermAuctionOfferLocker is
    ITermAuctionOfferLocker,
    ITermAuctionOfferLockerErrors,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable
{
    // ========================================================================
    // = Constants  ===========================================================
    // ========================================================================

    uint256 public constant MAX_OFFER_PRICE = 10000e16; // 10,000%

    uint256 public constant MAX_OFFER_COUNT = 150;

    // ========================================================================
    // = Access Roles  ========================================================
    // ========================================================================

    bytes32 public constant AUCTIONEER_ROLE = keccak256("AUCTIONEER_ROLE");

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
    IERC20Upgradeable public purchaseToken;
    mapping(IERC20Upgradeable => bool) public collateralTokens;
    ITermRepoServicer public termRepoServicer;
    ITermEventEmitter internal emitter;
    ITermAuction internal termAuction;

    // Auction in-progress state
    mapping(bytes32 => TermAuctionOffer) internal offers;
    uint256 public offerCount;
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

    modifier onlyOfferor(address offeror, address authedUser) {
        if (authedUser != offeror) {
            revert OfferNotOwned();
        }
        _;
    }
    modifier onlyExistingOffer(bytes32 id) {
        if (offers[id].amount == 0) {
            revert NonExistentOffer(id);
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
        uint256 minimumTenderAmount_,
        IERC20Upgradeable purchaseToken_,
        IERC20Upgradeable[] memory collateralTokens_
    ) external initializer {
        UUPSUpgradeable.__UUPSUpgradeable_init();
        AccessControlUpgradeable.__AccessControl_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(INITIALIZER_ROLE, msg.sender);

        if (auctionStartTime_ > revealTime_) {
            revert AuctionStartsAfterReveal(auctionStartTime_, revealTime_);
        }

        termRepoId = keccak256(abi.encodePacked(termRepoId_));
        termAuctionId = keccak256(abi.encodePacked(auctionId_));

        auctionStartTime = auctionStartTime_;
        revealTime = revealTime_;
        auctionEndTime = auctionEndTime_;
        minimumTenderAmount = minimumTenderAmount_;
        purchaseToken = purchaseToken_;
        address[] memory collateralTokenAddresses = new address[](
            collateralTokens_.length
        );
        for (uint8 i = 0; i < collateralTokens_.length; ++i) {
            collateralTokens[collateralTokens_[i]] = true;
            collateralTokenAddresses[i] = address(collateralTokens_[i]);
        }

        offerCount = 0;
        termContractPaired = false;
    }

    function pairTermContracts(
        address termAuction_,
        ITermEventEmitter emitter_,
        ITermRepoServicer termRepoServicer_
    ) external onlyRole(INITIALIZER_ROLE) notTermContractPaired {
        termAuction = ITermAuction(termAuction_);
        _setupRole(AUCTIONEER_ROLE, termAuction_);
        emitter = emitter_;

        termRepoServicer = termRepoServicer_;

        emitter.emitTermAuctionOfferLockerInitialized(
            termRepoId,
            termAuctionId,
            address(this),
            auctionStartTime,
            revealTime,
            MAX_OFFER_PRICE,
            minimumTenderAmount
        );
    }

    // ========================================================================
    // = Interface/API ========================================================
    // ========================================================================

    /// @param offerSubmissions An array of Term Auction offer submissions to lend an amount of money at rate no lower than the offer rate
    /// @param referralAddress A user address that referred the submitter of this offer
    /// @return A bytes32 array of unique on chain offer ids.
    function lockOffersWithReferral(
        TermAuctionOfferSubmission[] calldata offerSubmissions,
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

        bytes32[] memory offerIds = new bytes32[](offerSubmissions.length);

        for (uint256 i = 0; i < offerSubmissions.length; ++i) {
            TermAuctionOffer storage offer = _lock(
                offerSubmissions[i],
                msg.sender
            );
            offerIds[i] = offer.id;
            emitter.emitOfferLocked(
                termAuctionId,
                offer.id,
                offer.offeror,
                offer.offerPriceHash,
                offer.amount,
                offer.purchaseToken,
                referralAddress
            );
        }
        return offerIds;
    }

    /// @param offerSubmissions An array of offer submissions
    /// @return A bytes32 array of unique on chain offer ids.
    function lockOffers(
        TermAuctionOfferSubmission[] memory offerSubmissions
    )
        external
        onlyWhileAuctionOpen
        whenLockingNotPaused
        nonReentrant
        returns (bytes32[] memory)
    {
        bytes32[] memory offerIds = new bytes32[](offerSubmissions.length);
        for (uint256 i = 0; i < offerSubmissions.length; ++i) {
            TermAuctionOffer storage offer = _lock(
                offerSubmissions[i],
                msg.sender
            );
            offerIds[i] = offer.id;
            emitter.emitOfferLocked(
                termAuctionId,
                offer.id,
                offer.offeror,
                offer.offerPriceHash,
                offer.amount,
                offer.purchaseToken,
                address(0)
            );
        }
        return offerIds;
    }

    /// @param id An offer Id
    /// @return A struct containing the details of the locked offer
    function lockedOffer(
        bytes32 id
    ) external view returns (TermAuctionOffer memory) {
        return offers[id];
    }

    /// @param ids An array offer ids to reveal
    /// @param prices An array of the offer prices to reveal
    /// @param nonces An array of nonce values to generate bid price hashes
    function revealOffers(
        bytes32[] calldata ids,
        uint256[] calldata prices,
        uint256[] calldata nonces
    ) external onlyWhileAuctionRevealing {
        for (uint256 i = 0; i < ids.length; ++i) {
            _revealOffer(ids[i], prices[i], nonces[i]);
        }
    }

    /// @notice unlockOffers unlocks multiple offers and returns funds to the offeror
    /// @param ids An array of offer ids
    function unlockOffers(
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
            if (offers[ids[i]].amount == 0) {
                revert NonExistentOffer(ids[i]);
            }
            if (msg.sender != offers[ids[i]].offeror) {
                revert OfferNotOwned();
            }
            _unlock(ids[i], msg.sender);
        }
    }

    // =========================================================================
    // = Auction Interface/API =================================================
    // =========================================================================

    /// @param revealedOffers An array of the revealed offer ids
    /// @param unrevealedOffers An array of the unrevealed offer ids
    /// @return An array of TermAuctionRevealedOffer structs containing details of the revealed offers
    /// @return An array of TermAuctionOffer structs containing details of the unrevealed offers
    function getAllOffers(
        bytes32[] calldata revealedOffers,
        bytes32[] calldata unrevealedOffers
    )
        external
        onlyRole(AUCTIONEER_ROLE)
        returns (TermAuctionRevealedOffer[] memory, TermAuctionOffer[] memory)
    {
        if (revealedOffers.length + unrevealedOffers.length != offerCount) {
            revert OfferCountIncorrect(offerCount);
        }

        TermAuctionRevealedOffer[]
            memory offersForAuction = new TermAuctionRevealedOffer[](
                revealedOffers.length
            );
        TermAuctionOffer[] memory unrevealed = new TermAuctionOffer[](
            unrevealedOffers.length
        );

        uint256 j = 0;
        uint256 previousOfferPrice = 0;
        for (uint256 i = 0; i < revealedOffers.length; ++i) {
            TermAuctionOffer storage revealedOffer = offers[revealedOffers[i]];
            if (revealedOffer.amount == 0) {
                revert NonExistentOffer(revealedOffers[i]);
            }
            if (!revealedOffer.isRevealed) {
                revert OfferNotRevealed(revealedOffer.id);
            }
            if (previousOfferPrice > revealedOffer.offerPriceRevealed) {
                revert RevealedOffersNotSorted();
            } else {
                previousOfferPrice = revealedOffer.offerPriceRevealed;
            }

            offersForAuction[j] = _truncateOfferStruct(
                revealedOffer,
                revealedOffer.offerPriceRevealed
            );
            j++;
            _processOfferForAuction(revealedOffer.id);
        }
        uint256 k = 0;
        for (uint256 i = 0; i < unrevealedOffers.length; ++i) {
            TermAuctionOffer storage unrevealedOffer = offers[
                unrevealedOffers[i]
            ];
            if (unrevealedOffer.amount == 0) {
                revert NonExistentOffer(unrevealedOffers[i]);
            }
            if (unrevealedOffer.isRevealed) {
                revert OfferRevealed(unrevealedOffers[i]);
            }
            unrevealed[k] = unrevealedOffer;
            ++k;
            _processOfferForAuction(unrevealedOffer.id);
        }

        assert(offerCount == 0);

        return (offersForAuction, unrevealed);
    }

    /// @param id An offer Id
    /// @param offeror Address of the offeror
    /// @param amount The amount of purchase tokens to unlock
    function unlockOfferPartial(
        bytes32 id,
        address offeror,
        uint256 amount
    ) public onlyRole(AUCTIONEER_ROLE) {
        termRepoServicer.unlockOfferAmount(offeror, amount);
        emitter.emitOfferUnlocked(termAuctionId, id);
    }

    // ========================================================================
    // = Helpers ==============================================================
    // ========================================================================

    function _lock(
        TermAuctionOfferSubmission memory offerSubmission,
        address authedUser
    )
        internal
        onlyOfferor(offerSubmission.offeror, authedUser)
        returns (TermAuctionOffer storage)
    {
        if (offerCount >= MAX_OFFER_COUNT) {
            revert MaxOfferCountReached();
        }
        bool offerExists = offers[offerSubmission.id].amount != 0;
        bytes32 offerId;
        if (offerExists) {
            if (offers[offerSubmission.id].offeror != offerSubmission.offeror) {
                revert OfferNotOwned();
            }
            offerId = offerSubmission.id;
        } else {
            offerId = _generateOfferId(offerSubmission.id, authedUser);
        }
        if (address(purchaseToken) != offerSubmission.purchaseToken) {
            revert PurchaseTokenNotApproved(offerSubmission.purchaseToken);
        }
        if (offerSubmission.amount < minimumTenderAmount) {
            revert OfferAmountTooLow(offerSubmission.amount);
        }

        uint256 oldLockedAmount = offers[offerId].amount;

        // Store offer in auction contract.
        offers[offerId] = TermAuctionOffer({
            id: offerId,
            offeror: offerSubmission.offeror,
            offerPriceRevealed: 0,
            offerPriceHash: offerSubmission.offerPriceHash,
            amount: offerSubmission.amount,
            purchaseToken: offerSubmission.purchaseToken,
            isRevealed: false
        });
        if (!offerExists) {
            offerCount += 1;
        }

        // Calculate the amount of purchase tokens to lock.
        if (oldLockedAmount < offerSubmission.amount) {
            termRepoServicer.lockOfferAmount(
                offerSubmission.offeror,
                offerSubmission.amount - oldLockedAmount
            );
        } else if (oldLockedAmount > offerSubmission.amount) {
            termRepoServicer.unlockOfferAmount(
                offerSubmission.offeror,
                oldLockedAmount - offerSubmission.amount
            );
        }

        return offers[offerId];
    }

    function _unlock(bytes32 id, address offeror) internal {
        uint256 amountToUnlock = offers[id].amount;

        delete offers[id];
        offerCount -= 1;

        emitter.emitOfferUnlocked(termAuctionId, id);

        termRepoServicer.unlockOfferAmount(offeror, amountToUnlock);
    }

    /// @dev Will revert if either the price does not match the offer price or is greater than the max offer price
    /// @param id An offer Id
    /// @param price The price of the offer to reveal
    /// @param nonce The user provided nonce value to generate the bid price hash
    function _revealOffer(bytes32 id, uint256 price, uint256 nonce) internal {
        // Check that price hasn't been modified/revealed.
        if (keccak256(abi.encode(price, nonce)) != offers[id].offerPriceHash) {
            revert OfferPriceModified();
        }
        if (price > MAX_OFFER_PRICE) {
            revert TenderPriceTooHigh(id, MAX_OFFER_PRICE);
        }

        offers[id].offerPriceRevealed = price;
        offers[id].isRevealed = true;

        emitter.emitOfferRevealed(termAuctionId, id, price);
    }

    function _generateOfferId(
        bytes32 id,
        address user
    ) internal view returns (bytes32) {
        bytes32 generatedId = keccak256(
            abi.encodePacked(id, user, address(this))
        );
        if (offers[generatedId].amount != 0) {
            revert GeneratingExistingOffer(generatedId);
        }
        return generatedId;
    }

    function _processOfferForAuction(bytes32 id) internal {
        delete offers[id];
        offerCount -= 1;
    }

    /// @param hidden TermAuctionOffer to convert to TermAuctionRevealedOffer
    /// @param price The revealed price of the offer
    /// @dev This does not check the hash of the revealed offer price
    function _truncateOfferStruct(
        TermAuctionOffer memory hidden,
        uint256 price
    ) internal pure returns (TermAuctionRevealedOffer memory revealed) {
        return
            TermAuctionRevealedOffer({
                id: hidden.id,
                offeror: hidden.offeror,
                offerPriceRevealed: price,
                amount: hidden.amount,
                purchaseToken: hidden.purchaseToken
            });
    }

    // ========================================================================
    // = Pausable =============================================================
    // ========================================================================

    function pauseLocking() external onlyRole(DEFAULT_ADMIN_ROLE) {
        lockingPaused = true;
        emitter.emitOfferLockingPaused(termAuctionId, termRepoId);
    }

    function unpauseLocking() external onlyRole(DEFAULT_ADMIN_ROLE) {
        lockingPaused = false;
        emitter.emitOfferLockingUnpaused(termAuctionId, termRepoId);
    }

    function pauseUnlocking() external onlyRole(DEFAULT_ADMIN_ROLE) {
        unlockingPaused = true;
        emitter.emitOfferUnlockingPaused(termAuctionId, termRepoId);
    }

    function unpauseUnlocking() external onlyRole(DEFAULT_ADMIN_ROLE) {
        unlockingPaused = false;
        emitter.emitOfferUnlockingUnpaused(termAuctionId, termRepoId);
    }

    // solhint-disable no-empty-blocks
    ///@dev required override by the OpenZeppelin UUPS module
    function _authorizeUpgrade(
        address
    ) internal view override onlyRole(DEFAULT_ADMIN_ROLE) {}
    // solhint-enable no-empty-blocks
}