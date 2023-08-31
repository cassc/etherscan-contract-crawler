//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

import "./interfaces/ITermEventEmitter.sol";
import "./interfaces/ITermRepoServicer.sol";
import "./interfaces/ITermRepoServicerErrors.sol";
import "./interfaces/ITermController.sol";
import "./interfaces/ITermRepoCollateralManager.sol";
import "./interfaces/ITermRepoLocker.sol";
import "./interfaces/ITermRepoRolloverManager.sol";
import "./interfaces/ITermRepoToken.sol";

import "./lib/ExponentialNoError.sol";
import "./lib/TermAuctionGroup.sol";
import "./lib/TermRepoRolloverElection.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/// @author TermLabs
/// @title Term Repo Servicer
/// @notice This contract maintains records, collects and disburse repurchase payments
/// @dev This contract belongs to the Term Servicer group of contracts and is specific to a Term Repo deployment
contract TermRepoServicer is
    ITermRepoServicer,
    ITermRepoServicerErrors,
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    ExponentialNoError
{
    // ========================================================================
    // = Constants  ===========================================================
    // ========================================================================
    uint256 public constant YEAR_SECONDS = 60 * 60 * 24 * 360;

    // ========================================================================
    // = Access Roles  ========================================================
    // ========================================================================

    bytes32 public constant AUCTION_LOCKER = keccak256("AUCTION_LOCKER");
    bytes32 public constant AUCTIONEER = keccak256("AUCTIONEER");
    bytes32 public constant COLLATERAL_MANAGER =
        keccak256("COLLATERAL_MANAGER");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ROLLOVER_MANAGER = keccak256("ROLLOVER_MANAGER");
    bytes32 public constant ROLLOVER_TARGET_AUCTIONEER_ROLE =
        keccak256("ROLLOVER_TARGET_AUCTIONEER_ROLE");
    bytes32 public constant INITIALIZER_ROLE = keccak256("INITIALIZER_ROLE");

    // ========================================================================
    // = State Variables  =====================================================
    // ========================================================================

    bytes32 public termRepoId;

    // Total Repurchase Price Owed by all borrowers
    uint256 public totalOutstandingRepurchaseExposure;

    // Total Repurchase Currency locked by TermLocker
    uint256 public totalRepurchaseCollected;

    // block timestamp at which repurchase is due
    uint256 public maturityTimestamp;

    //block timestamp at which repurchase period ends
    uint256 public endOfRepurchaseWindow;

    /// block timestamp at which term repo tokens can be redeemed
    uint256 public redemptionTimestamp;

    /// percentage share of bid amounts charged to bidder
    uint256 public servicingFee;

    /// proportion of redemption value for redemption
    uint256 public shortfallHaircutMantissa;

    // token used for purchase/loans
    address public purchaseToken;

    // collateral manager in same term
    ITermRepoCollateralManager public termRepoCollateralManager;

    // rollover manager in same term
    ITermRepoRolloverManager public termRepoRolloverManager;

    // TermRepoLocker for term funds
    ITermRepoLocker public termRepoLocker;

    // TermRepoToken for current term
    ITermRepoToken public termRepoToken;

    // global term controller contract
    ITermController internal termController;

    // global term event emitter
    ITermEventEmitter internal emitter;

    // Repurchase Exposure Ledger
    // For each borrower wallet address, keep ledger of repurchase obligations
    mapping(address => uint256) internal repurchaseExposureLedger;

    bool internal termContractPaired;

    // ========================================================================
    // = Modifiers  ===========================================================
    // ========================================================================
    modifier notTermContractPaired() {
        if (termContractPaired) {
            revert AlreadyTermContractPaired();
        }
        termContractPaired = true;
        _;
    }

    // ========================================================================
    // = Deploy  ==============================================================
    // ========================================================================

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string calldata termRepoId_,
        uint256 maturityTimestamp_,
        uint256 repurchaseWindow_,
        uint256 redemptionBuffer_,
        uint256 servicingFee_,
        address purchaseToken_,
        ITermController termController_,
        ITermEventEmitter emitter_
    ) external initializer {
        UUPSUpgradeable.__UUPSUpgradeable_init();
        AccessControlUpgradeable.__AccessControl_init();

        termRepoId = keccak256(abi.encodePacked(termRepoId_));
        totalOutstandingRepurchaseExposure = 0;
        totalRepurchaseCollected = 0;
        maturityTimestamp = maturityTimestamp_;
        endOfRepurchaseWindow = maturityTimestamp_ + repurchaseWindow_;
        redemptionTimestamp =
            maturityTimestamp_ +
            repurchaseWindow_ +
            redemptionBuffer_;
        servicingFee = servicingFee_;

        require(purchaseToken_ != address(0), "Zero address purchase token");
        purchaseToken = purchaseToken_;

        termController = termController_;
        emitter = emitter_;

        termContractPaired = false;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(INITIALIZER_ROLE, msg.sender);
    }

    function pairTermContracts(
        address termRepoLocker_,
        address termRepoCollateralManager_,
        address termRepoToken_,
        address termAuctionOfferLocker_,
        address termAuction_,
        address rolloverManager_,
        string calldata version_
    ) external onlyRole(INITIALIZER_ROLE) notTermContractPaired {
        termRepoLocker = ITermRepoLocker(termRepoLocker_);
        termRepoCollateralManager = ITermRepoCollateralManager(
            termRepoCollateralManager_
        );
        termRepoRolloverManager = ITermRepoRolloverManager(rolloverManager_);
        termRepoToken = ITermRepoToken(termRepoToken_);

        _grantRole(AUCTION_LOCKER, termAuctionOfferLocker_);
        _grantRole(AUCTIONEER, termAuction_);
        _grantRole(COLLATERAL_MANAGER, termRepoCollateralManager_);
        _grantRole(ROLLOVER_MANAGER, rolloverManager_);

        emitter.emitTermRepoServicerInitialized(
            termRepoId,
            address(this),
            purchaseToken,
            maturityTimestamp,
            endOfRepurchaseWindow,
            redemptionTimestamp,
            servicingFee,
            version_
        );
    }

    // ========================================================================
    // = APIs  ================================================================
    // ========================================================================

    /// @notice The max repurchase amount is the repurchase balance less any amounts earmarked for rollover
    /// @param amount The amount of purchase token to submit for repurchase
    function submitRepurchasePayment(uint256 amount) external {
        address borrower = msg.sender;

        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp < maturityTimestamp) {
            revert NotMaturedYet();
        }
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp >= endOfRepurchaseWindow) {
            revert AfterRepurchaseWindow();
        }

        if (repurchaseExposureLedger[borrower] == 0) {
            revert ZeroBorrowerRepurchaseObligation();
        }

        if (amount == type(uint256).max) {
            revert InvalidParameters("repurchase amount cannot be uint max");
        }

        uint256 maxRepurchaseAmount = _getMaxRepaymentAroundRollover(borrower);

        if (amount > maxRepurchaseAmount) {
            revert RepurchaseAmountTooHigh();
        }

        _repay(borrower, borrower, amount);

        if (repurchaseExposureLedger[borrower] == 0) {
            termRepoCollateralManager.unlockCollateralOnRepurchase(borrower);
        }

        emitter.emitRepurchasePaymentSubmitted(termRepoId, borrower, amount);
    }

    /// @param amountToBurn The amount of TermRepoTokens to burn
    function burnCollapseExposure(uint256 amountToBurn) external {
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp >= endOfRepurchaseWindow) {
            revert AfterRepurchaseWindow();
        }

        address borrower = msg.sender;

        if (repurchaseExposureLedger[borrower] == 0) {
            revert ZeroBorrowerRepurchaseObligation();
        }

        IERC20MetadataUpgradeable purchaseTokenInstance = IERC20MetadataUpgradeable(
                purchaseToken
            );
        uint256 purchaseTokenDecimals = uint256(
            purchaseTokenInstance.decimals()
        );

        uint256 maxRepurchaseAmount = _getMaxRepaymentAroundRollover(borrower);

        uint256 termRepoTokenValueOfRepurchase = div_(
            Exp({
                mantissa: maxRepurchaseAmount *
                    10 ** (18 - purchaseTokenDecimals)
            }),
            Exp({mantissa: termRepoToken.redemptionValue()})
        ).mantissa / 10 ** (18 - purchaseTokenDecimals);

        if (amountToBurn < termRepoTokenValueOfRepurchase) {
            uint256 repayAmount = termRepoToken.burnAndReturnValue(
                borrower,
                amountToBurn
            );
            // slither-disable-start reentrancy-no-eth
            repurchaseExposureLedger[borrower] -= repayAmount;

            totalOutstandingRepurchaseExposure -= repayAmount;
            // slither-disable-end reentrancy-no-eth

            assert(_isTermRepoBalanced());

            emitter.emitBurnCollapseExposure(termRepoId, borrower, repayAmount);
        } else {
            // slither-disable-start reentrancy-no-eth
            totalOutstandingRepurchaseExposure -= maxRepurchaseAmount;
            repurchaseExposureLedger[borrower] -= maxRepurchaseAmount;
            // slither-disable-end reentrancy-no-eth

            termRepoToken.burn(borrower, termRepoTokenValueOfRepurchase);

            assert(_isTermRepoBalanced());

            emitter.emitBurnCollapseExposure(
                termRepoId,
                borrower,
                maxRepurchaseAmount
            );

            termRepoCollateralManager.unlockCollateralOnRepurchase(borrower);
        }
    }

    /// @param borrower The address of the borrower to query
    /// @return The total repurchase price due at maturity for a given borrower
    function getBorrowerRepurchaseObligation(
        address borrower
    ) external view returns (uint256) {
        return repurchaseExposureLedger[borrower];
    }

    /// @dev This method allows MINTER_ROLE to open repurchase price exposure against a TermRepoToken mint of corresponding value outside of a Term Auction to create new supply
    /// @param amount The amount of Term Repo Tokens to mint
    /// @param collateralAmounts An array containing an amount of collateral token for each token in collateral basket
    function mintOpenExposure(
        uint256 amount,
        uint256[] calldata collateralAmounts
    ) external {
        address borrower = msg.sender;

        if (!hasRole(MINTER_ROLE, borrower)) {
            revert NoMintOpenExposureAccess();
        }

        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp > maturityTimestamp) {
            revert AfterMaturity();
        }

        if (
            collateralAmounts.length !=
            termRepoCollateralManager.numOfAcceptedCollateralTokens()
        ) {
            revert InvalidParameters(
                "Collateral Amounts array not same length as collateral tokens list"
            );
        }

        uint256 maxMintValue = 0;
        for (uint256 i = 0; i < collateralAmounts.length; ++i) {
            termRepoCollateralManager.mintOpenExposureLockCollateral(
                borrower,
                termRepoCollateralManager.collateralTokens(i),
                collateralAmounts[i]
            );
            uint256 maxTokensFromCollateral = truncate(
                div_(
                    termRepoCollateralManager.calculateMintableExposure(
                        termRepoCollateralManager.collateralTokens(i),
                        collateralAmounts[i]
                    ),
                    Exp({mantissa: termRepoToken.redemptionValue()})
                )
            );
            maxMintValue += maxTokensFromCollateral;
        }
        if (amount > maxMintValue) {
            revert InsufficientCollateral();
        }

        Exp memory proRate = div_(
            // solhint-disable-next-line not-rely-on-time
            Exp({mantissa: (maturityTimestamp - block.timestamp)}),
            Exp({mantissa: (YEAR_SECONDS)})
        );

        Exp memory protocolShareProRated = mul_(
            Exp({mantissa: servicingFee}),
            proRate
        );

        uint256 protocolMintTokens = mul_ScalarTruncate(
            protocolShareProRated,
            amount
        );
        uint256 minterTokens = amount - protocolMintTokens;

        uint256 protocolMintTokensValue = termRepoToken.mintTokens(
            termController.getTreasuryAddress(),
            protocolMintTokens
        );
        uint256 minterTokensValue = termRepoToken.mintTokens(
            borrower,
            minterTokens
        );
        termRepoToken.decrementMintExposureCap(amount);

        uint256 totalMintValue = protocolMintTokensValue + minterTokensValue;

        // slither-disable-start reentrancy-benign
        repurchaseExposureLedger[borrower] += totalMintValue;

        totalOutstandingRepurchaseExposure += totalMintValue;
        // slither-disable-end reentrancy-benign

        assert(_isTermRepoBalanced());

        emitter.emitBidFulfilled(
            termRepoId,
            borrower,
            minterTokensValue,
            totalMintValue,
            protocolMintTokensValue
        );

        emitter.emitMintExposure(
            termRepoId,
            borrower,
            minterTokens,
            protocolMintTokens,
            totalMintValue
        );
    }

    /// @param redeemer The address of redeemer
    /// @param amountToRedeem The amount of TermRepoTokens to redeem
    function redeemTermRepoTokens(
        address redeemer,
        uint256 amountToRedeem
    ) external {
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp <= redemptionTimestamp) {
            revert RedemptionPeriodNotOpen();
        }

        if (termRepoToken.balanceOf(redeemer) == 0) {
            revert ZeroTermRepoTokenBalance();
        }

        if (
            termRepoToken.totalRedemptionValue() <=
            totalRepurchaseCollected + 10 ** 4
        ) {
            _parRedemption(redeemer, amountToRedeem);
        } else if (!termRepoCollateralManager.encumberedCollateralRemaining()) {
            _proRataRedemption(redeemer, amountToRedeem);
        } else {
            revert EncumberedCollateralRemaining();
        }
    }

    /// @return A boolean that represents whether the term repo locker is balanced
    function isTermRepoBalanced() external view returns (bool) {
        return _isTermRepoBalanced();
    }

    // ========================================================================
    // = Auction Functions  ===================================================
    // ========================================================================

    /// @param offeror The address of the offeror
    /// @param amount The amount of purchase tokens to lock
    function lockOfferAmount(
        address offeror,
        uint256 amount
    ) external onlyRole(AUCTION_LOCKER) {
        termRepoLocker.transferTokenFromWallet(offeror, purchaseToken, amount);

        emitter.emitOfferLockedByServicer(termRepoId, offeror, amount);
    }

    /// @param offeror The address of the offeror
    /// @param amount The amount of purchase tokens to unlocked
    function unlockOfferAmount(
        address offeror,
        uint256 amount
    ) external onlyRole(AUCTION_LOCKER) {
        termRepoLocker.transferTokenToWallet(offeror, purchaseToken, amount);

        emitter.emitOfferUnlockedByServicer(termRepoId, offeror, amount);
    }

    /// @param offeror The address of the offeror
    /// @param purchasePrice The offer amount to fulfill
    /// @param repurchasePrice The repurchase price due to offeror at maturity
    /// @param offerId Unique identifier for this offer
    function fulfillOffer(
        address offeror,
        uint256 purchasePrice,
        uint256 repurchasePrice,
        bytes32 offerId
    ) external onlyRole(AUCTIONEER) {
        uint256 repoTokensMinted = termRepoToken.mintRedemptionValue(
            offeror,
            repurchasePrice
        );

        emitter.emitOfferFulfilled(
            offerId,
            offeror,
            purchasePrice,
            repurchasePrice,
            repoTokensMinted
        );
    }

    /// @param bidder The address of the bidder
    /// @param purchasePrice The bid amount to fulfill
    /// @param repurchasePrice The repurchase price due at maturity
    /// @param collateralTokens Collateral token addresses
    /// @param collateralAmounts Collateral token amounts
    /// @param dayCountFractionMantissa Actual/360 day count fraction parameter from Term Auction Group
    function fulfillBid(
        address bidder,
        uint256 purchasePrice,
        uint256 repurchasePrice,
        address[] calldata collateralTokens,
        uint256[] calldata collateralAmounts,
        uint256 dayCountFractionMantissa
    ) external onlyRole(AUCTIONEER) {
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp >= maturityTimestamp) {
            revert AfterMaturity();
        }

        repurchaseExposureLedger[bidder] += repurchasePrice;
        totalOutstandingRepurchaseExposure += repurchasePrice;

        termRepoCollateralManager.journalBidCollateralToCollateralManager(
            bidder,
            collateralTokens,
            collateralAmounts
        );

        uint256 protocolShare = mul_ScalarTruncate(
            mul_(
                Exp({mantissa: dayCountFractionMantissa}),
                Exp({mantissa: servicingFee})
            ),
            purchasePrice
        );

        termRepoLocker.transferTokenToWallet(
            termController.getTreasuryAddress(),
            purchaseToken,
            protocolShare
        );

        termRepoLocker.transferTokenToWallet(
            bidder,
            purchaseToken,
            purchasePrice - protocolShare
        );

        emitter.emitBidFulfilled(
            termRepoId,
            bidder,
            purchasePrice,
            repurchasePrice,
            protocolShare
        );
    }

    // ========================================================================
    // = Rollover Functions  ==================================================
    // ========================================================================

    /// @param termAuction The address of a TermAuction contract to receive autioneer role
    function approveRolloverAuction(
        address termAuction
    ) external onlyRole(ROLLOVER_MANAGER) {
        _grantRole(ROLLOVER_TARGET_AUCTIONEER_ROLE, termAuction);
    }

    /// @param borrower The address of the borrower rolling into new Term Repo
    /// @param purchasePrice The purchase price received from new TermRepo
    /// @param repurchasePrice The new repurchase price due at maturity of new TermRepo
    /// @param previousTermRepoLocker   The address of the old TermRepoLocker contract
    /// @param dayCountFractionMantissa Actual/360 day count fraction parameter from Term Auction Group
    /// @return The net purchase price received in after deducing protocol servicing fees
    function openExposureOnRolloverNew(
        address borrower,
        uint256 purchasePrice,
        uint256 repurchasePrice,
        address previousTermRepoLocker,
        uint256 dayCountFractionMantissa
    ) external onlyRole(AUCTIONEER) returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp >= maturityTimestamp) {
            revert AfterMaturity();
        }

        repurchaseExposureLedger[borrower] += repurchasePrice;
        totalOutstandingRepurchaseExposure += repurchasePrice;

        uint256 protocolShare = mul_ScalarTruncate(
            mul_(
                Exp({mantissa: dayCountFractionMantissa}),
                Exp({mantissa: servicingFee})
            ),
            purchasePrice
        );

        termRepoLocker.transferTokenToWallet(
            termController.getTreasuryAddress(),
            purchaseToken,
            protocolShare
        );

        uint256 netPurchasePrice = purchasePrice - protocolShare;

        termRepoLocker.transferTokenToWallet(
            previousTermRepoLocker,
            purchaseToken,
            netPurchasePrice
        );

        emitter.emitExposureOpenedOnRolloverNew(
            termRepoId,
            borrower,
            netPurchasePrice,
            repurchasePrice,
            protocolShare
        );

        return netPurchasePrice;
    }

    /// @param borrower The address of the borrower
    /// @param rolloverSettlementAmount The amount of net proceeds received from new TermRepo to pay down existing repurchase obligation due to old Term Repo
    /// @return A uint256 representing the proportion of total repurchase due to old Term Repo from borrower settled by proceeds from new TermRepo
    function closeExposureOnRolloverExisting(
        address borrower,
        uint256 rolloverSettlementAmount
    ) external onlyRole(ROLLOVER_TARGET_AUCTIONEER_ROLE) returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp < maturityTimestamp) {
            revert NotMaturedYet();
        }
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp >= endOfRepurchaseWindow) {
            revert AfterRepurchaseWindow();
        }
        uint256 proportionPaid;
        if (rolloverSettlementAmount >= repurchaseExposureLedger[borrower]) {
            proportionPaid = expScale;
        } else {
            proportionPaid =
                (rolloverSettlementAmount * expScale) /
                repurchaseExposureLedger[borrower];
        }

        //NOTE: Prevent overflow errors in the case purchasePrice > remaining borrow balance
        if (rolloverSettlementAmount > repurchaseExposureLedger[borrower]) {
            totalOutstandingRepurchaseExposure -= repurchaseExposureLedger[
                borrower
            ];

            totalRepurchaseCollected += repurchaseExposureLedger[borrower];

            emitter.emitExposureClosedOnRolloverExisting(
                termRepoId,
                borrower,
                repurchaseExposureLedger[borrower]
            );
            // slither-disable-start reentrancy-no-eth
            repurchaseExposureLedger[borrower] = 0;
            // slither-disable-end reentrancy-no-eth
        } else {
            repurchaseExposureLedger[borrower] -= rolloverSettlementAmount;
            totalOutstandingRepurchaseExposure -= rolloverSettlementAmount;
            totalRepurchaseCollected += rolloverSettlementAmount;

            emitter.emitExposureClosedOnRolloverExisting(
                termRepoId,
                borrower,
                rolloverSettlementAmount
            );
        }

        assert(_isTermRepoBalanced());

        termRepoRolloverManager.fulfillRollover(borrower);

        return proportionPaid;
    }

    // ========================================================================
    // = Collateral Functions  ================================================
    // ========================================================================

    /// @param borrower The address of the borrower
    /// @param liquidator The address of the liquidator
    /// @param amountToCover The amount of repurchase exposure to cover in liquidation
    function liquidatorCoverExposure(
        address borrower,
        address liquidator,
        uint256 amountToCover
    ) external onlyRole(COLLATERAL_MANAGER) {
        _repay(borrower, liquidator, amountToCover);
    }

    /// @param borrower The address of the borrower
    /// @param liquidator The address of the liquidator
    /// @param amountOfRepoToken The amount of term tokens used to cover in liquidation
    /// @return A uint256 representing purchase value of repo tokens burned
    function liquidatorCoverExposureWithRepoToken(
        address borrower,
        address liquidator,
        uint256 amountOfRepoToken
    ) external onlyRole(COLLATERAL_MANAGER) returns (uint256) {
        uint256 burnValue = termRepoToken.burnAndReturnValue(
            liquidator,
            amountOfRepoToken
        );
        if (burnValue > repurchaseExposureLedger[borrower]) {
            revert RepurchaseAmountTooHigh();
        }
        repurchaseExposureLedger[borrower] -= burnValue;
        totalOutstandingRepurchaseExposure -= burnValue;

        assert(_isTermRepoBalanced());

        return burnValue;
    }

    // ========================================================================
    // = Admin Functions ======================================================
    // ========================================================================

    /// @param authedUser The address of user granted acces to create mint exposure
    function grantMintExposureAccess(
        address authedUser
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(MINTER_ROLE, authedUser);
    }

    /// @param termAuctionGroup A struct containing contract addresses of a Term Auction deployment to pair for a reopening of a TermRepo
    function reopenToNewAuction(
        TermAuctionGroup calldata termAuctionGroup
    ) external onlyRole(INITIALIZER_ROLE) {
        _grantRole(
            AUCTION_LOCKER,
            address(termAuctionGroup.termAuctionOfferLocker)
        );
        _grantRole(AUCTIONEER, address(termAuctionGroup.auction));

        emitter.emitReopeningOfferLockerPaired(
            termRepoId,
            address(this),
            address(termAuctionGroup.termAuctionOfferLocker),
            address(termAuctionGroup.auction)
        );
    }

    // ========================================================================
    // = Internal Functions  ==================================================
    // ========================================================================

    /// @notice Truncation is by 4 decimal places due to the assumption that number of participants < 10000
    function _isTermRepoBalanced() internal view returns (bool) {
        if (shortfallHaircutMantissa == 0) {
            return
                (totalOutstandingRepurchaseExposure +
                    totalRepurchaseCollected) /
                    (10 ** 4) ==
                termRepoToken.totalRedemptionValue() / (10 ** 4);
        }

        // @note in the case of shortfall, purchase currency in termRepoLocker must balance the pro rata redemption value of remaining term repo tokens
        return
            (totalRepurchaseCollected) / (10 ** 4) ==
            mul_ScalarTruncate(
                Exp({mantissa: shortfallHaircutMantissa}),
                termRepoToken.totalRedemptionValue()
            ) /
                (10 ** 4);
    }

    function _getMaxRepaymentAroundRollover(
        address borrower
    ) internal view returns (uint256) {
        uint256 outstandingRolloverAmount;
        TermRepoRolloverElection
            memory rolloverElection = termRepoRolloverManager
                .getRolloverInstructions(borrower);
        if (
            rolloverElection.rolloverAmount == 0 || rolloverElection.processed
        ) {
            outstandingRolloverAmount = 0;
        } else {
            outstandingRolloverAmount = rolloverElection.rolloverAmount;
        }

        return repurchaseExposureLedger[borrower] - outstandingRolloverAmount;
    }

    // Reentrancy risk
    function _repay(
        address _borrower,
        address repayer_,
        uint256 amount_
    ) internal {
        if (amount_ > repurchaseExposureLedger[_borrower]) {
            revert RepurchaseAmountTooHigh();
        }
        repurchaseExposureLedger[_borrower] -= amount_;
        totalOutstandingRepurchaseExposure -= amount_;
        totalRepurchaseCollected += amount_;

        termRepoLocker.transferTokenFromWallet(
            repayer_,
            purchaseToken,
            amount_
        );

        assert(_isTermRepoBalanced());
    }

    function _parRedemption(address redeemer_, uint256 amount_) internal {
        uint256 redemptionValue = termRepoToken.burnAndReturnValue(
            redeemer_,
            amount_
        );

        if (redemptionValue <= totalRepurchaseCollected) {
            totalRepurchaseCollected -= redemptionValue;

            termRepoLocker.transferTokenToWallet(
                redeemer_,
                purchaseToken,
                redemptionValue
            );

            emitter.emitTermRepoTokensRedeemed(
                termRepoId,
                redeemer_,
                redemptionValue,
                0
            );
        } else {
            uint256 repurchaseRedeemed = totalRepurchaseCollected;
            totalRepurchaseCollected = 0;

            termRepoLocker.transferTokenToWallet(
                redeemer_,
                purchaseToken,
                repurchaseRedeemed
            );

            emitter.emitTermRepoTokensRedeemed(
                termRepoId,
                redeemer_,
                repurchaseRedeemed,
                0
            );
        }

        assert(_isTermRepoBalanced());
    }

    function _proRataRedemption(address redeemer_, uint256 amount_) internal {
        if (shortfallHaircutMantissa == 0) {
            shortfallHaircutMantissa = div_(
                Exp({mantissa: totalRepurchaseCollected * expScale}),
                Exp({
                    mantissa: (totalRepurchaseCollected +
                        totalOutstandingRepurchaseExposure) * expScale
                })
            ).mantissa;
        }

        // slither-disable-start reentrancy-no-eth
        uint256 redemptionAmount = termRepoToken.burnAndReturnValue(
            redeemer_,
            amount_
        );

        uint256 proRataRedemptionAmount = mul_ScalarTruncate(
            Exp({mantissa: shortfallHaircutMantissa}),
            redemptionAmount
        );

        if (proRataRedemptionAmount <= totalRepurchaseCollected) {
            totalRepurchaseCollected -= proRataRedemptionAmount;

            termRepoLocker.transferTokenToWallet(
                redeemer_,
                purchaseToken,
                proRataRedemptionAmount
            );

            emitter.emitTermRepoTokensRedeemed(
                termRepoId,
                redeemer_,
                proRataRedemptionAmount,
                expScale - shortfallHaircutMantissa
            );
        } else {
            uint256 repurchaseRedeemed = totalRepurchaseCollected;
            totalRepurchaseCollected = 0;

            termRepoLocker.transferTokenToWallet(
                redeemer_,
                purchaseToken,
                repurchaseRedeemed
            );

            emitter.emitTermRepoTokensRedeemed(
                termRepoId,
                redeemer_,
                repurchaseRedeemed,
                expScale - shortfallHaircutMantissa
            );
        }

        assert(_isTermRepoBalanced());
    }

    // solhint-disable no-empty-blocks
    ///@dev required override by the OpenZeppelin UUPS module
    function _authorizeUpgrade(
        address
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
    // solhint-enable no-empty-blocks
}