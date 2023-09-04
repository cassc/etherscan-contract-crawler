//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

import "./interfaces/ITermController.sol";
import "./interfaces/ITermEventEmitter.sol";
import "./interfaces/ITermRepoCollateralManager.sol";
import "./interfaces/ITermRepoCollateralManagerErrors.sol";
import "./interfaces/ITermRepoLocker.sol";
import "./interfaces/ITermRepoServicer.sol";
import "./interfaces/ITermRepoToken.sol";
import "./interfaces/ITermPriceOracle.sol";
import "./interfaces/ITermRepoRolloverManager.sol";

import "./lib/Collateral.sol";
import "./lib/ExponentialNoError.sol";
import "./lib/TermAuctionGroup.sol";

import "./TermPriceConsumerV3.sol";
import "./TermRepoLocker.sol";
import "./TermRepoServicer.sol";
import "./TermRepoToken.sol";
import "./lib/TermRepoRolloverElection.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/// @author TermLabs
/// @title Term Repo Collateral Manager
/// @notice This contract enforces margin maintenance rules for adding/withdrawing, repurchasing and liquidating collateral
/// @dev This contract belongs to the Term Servicer group of contracts and is specific to a Term Repo deployment
contract TermRepoCollateralManager is
    ITermRepoCollateralManager,
    ITermRepoCollateralManagerErrors,
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    ExponentialNoError
{
    // ========================================================================
    // = Access Role  =========================================================
    // ========================================================================

    bytes32 public constant AUCTION_LOCKER = keccak256("AUCTION_LOCKER");
    bytes32 public constant SERVICER_ROLE = keccak256("SERVICER_ROLE");
    bytes32 public constant ROLLOVER_MANAGER = keccak256("ROLLOVER_MANAGER");
    bytes32 public constant ROLLOVER_TARGET_AUCTIONEER_ROLE =
        keccak256("ROLLOVER_TARGET_AUCTIONEER_ROLE");
    bytes32 public constant INITIALIZER_ROLE = keccak256("INITIALIZER_ROLE");

    // ========================================================================
    // = State Variables  =====================================================
    // ========================================================================

    // Term Identifier
    bytes32 public termRepoId;

    // Boolean indicating if liquidations are paused
    bool public liquidationsPaused;

    // Boolean indicatting if term contracts paired
    bool internal termContractPaired;

    // Number of Collateral Tokens Accepted By Term
    uint8 public numOfAcceptedCollateralTokens;

    // De minimis margin threshold triggering full liquidation
    uint256 public deMinimisMarginThreshold;

    // Collateral Seizures Share for Protocol in Liquidations
    uint256 public liquidateDamangesDueToProtocol;

    //Max percentage collateralization of repurchase after liquidation
    uint256 public netExposureCapOnLiquidation;

    // Repo servicer within same term
    ITermRepoServicer internal termRepoServicer;

    // token used for purchase/loans
    address public purchaseToken;

    // consumer for Chainlink price feeds
    ITermPriceOracle internal termPriceOracle;

    // TermRepoLocker for term funds
    ITermRepoLocker public termRepoLocker;

    // Term Controller contract
    ITermController internal termController;

    // Term Event Emitter contract
    ITermEventEmitter internal emitter;

    //list of acceptable collateral token addresses
    address[] public collateralTokens;

    // mapping of encumbered collateral balances
    mapping(address => uint256) internal encumberedCollateralBalances;

    // maintenance collateral ratios applicable to accepted collateral token basket
    mapping(address => uint256) public maintenanceCollateralRatios;

    // initial collateral ratios applicable to accepted collateral token basket
    mapping(address => uint256) public initialCollateralRatios;

    // liquidated damages schedule applicable to collateral token basket
    mapping(address => uint256) public liquidatedDamages;

    // Locked Collateral Balance Ledger
    // For each wallet address, keep ledger of collateral balances of different token addresses
    mapping(address => mapping(address => uint256))
        internal lockedCollateralLedger;

    // ========================================================================
    // = Modifiers  ===========================================================
    // ========================================================================

    modifier isCollateralTokenAccepted(address token) {
        if (!_isAcceptedCollateralToken(token)) {
            revert CollateralTokenNotAllowed(token);
        }
        _;
    }

    modifier whileLiquidationsNotPaused() {
        if (liquidationsPaused) {
            revert LiquidationsPaused();
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
    // = Deploy  ==============================================================
    // ========================================================================

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string calldata termRepoId_,
        uint256 liquidateDamangesDueToProtocol_,
        uint256 netExposureCapOnLiquidation_,
        uint256 deMinimisMarginThreshold_,
        address purchaseToken_,
        Collateral[] calldata collateralTokens_,
        ITermEventEmitter emitter_
    ) external initializer {
        UUPSUpgradeable.__UUPSUpgradeable_init();
        AccessControlUpgradeable.__AccessControl_init();

        termRepoId = keccak256(abi.encodePacked(termRepoId_));

        liquidationsPaused = false;

        // slither-disable-start reentrancy-no-eth events-maths
        liquidateDamangesDueToProtocol = liquidateDamangesDueToProtocol_;

        netExposureCapOnLiquidation = netExposureCapOnLiquidation_;
        deMinimisMarginThreshold = deMinimisMarginThreshold_;
        // slither-disable-end reentrancy-no-eth events-maths

        require(purchaseToken_ != address(0), "Zero address purchase token");
        purchaseToken = purchaseToken_;

        numOfAcceptedCollateralTokens = uint8(collateralTokens_.length);
        collateralTokens = new address[](collateralTokens_.length);

        for (uint256 i = 0; i < collateralTokens_.length; ++i) {
            collateralTokens[i] = collateralTokens_[i].tokenAddress;
            maintenanceCollateralRatios[
                collateralTokens_[i].tokenAddress
            ] = collateralTokens_[i].maintenanceRatio;
            initialCollateralRatios[
                collateralTokens_[i].tokenAddress
            ] = collateralTokens_[i].initialCollateralRatio;

            require(
                collateralTokens_[i].liquidatedDamage != 0,
                "Liquidated damage is zero"
            );
            liquidatedDamages[
                collateralTokens_[i].tokenAddress
            ] = collateralTokens_[i].liquidatedDamage;

            termContractPaired = false;
        }

        emitter = emitter_;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(INITIALIZER_ROLE, msg.sender);
    }

    function pairTermContracts(
        address termRepoLocker_,
        address termRepoServicer_,
        address termAuctionBidLocker_,
        address termAuction_,
        address termController_,
        address termPriceOracle_,
        address termRepoRolloverManager_
    ) external onlyRole(INITIALIZER_ROLE) notTermContractPaired {
        termRepoLocker = TermRepoLocker(termRepoLocker_);
        termRepoServicer = TermRepoServicer(termRepoServicer_);
        termPriceOracle = TermPriceConsumerV3(termPriceOracle_);
        termController = ITermController(termController_);

        _grantRole(AUCTION_LOCKER, termAuctionBidLocker_);
        _grantRole(AUCTION_LOCKER, termAuction_);
        _grantRole(AUCTION_LOCKER, termRepoServicer_);
        _grantRole(SERVICER_ROLE, termRepoServicer_);
        _grantRole(ROLLOVER_MANAGER, termRepoRolloverManager_);

        uint256[] memory maintenanceRatioList = new uint256[](
            collateralTokens.length
        );
        uint256[] memory initialCollateralRatioList = new uint256[](
            collateralTokens.length
        );
        uint256[] memory liquidatedDamagesList = new uint256[](
            collateralTokens.length
        );
        for (uint256 i = 0; i < collateralTokens.length; ++i) {
            maintenanceRatioList[i] = maintenanceCollateralRatios[
                collateralTokens[i]
            ];

            initialCollateralRatioList[i] = initialCollateralRatios[
                collateralTokens[i]
            ];

            liquidatedDamagesList[i] = liquidatedDamages[collateralTokens[i]];
        }

        emitter.emitTermRepoCollateralManagerInitialized(
            termRepoId,
            address(this),
            collateralTokens,
            initialCollateralRatioList,
            maintenanceRatioList,
            liquidatedDamagesList
        );
    }

    // ========================================================================
    // = APIs  ================================================================
    // ========================================================================

    /// @param collateralToken The address of the collateral token to lock
    /// @param amount The amount of collateral token to lock
    function externalLockCollateral(
        address collateralToken,
        uint256 amount
    ) external isCollateralTokenAccepted(collateralToken) {
        address borrower = msg.sender;

        if (block.timestamp > termRepoServicer.endOfRepurchaseWindow()) {
            revert CollateralDepositClosed();
        }

        if (termRepoServicer.getBorrowerRepurchaseObligation(borrower) == 0) {
            revert ZeroBorrowerRepurchaseObligation();
        }

        _lockCollateral(borrower, collateralToken, amount);
    }

    /// @param collateralToken The address of the collateral token to unlock
    /// @param amount The amount of collateral token to unlock
    function externalUnlockCollateral(
        address collateralToken,
        uint256 amount
    ) external isCollateralTokenAccepted(collateralToken) {
        address borrower = msg.sender;

        if (amount == 0) {
            revert InvalidParameters("Zero amount");
        }

        if (lockedCollateralLedger[borrower][collateralToken] == 0) {
            revert ZeroCollateralBalance();
        }
        if (
            // solhint-disable-next-line not-rely-on-time
            block.timestamp >= termRepoServicer.endOfRepurchaseWindow() &&
            block.timestamp < termRepoServicer.redemptionTimestamp()
        ) {
            revert CollateralWithdrawalClosed();
        }
        bool decrementEncumberedCollateral;

        // if borrow balance is zero, collateral has already been unencumbered through liquidation
        if (termRepoServicer.getBorrowerRepurchaseObligation(borrower) != 0) {
            decrementEncumberedCollateral = true;
        }
        _unlockCollateral(
            borrower,
            collateralToken,
            amount,
            decrementEncumberedCollateral
        );
        if (isBorrowerInShortfall(borrower)) {
            revert CollateralBelowMaintenanceRatios(borrower, collateralToken);
        }
    }

    /// @param borrower The address of the borrower
    /// @param closureAmounts An array specifying the amounts of Term Repo exposure the liquidator proposes to cover in liquidation; an amount is required to be specified for each collateral token
    function batchLiquidation(
        address borrower,
        uint256[] calldata closureAmounts
    ) external whileLiquidationsNotPaused {
        bool allowFullLiquidation = _validateBatchLiquidationForFullLiquidation(
            borrower,
            msg.sender,
            closureAmounts
        );

        uint256 totalClosureAmount = 0;

        uint256 collateralSeizureAmount;
        uint256 collateralSeizureProtocolShare;

        for (uint256 i = 0; i < closureAmounts.length; ++i) {
            if (closureAmounts[i] == 0) {
                continue;
            }
            if (closureAmounts[i] == type(uint256).max) {
                revert InvalidParameters("closureAmounts cannot be uint max");
            }
            totalClosureAmount += closureAmounts[i];

            termRepoServicer.liquidatorCoverExposure(
                borrower,
                msg.sender,
                closureAmounts[i]
            );

            (
                collateralSeizureAmount,
                collateralSeizureProtocolShare
            ) = _collateralSeizureAmounts(
                closureAmounts[i],
                collateralTokens[i]
            );

            _transferLiquidationCollateral(
                borrower,
                msg.sender,
                collateralTokens[i],
                closureAmounts[i],
                collateralSeizureAmount,
                collateralSeizureProtocolShare,
                false
            );
        }

        if (totalClosureAmount == 0) {
            revert ZeroLiquidationNotPermitted();
        }

        /// allow any liquidations if within margin minimum
        if (!allowFullLiquidation) {
            if (!_withinNetExposureCapOnLiquidation(borrower)) {
                revert ExceedsNetExposureCapOnLiquidation();
            }
        }

        // unencumber all collateral tokens owned by borrower if balance paid off
        if (termRepoServicer.getBorrowerRepurchaseObligation(borrower) == 0) {
            _unencumberRemainingBorrowerCollateralOnZeroObligation(borrower);
        }
    }

    /// @param borrower The address of the borrower
    /// @param closureRepoTokenAmounts An array specifying the amounts of Term Repo Tokens the liquidator proposes to cover borrower repo exposure in liquidation; an amount is required to be specified for each collateral token
    function batchLiquidationWithRepoToken(
        address borrower,
        uint256[] calldata closureRepoTokenAmounts
    ) external whileLiquidationsNotPaused {
        bool allowFullLiquidation = _validateBatchLiquidationForFullLiquidation(
            borrower,
            msg.sender,
            closureRepoTokenAmounts
        );

        uint256 totalClosureRepoTokenAmounts = 0;

        uint256 closureValue;

        uint256 collateralSeizureAmount;
        uint256 collateralSeizureProtocolShare;

        for (uint256 i = 0; i < closureRepoTokenAmounts.length; ++i) {
            if (closureRepoTokenAmounts[i] == 0) {
                continue;
            }
            if (closureRepoTokenAmounts[i] == type(uint256).max) {
                revert InvalidParameters(
                    "closureRepoTokenAmounts cannot be uint max"
                );
            }
            totalClosureRepoTokenAmounts += closureRepoTokenAmounts[i];

            closureValue = termRepoServicer
                .liquidatorCoverExposureWithRepoToken(
                    borrower,
                    msg.sender,
                    closureRepoTokenAmounts[i]
                );

            (
                collateralSeizureAmount,
                collateralSeizureProtocolShare
            ) = _collateralSeizureAmounts(closureValue, collateralTokens[i]);

            _transferLiquidationCollateral(
                borrower,
                msg.sender,
                collateralTokens[i],
                closureRepoTokenAmounts[i],
                collateralSeizureAmount,
                collateralSeizureProtocolShare,
                false
            );
        }

        if (totalClosureRepoTokenAmounts == 0) {
            revert ZeroLiquidationNotPermitted();
        }

        /// allow any liquidations if within margin minimum
        if (!allowFullLiquidation) {
            if (!_withinNetExposureCapOnLiquidation(borrower)) {
                revert ExceedsNetExposureCapOnLiquidation();
            }
        }

        // unencumber all collateral tokens owned by borrower if balance paid off
        if (termRepoServicer.getBorrowerRepurchaseObligation(borrower) == 0) {
            _unencumberRemainingBorrowerCollateralOnZeroObligation(borrower);
        }
    }

    /// @param borrower The address of the borrower
    /// @param closureAmounts An array specifying the amounts of Term Repo exposure the liquidator proposes to cover in liquidation; an amount is required to be specified for each collateral token
    function batchDefault(
        address borrower,
        uint256[] calldata closureAmounts
    ) external whileLiquidationsNotPaused {
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp <= termRepoServicer.endOfRepurchaseWindow()) {
            revert DefaultsClosed();
        }
        if (msg.sender == borrower) {
            revert SelfLiquidationNotPermitted();
        }
        if (collateralTokens.length != closureAmounts.length) {
            revert InvalidParameters(
                "Closure amounts array not same length as collateral tokens list"
            );
        }

        uint256 totalClosureAmount = 0;
        uint256 borrowerRepurchaseObligation = termRepoServicer
            .getBorrowerRepurchaseObligation(borrower);

        if (borrowerRepurchaseObligation == 0) {
            revert ZeroBorrowerRepurchaseObligation();
        }

        uint256 collateralSeizureAmount;

        uint256 collateralSeizureProtocolShare;

        for (uint256 i = 0; i < closureAmounts.length; ++i) {
            if (closureAmounts[i] == 0) {
                continue;
            }
            if (closureAmounts[i] == type(uint256).max) {
                revert InvalidParameters("closureAmounts cannot be uint max");
            }
            totalClosureAmount += closureAmounts[i];

            if (totalClosureAmount > borrowerRepurchaseObligation) {
                revert TotalRepaymentGreaterThangetBorrowerRepurchaseObligation();
            }

            termRepoServicer.liquidatorCoverExposure(
                borrower,
                msg.sender,
                closureAmounts[i]
            );

            (
                collateralSeizureAmount,
                collateralSeizureProtocolShare
            ) = _collateralSeizureAmounts(
                closureAmounts[i],
                collateralTokens[i]
            );

            _transferLiquidationCollateral(
                borrower,
                msg.sender,
                collateralTokens[i],
                closureAmounts[i],
                collateralSeizureAmount,
                collateralSeizureProtocolShare,
                true
            );
        }

        if (totalClosureAmount == 0) {
            revert ZeroLiquidationNotPermitted();
        }

        // unencumber all collateral tokens owned by borrower if balance paid off
        if (termRepoServicer.getBorrowerRepurchaseObligation(borrower) == 0) {
            _unencumberRemainingBorrowerCollateralOnZeroObligation(borrower);
        }
    }

    /// @param collateralToken The collateral token address of tokens locked
    /// @param amountToLock The amount of collateral tokens to lock
    function calculateMintableExposure(
        address collateralToken,
        uint256 amountToLock
    ) external view returns (Exp memory) {
        return
            div_(
                div_(
                    termPriceOracle.usdValueOfTokens(
                        collateralToken,
                        amountToLock
                    ),
                    Exp({mantissa: initialCollateralRatios[collateralToken]})
                ),
                termPriceOracle.usdValueOfTokens(purchaseToken, 1)
            );
    }

    /// @param borrower The address of the borrower
    /// @return An array of collateral token addresses
    /// @return An array collateral token balances locked on behalf of borrower
    function getCollateralBalances(
        address borrower
    ) external view returns (address[] memory, uint256[] memory) {
        address[] memory collateralTokensOwnedByBorrower = new address[](
            collateralTokens.length
        );
        uint256[] memory collateralBalancesOwnedByBorrower = new uint256[](
            collateralTokens.length
        );
        for (uint256 i = 0; i < collateralTokens.length; ++i) {
            address collateralToken = collateralTokens[i];
            uint256 collateralAmount = lockedCollateralLedger[borrower][
                collateralToken
            ];
            collateralTokensOwnedByBorrower[i] = collateralToken;
            collateralBalancesOwnedByBorrower[i] = collateralAmount;
        }
        return (
            collateralTokensOwnedByBorrower,
            collateralBalancesOwnedByBorrower
        );
    }

    /// @param borrower The address of the borrower
    /// @param collateralToken The collateral token address to query
    /// @return uint256 The amount of collateralToken locked on behalf of borrower
    function getCollateralBalance(
        address borrower,
        address collateralToken
    ) external view returns (uint256) {
        return lockedCollateralLedger[borrower][collateralToken];
    }

    /// @return bool A boolean that tests whether any encumbered collateral remains locked
    function encumberedCollateralRemaining() external view returns (bool) {
        for (uint256 i = 0; i < collateralTokens.length; ++i) {
            if (encumberedCollateralBalances[collateralTokens[i]] > 0) {
                return true;
            }
        }
        return false;
    }

    // ========================================================================
    // = Auction Functions  ===================================================
    // ========================================================================

    /// @param bidder The bidder's address
    /// @param collateralToken The address of the token to be used as collateral
    /// @param amount The amount of the token to lock
    function auctionLockCollateral(
        address bidder,
        address collateralToken,
        uint256 amount
    ) external onlyRole(AUCTION_LOCKER) {
        termRepoLocker.transferTokenFromWallet(bidder, collateralToken, amount);
    }

    /// @param bidder The bidder's address
    /// @param collateralToken The address of the token used as collateral
    /// @param amount The amount of collateral tokens to unlock
    function auctionUnlockCollateral(
        address bidder,
        address collateralToken,
        uint256 amount
    ) external onlyRole(AUCTION_LOCKER) {
        termRepoLocker.transferTokenToWallet(bidder, collateralToken, amount);
    }

    // ========================================================================
    // = Rollover Functions  ==================================================
    // ========================================================================

    /// @param borrower The address of the borrower
    /// @param collateralToken The address of a collateral token
    /// @param amount The amount of collateral tokens to lock
    function acceptRolloverCollateral(
        address borrower,
        address collateralToken,
        uint256 amount
    ) external onlyRole(AUCTION_LOCKER) {
        lockedCollateralLedger[borrower][collateralToken] += amount;
        encumberedCollateralBalances[collateralToken] += amount;

        emitter.emitCollateralLocked(
            termRepoId,
            borrower,
            collateralToken,
            amount
        );
    }

    /// @param borrower The borrower's address
    /// @param rolloverProportion The proportion of the collateral to be unlocked, equal to the proportion of the collateral repaid
    /// @param rolloverTermRepoLocker The address of the new TermRepoLocker contract to roll into
    /// @return An array representing a list of accepted collateral token addresses
    /// @return An array containing the amount of collateral tokens to pairoff and transfer to new TermRepoLocker to roll into
    function transferRolloverCollateral(
        address borrower,
        uint256 rolloverProportion,
        address rolloverTermRepoLocker
    )
        external
        onlyRole(ROLLOVER_TARGET_AUCTIONEER_ROLE)
        returns (address[] memory, uint256[] memory)
    {
        return (
            collateralTokens,
            _partialUnlockCollateral(
                borrower,
                rolloverProportion,
                rolloverTermRepoLocker
            )
        );
    }

    /// @param rolloverAuction The address of the rollover auction
    function approveRolloverAuction(
        address rolloverAuction
    ) external onlyRole(ROLLOVER_MANAGER) {
        _grantRole(ROLLOVER_TARGET_AUCTIONEER_ROLE, rolloverAuction);
    }

    // ========================================================================
    // = Servicer Functions  ========================================
    // ========================================================================

    /// @param borrower The address of the borrower
    function unlockCollateralOnRepurchase(
        address borrower
    ) external onlyRole(SERVICER_ROLE) {
        for (uint256 i = 0; i < collateralTokens.length; ++i) {
            address collateralToken = collateralTokens[i];
            uint256 collateralAmount = lockedCollateralLedger[borrower][
                collateralToken
            ];

            if (collateralAmount > 0) {
                _unlockCollateral(
                    borrower,
                    collateralToken,
                    collateralAmount,
                    true
                );
            }
        }
    }

    /// @param borrower The address of the borrower
    /// @param collateralTokenAddresses Collateral token addresses
    /// @param collateralTokenAmounts Collateral token amounts
    function journalBidCollateralToCollateralManager(
        address borrower,
        address[] calldata collateralTokenAddresses,
        uint256[] calldata collateralTokenAmounts
    ) external onlyRole(SERVICER_ROLE) {
        for (uint256 i = 0; i < collateralTokenAddresses.length; ++i) {
            lockedCollateralLedger[borrower][
                collateralTokenAddresses[i]
            ] += collateralTokenAmounts[i];
            encumberedCollateralBalances[
                collateralTokenAddresses[i]
            ] += collateralTokenAmounts[i];

            emitter.emitCollateralLocked(
                termRepoId,
                borrower,
                collateralTokenAddresses[i],
                collateralTokenAmounts[i]
            );
        }
    }

    /// @param borrower The address of the borrower
    /// @param collateralToken Collateral token addresse
    /// @param amount Collateral token amount
    function mintOpenExposureLockCollateral(
        address borrower,
        address collateralToken,
        uint256 amount
    ) external onlyRole(SERVICER_ROLE) {
        _lockCollateral(borrower, collateralToken, amount);
    }

    // ========================================================================
    // = Admin Functions ======================================================
    // ========================================================================

    /// @param termAuctionGroup A struct of auction contracts
    function reopenToNewAuction(
        TermAuctionGroup calldata termAuctionGroup
    ) external onlyRole(INITIALIZER_ROLE) {
        _grantRole(
            AUCTION_LOCKER,
            address(termAuctionGroup.termAuctionBidLocker)
        );

        _grantRole(AUCTION_LOCKER, address(termAuctionGroup.auction));

        termPriceOracle.reOpenToNewBidLocker(
            address(termAuctionGroup.termAuctionBidLocker)
        );

        emitter.emitPairReopeningBidLocker(
            termRepoId,
            address(this),
            address(termAuctionGroup.termAuctionBidLocker)
        );
    }

    function pauseLiquidations() external onlyRole(DEFAULT_ADMIN_ROLE) {
        liquidationsPaused = true;
        emitter.emitLiquidationPaused(termRepoId);
    }

    function unpauseLiquidations() external onlyRole(DEFAULT_ADMIN_ROLE) {
        liquidationsPaused = false;
        emitter.emitLiquidationUnpaused(termRepoId);
    }

    // ========================================================================
    // = Public Functions  ====================================================
    // ========================================================================

    /// @param borrower The address of the borrower
    /// @return Boolean testing whether the given borrower is in shortfall or margin deficit
    function isBorrowerInShortfall(
        address borrower
    ) public view returns (bool) {
        Exp memory repurchasePriceUSDValue = termPriceOracle.usdValueOfTokens(
            purchaseToken,
            termRepoServicer.getBorrowerRepurchaseObligation(borrower)
        );
        Exp memory haircutUSDTotalCollateralValue = Exp({mantissa: 0});
        for (uint256 i = 0; i < collateralTokens.length; ++i) {
            address collateralToken = collateralTokens[i];
            Exp memory additionalHairCutUSDCollateralValue = div_(
                termPriceOracle.usdValueOfTokens(
                    collateralToken,
                    lockedCollateralLedger[borrower][collateralToken]
                ),
                Exp({mantissa: maintenanceCollateralRatios[collateralToken]})
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

    /// @param borrower The address of the borrower
    /// @return The market value of borrower's locked collateral denominated in USD
    function getCollateralMarketValue(
        address borrower
    ) public view returns (uint256) {
        return _usdValueOfBalances(lockedCollateralLedger[borrower]);
    }

    // ========================================================================
    // = Internal Functions  ==================================================
    // ========================================================================
    function _lockCollateral(
        address borrower,
        address collateralToken,
        uint256 amount
    ) internal {
        lockedCollateralLedger[borrower][collateralToken] += amount;
        encumberedCollateralBalances[collateralToken] += amount;
        termRepoLocker.transferTokenFromWallet(
            borrower,
            collateralToken,
            amount
        );

        emitter.emitCollateralLocked(
            termRepoId,
            borrower,
            collateralToken,
            amount
        );
    }

    function _unlockCollateral(
        address borrower,
        address collateralToken,
        uint256 amount,
        bool decrementEncumberedCollateral
    ) internal {
        if (amount > lockedCollateralLedger[borrower][collateralToken]) {
            revert UnlockAmountGreaterThanCollateralBalance();
        }
        lockedCollateralLedger[borrower][collateralToken] -= amount;
        if (decrementEncumberedCollateral) {
            encumberedCollateralBalances[collateralToken] -= amount;
        }
        termRepoLocker.transferTokenToWallet(borrower, collateralToken, amount);

        emitter.emitCollateralUnlocked(
            termRepoId,
            borrower,
            collateralToken,
            amount
        );
    }

    function _partialUnlockCollateral(
        address borrower,
        uint256 unlockProportion,
        address destinationwallet
    ) internal returns (uint256[] memory) {
        uint256[] memory unlockedCollateral = new uint256[](
            collateralTokens.length
        );
        for (uint256 i = 0; i < collateralTokens.length; ++i) {
            address collateralToken = collateralTokens[i];
            uint256 collateralAmount = lockedCollateralLedger[borrower][
                collateralToken
            ];

            if (collateralAmount > 0) {
                if (unlockProportion == expScale) {
                    uint256 unlockedAmount = lockedCollateralLedger[borrower][
                        collateralToken
                    ];
                    // slither-disable-start reentrancy-no-eth
                    lockedCollateralLedger[borrower][collateralToken] = 0;
                    unlockedCollateral[i] = unlockedAmount;
                    encumberedCollateralBalances[
                        collateralToken
                    ] -= unlockedAmount;
                    // slither-disable-end reentrancy-no-eth

                    termRepoLocker.transferTokenToWallet(
                        destinationwallet,
                        collateralToken,
                        unlockedAmount
                    );
                    emitter.emitCollateralUnlocked(
                        termRepoId,
                        borrower,
                        collateralToken,
                        unlockedAmount
                    );
                } else {
                    uint256 proportionToUnlock = mul_ScalarTruncate(
                        Exp({mantissa: unlockProportion}),
                        collateralAmount
                    );
                    // slither-disable-start reentrancy-no-eth
                    lockedCollateralLedger[borrower][
                        collateralToken
                    ] -= proportionToUnlock;
                    unlockedCollateral[i] = proportionToUnlock;
                    encumberedCollateralBalances[
                        collateralToken
                    ] -= proportionToUnlock;
                    // slither-disable-end reentrancy-no-eth

                    termRepoLocker.transferTokenToWallet(
                        destinationwallet,
                        collateralToken,
                        proportionToUnlock
                    );
                    emitter.emitCollateralUnlocked(
                        termRepoId,
                        borrower,
                        collateralToken,
                        proportionToUnlock
                    );
                }
            }
        }
        return unlockedCollateral;
    }

    /// @dev A helper function to validate various conditions required to liquidate
    /// @return A boolean for whether borrower position eligible for full liquidation
    function _validateBatchLiquidationForFullLiquidation(
        address borrower,
        address liquidator,
        uint256[] calldata closureTokenAmounts
    ) internal returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp > termRepoServicer.endOfRepurchaseWindow()) {
            revert ShortfallLiquidationsClosed();
        }
        if (liquidator == borrower) {
            revert SelfLiquidationNotPermitted();
        }
        if (collateralTokens.length != closureTokenAmounts.length) {
            revert InvalidParameters(
                "Closure amounts array not same length as collateral tokens list"
            );
        }
        uint256 borrowerRepurchaseObligation = termRepoServicer
            .getBorrowerRepurchaseObligation(borrower);
        if (borrowerRepurchaseObligation == 0) {
            revert ZeroBorrowerRepurchaseObligation();
        }
        bool allowFullLiquidation = getCollateralMarketValue(borrower) <
            termPriceOracle
                .usdValueOfTokens(purchaseToken, borrowerRepurchaseObligation)
                .mantissa +
                deMinimisMarginThreshold;

        if (!allowFullLiquidation && !isBorrowerInShortfall(borrower)) {
            revert BorrowerNotInShortfall();
        }
        return allowFullLiquidation;
    }

    function _unencumberRemainingBorrowerCollateralOnZeroObligation(
        address borrower
    ) internal {
        for (uint256 i = 0; i < collateralTokens.length; ++i) {
            encumberedCollateralBalances[
                collateralTokens[i]
            ] -= lockedCollateralLedger[borrower][collateralTokens[i]];
        }
    }

    function _withinNetExposureCapOnLiquidation(
        address borrower
    ) internal view returns (bool) {
        uint256 borrowerRepurchaseObligation = termRepoServicer
            .getBorrowerRepurchaseObligation(borrower);

        /// Borrower should not be liquidated to zero balance in this case.
        if (borrowerRepurchaseObligation == 0) {
            return false;
        }

        Exp memory haircutUSDTotalCollateralValue = Exp({mantissa: 0});
        for (uint256 i = 0; i < collateralTokens.length; ++i) {
            address collateralToken = collateralTokens[i];
            Exp memory additionalHairCutUSDCollateralValue = div_(
                termPriceOracle.usdValueOfTokens(
                    collateralToken,
                    lockedCollateralLedger[borrower][collateralToken]
                ),
                Exp({mantissa: initialCollateralRatios[collateralToken]})
            );
            haircutUSDTotalCollateralValue = add_(
                additionalHairCutUSDCollateralValue,
                haircutUSDTotalCollateralValue
            );
        }
        Exp memory borrowerRepurchaseValue = termPriceOracle.usdValueOfTokens(
            purchaseToken,
            borrowerRepurchaseObligation
        );

        if (
            lessThanExp(haircutUSDTotalCollateralValue, borrowerRepurchaseValue)
        ) {
            return true;
        }
        Exp memory excessEquity = sub_(
            haircutUSDTotalCollateralValue,
            borrowerRepurchaseValue
        );

        return
            lessThanOrEqualExp(
                div_(excessEquity, borrowerRepurchaseValue),
                Exp({mantissa: netExposureCapOnLiquidation})
            );
    }

    ///@dev returns total amount of collateral seized in liquidation and the amount of that total going protocol
    function _collateralSeizureAmounts(
        uint256 amountToCover_,
        address collateralToken
    ) internal view returns (uint256, uint256) {
        IERC20MetadataUpgradeable tokenInstance = IERC20MetadataUpgradeable(
            collateralToken
        );
        Exp memory usdValueOfCoverAmount = termPriceOracle.usdValueOfTokens(
            purchaseToken,
            amountToCover_
        );
        Exp memory latestPriceValueCollateralAmount = div_(
            usdValueOfCoverAmount,
            termPriceOracle.usdValueOfTokens(
                collateralToken,
                10 ** (tokenInstance.decimals())
            )
        );

        Exp memory collateralAmountWithDiscount = mul_(
            latestPriceValueCollateralAmount,
            add_(
                Exp({mantissa: expScale}),
                Exp({mantissa: liquidatedDamages[collateralToken]})
            )
        );

        Exp memory protocolSeizureAmount = mul_(
            latestPriceValueCollateralAmount,
            Exp({mantissa: liquidateDamangesDueToProtocol})
        );

        // this is equivalent to usdValueOfClosureAmount / discountedPriceofCollateralToken
        return (
            collateralAmountWithDiscount.mantissa /
                10 ** (18 - tokenInstance.decimals()),
            protocolSeizureAmount.mantissa /
                10 ** (18 - tokenInstance.decimals())
        );
    }

    /// @dev A helper function to transfer tokens and update relevant state variables and mappings
    function _transferLiquidationCollateral(
        address borrower,
        address liquidator,
        address collateralAddress,
        uint256 closureAmount,
        uint256 collateralSeizureAmount,
        uint256 collateralSeizureProtocolShare,
        bool isDefault
    ) internal {
        if (
            collateralSeizureAmount >
            lockedCollateralLedger[borrower][collateralAddress]
        ) {
            revert InsufficientCollateralForLiquidationRepayment(
                collateralAddress
            );
        }
        // slither-disable-start reentrancy-no-eth
        lockedCollateralLedger[borrower][
            collateralAddress
        ] -= collateralSeizureAmount;

        encumberedCollateralBalances[
            collateralAddress
        ] -= collateralSeizureAmount;
        // slither-disable-end reentrancy-no-eth

        termRepoLocker.transferTokenToWallet(
            termController.getProtocolReserveAddress(),
            collateralAddress,
            collateralSeizureProtocolShare
        );

        termRepoLocker.transferTokenToWallet(
            liquidator,
            collateralAddress,
            collateralSeizureAmount - collateralSeizureProtocolShare // Liquidation yield
        );

        emitter.emitLiquidation(
            termRepoId,
            borrower,
            liquidator,
            closureAmount,
            collateralAddress,
            collateralSeizureAmount,
            collateralSeizureProtocolShare,
            isDefault
        );
    }

    function _isAcceptedCollateralToken(
        address token_
    ) internal view returns (bool) {
        if (liquidatedDamages[token_] == 0) {
            return false;
        }
        return true;
    }

    function _usdValueOfBalances(
        mapping(address => uint256) storage _tokenBalances
    ) internal view returns (uint256) {
        Exp memory totalValue = Exp({mantissa: 0});
        for (uint256 i = 0; i < collateralTokens.length; ++i) {
            totalValue = add_(
                totalValue,
                termPriceOracle.usdValueOfTokens(
                    collateralTokens[i],
                    _tokenBalances[collateralTokens[i]]
                )
            );
        }
        return totalValue.mantissa;
    }

    // solhint-disable no-empty-blocks
    ///@dev required override by the OpenZeppelin UUPS module
    function _authorizeUpgrade(
        address
    ) internal view override onlyRole(DEFAULT_ADMIN_ROLE) {}
    // solhint-enable no-empty-blocks
}