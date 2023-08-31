//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

import "./interfaces/ITermAuctionBidLocker.sol";
import "./interfaces/ITermAuctionOfferLocker.sol";
import "./interfaces/ITermEventEmitter.sol";
import "./interfaces/ITermRepoRolloverManager.sol";
import "./interfaces/ITermRepoRolloverManagerErrors.sol";
import "./interfaces/ITermRepoCollateralManager.sol";
import "./interfaces/ITermRepoServicer.sol";
import "./interfaces/ITermController.sol";

import "./lib/ExponentialNoError.sol";
import "./lib/TermAuctionBid.sol";
import "./lib/TermRepoRolloverElection.sol";
import "./lib/TermRepoRolloverElectionSubmission.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/// @author TermLabs
/// @title Term Repo Rollover Manager
/// @notice This contract accepts and carries out borrower Term Repo rollover instructions
/// @dev This contract belongs to the Term Servicer group of contracts and is specific to a Term Repo deployment
contract TermRepoRolloverManager is
    ITermRepoRolloverManager,
    ITermRepoRolloverManagerErrors,
    ExponentialNoError,
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable
{
    // ========================================================================
    // = Access Role  =========================================================
    // ========================================================================

    bytes32 public constant ROLLOVER_BID_FULFILLER_ROLE =
        keccak256("ROLLOVER_BID_FULFILLER_ROLE");
    bytes32 public constant INITIALIZER_ROLE = keccak256("INITIALIZER_ROLE");

    // ========================================================================
    // = State Variables ======================================================
    // ========================================================================
    bytes32 public termRepoId;
    ITermRepoCollateralManager internal termRepoCollateralManager;
    ITermRepoServicer internal termRepoServicer;
    ITermController internal termController;
    ITermEventEmitter internal emitter;

    // Mapping that returns true for approved Borrower Rollover Auctions
    mapping(address => bool) internal approvedRolloverAuctions;

    // Borrow Rollover Ledger
    // For each borrower wallet address, keep ledger of borrow rollver election addresses.
    mapping(address => TermRepoRolloverElection) internal rolloverElections;

    bool internal termContractPaired;

    // ========================================================================
    // = Modifiers ============================================================
    // ========================================================================

    modifier whileNotMatured() {
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp >= termRepoServicer.maturityTimestamp()) {
            revert MaturityReached();
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
        ITermRepoServicer termRepoServicer_,
        ITermRepoCollateralManager termRepoCollateralManager_,
        ITermController termController_
    ) external initializer {
        UUPSUpgradeable.__UUPSUpgradeable_init();
        AccessControlUpgradeable.__AccessControl_init();

        termRepoId = keccak256(abi.encodePacked(termRepoId_));
        termRepoCollateralManager = termRepoCollateralManager_;
        termRepoServicer = termRepoServicer_;
        termController = termController_;

        termContractPaired = false;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(INITIALIZER_ROLE, msg.sender);
    }

    function pairTermContracts(
        address termRepoServicer_,
        ITermEventEmitter emitter_
    ) external onlyRole(INITIALIZER_ROLE) notTermContractPaired {
        emitter = emitter_;
        _grantRole(ROLLOVER_BID_FULFILLER_ROLE, termRepoServicer_);

        emitter.emitTermRepoRolloverManagerInitialized(
            termRepoId,
            address(this)
        );
    }

    // ========================================================================
    // = APIs  ================================================================
    // ========================================================================

    /// @notice An external function that accepted Term Repo rollover instructions
    /// @param termRepoRolloverElectionSubmission A struct containing borrower rollover instructions
    function electRollover(
        TermRepoRolloverElectionSubmission
            calldata termRepoRolloverElectionSubmission
    ) external whileNotMatured {
        address borrower = msg.sender;
        uint256 borrowerRepurchaseObligation = termRepoServicer
            .getBorrowerRepurchaseObligation(borrower);
        if (borrowerRepurchaseObligation == 0) {
            revert ZeroBorrowerRepurchaseObligation();
        }
        if (
            !approvedRolloverAuctions[
                termRepoRolloverElectionSubmission.rolloverAuction
            ]
        ) {
            revert RolloverAddressNotApproved(
                termRepoRolloverElectionSubmission.rolloverAuction
            );
        }

        if (rolloverElections[borrower].locked) {
            revert RolloverLockedToAuction();
        }

        if (rolloverElections[borrower].processed) {
            revert RolloverProcessedToTerm();
        }

        if (termRepoRolloverElectionSubmission.rolloverAmount == 0) {
            revert InvalidParameters("Rollover amount cannot be 0");
        }

        if (
            borrowerRepurchaseObligation <
            termRepoRolloverElectionSubmission.rolloverAmount
        ) {
            revert BorrowerRepurchaseObligationInsufficient();
        }

        rolloverElections[borrower] = TermRepoRolloverElection({
            rolloverAuction: termRepoRolloverElectionSubmission.rolloverAuction,
            rolloverAmount: termRepoRolloverElectionSubmission.rolloverAmount,
            rolloverBidPriceHash: termRepoRolloverElectionSubmission
                .rolloverBidPriceHash,
            locked: false,
            processed: false
        });

        ITermAuctionBidLocker auctionBidLocker = ITermAuctionBidLocker(
            termRepoRolloverElectionSubmission.rolloverAuction
        );

        emitter.emitRolloverElection(
            termRepoId,
            auctionBidLocker.termRepoId(),
            borrower,
            termRepoRolloverElectionSubmission.rolloverAuction,
            termRepoRolloverElectionSubmission.rolloverAmount,
            termRepoRolloverElectionSubmission.rolloverBidPriceHash
        );
    }

    /// @notice A view function that returns borrower rollover instructions
    /// @param borrower The address of the borrower
    /// @return A struct containing borrower rollover instructions
    function getRolloverInstructions(
        address borrower
    ) external view returns (TermRepoRolloverElection memory) {
        return rolloverElections[borrower];
    }

    /// @notice An external function to cancel previously submitted rollover instructions
    function cancelRollover() external {
        address borrower = msg.sender;
        if (termRepoServicer.getBorrowerRepurchaseObligation(borrower) == 0) {
            revert ZeroBorrowerRepurchaseObligation();
        }

        if (rolloverElections[borrower].rolloverAmount == 0) {
            revert NoRolloverToCancel();
        }

        if (rolloverElections[borrower].locked) {
            revert RolloverLockedToAuction();
        }

        if (rolloverElections[borrower].processed) {
            revert RolloverProcessedToTerm();
        }

        delete rolloverElections[borrower];

        emitter.emitRolloverCancellation(termRepoId, borrower);
    }

    /// @notice An external function that submits rollover bids given a list of borrower addresses
    /// @param borrowersToRollover An array containing borrower addresses to process for rollover
    function batchProcessRollovers(
        address[] calldata borrowersToRollover
    ) external {
        if (
            // solhint-disable-next-line not-rely-on-time
            block.timestamp >= termRepoServicer.endOfRepurchaseWindow()
        ) {
            revert RepurchaseWindowOver();
        }

        for (uint256 i = 0; i < borrowersToRollover.length; ++i) {
            address borrower = borrowersToRollover[i];
            if (
                rolloverElections[borrower].rolloverAmount > 0 &&
                !rolloverElections[borrower].locked &&
                !rolloverElections[borrower].processed
            ) {
                _processRollover(borrowersToRollover[i]);
            }
        }
    }

    // ========================================================================
    // = Fulfiller Functions ================================================
    // ========================================================================

    /// @notice An external function called by repo servicer to mark rollover as fulfilled
    /// @param borrower The address of the borrower
    function fulfillRollover(
        address borrower
    ) external onlyRole(ROLLOVER_BID_FULFILLER_ROLE) {
        rolloverElections[borrower].processed = true;
        emitter.emitRolloverProcessed(termRepoId, borrower);
    }

    // ========================================================================
    // = Admin Functions ======================================================
    // ========================================================================

    /// @param auctionBidLocker The ABI for ITermAuctionBidLocker interface
    /// @param termAuction The address of TermAuction contract to mark as eligible for rollover
    function approveRolloverAuction(
        ITermAuctionBidLocker auctionBidLocker,
        address termAuction
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp >= termRepoServicer.maturityTimestamp()) {
            revert MaturityReached();
        }
        if (!termController.isTermDeployed(address(auctionBidLocker))) {
            revert NotTermContract(address(auctionBidLocker));
        }
        if (!termController.isTermDeployed(termAuction)) {
            revert NotTermContract(termAuction);
        }

        if (
            auctionBidLocker.auctionEndTime() >
            termRepoServicer.endOfRepurchaseWindow()
        ) {
            revert AuctionEndsAfterRepayment();
        }
        if (
            auctionBidLocker.auctionEndTime() <
            termRepoServicer.maturityTimestamp()
        ) {
            revert AuctionEndsBeforeMaturity();
        }
        if (
            termRepoServicer.purchaseToken() !=
            address(auctionBidLocker.purchaseToken())
        ) {
            revert DifferentPurchaseToken(
                termRepoServicer.purchaseToken(),
                address(auctionBidLocker.purchaseToken())
            );
        }

        uint256 numOfAcceptedCollateralTokens = termRepoCollateralManager
            .numOfAcceptedCollateralTokens();

        for (uint256 i = 0; i < numOfAcceptedCollateralTokens; ++i) {
            IERC20Upgradeable supportedIERC20Collateral = IERC20Upgradeable(
                termRepoCollateralManager.collateralTokens(i)
            );
            if (!auctionBidLocker.collateralTokens(supportedIERC20Collateral)) {
                revert CollateralTokenNotSupported(
                    address(supportedIERC20Collateral)
                );
            }
        }

        approvedRolloverAuctions[address(auctionBidLocker)] = true;

        termRepoServicer.approveRolloverAuction(termAuction);
        termRepoCollateralManager.approveRolloverAuction(termAuction);

        _grantRole(ROLLOVER_BID_FULFILLER_ROLE, termAuction);

        emitter.emitRolloverTermApproved(
            termRepoId,
            auctionBidLocker.termAuctionId()
        );
    }

    /// @param auctionBidLocker The ABI for ITermAuctionBidLocker interface
    function revokeRolloverApproval(
        ITermAuctionBidLocker auctionBidLocker
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        approvedRolloverAuctions[address(auctionBidLocker)] = false;

        emitter.emitRolloverTermApprovalRevoked(
            termRepoId,
            auctionBidLocker.termAuctionId()
        );
    }

    // ========================================================================
    // = Internal =============================================================
    // ========================================================================

    function _processRollover(address borrowerToRollover) internal {
        TermRepoRolloverElection memory rolloverElection = rolloverElections[
            borrowerToRollover
        ];

        if (
            termRepoServicer.getBorrowerRepurchaseObligation(
                borrowerToRollover
            ) < rolloverElection.rolloverAmount
        ) {
            rolloverElections[borrowerToRollover].processed = true;
            emitter.emitRolloverBidLockFailed(termRepoId, borrowerToRollover);
        } else if (
            !approvedRolloverAuctions[rolloverElection.rolloverAuction]
        ) {
            delete rolloverElections[borrowerToRollover];
            emitter.emitRolloverCancellation(termRepoId, borrowerToRollover);
        } else {
            ITermAuctionBidLocker termAuctionBidLocker = ITermAuctionBidLocker(
                rolloverElection.rolloverAuction
            );
            (
                address[] memory collateralTokens,
                uint256[] memory collateralAmounts
            ) = termRepoCollateralManager.getCollateralBalances(
                    borrowerToRollover
                );

            ITermRepoServicer futureTermRepoServicer = termAuctionBidLocker
                .termRepoServicer();

            uint256 servicingFeeProRatedMantissa = mul_(
                Exp({
                    mantissa: termAuctionBidLocker.dayCountFractionMantissa()
                }),
                Exp({mantissa: futureTermRepoServicer.servicingFee()})
            ).mantissa;

            uint256 bidAmount = truncate(
                div_(
                    Exp({mantissa: rolloverElection.rolloverAmount * expScale}),
                    Exp({mantissa: expScale - servicingFeeProRatedMantissa})
                )
            );

            TermAuctionBid memory termAuctionBid = TermAuctionBid({
                id: keccak256(
                    abi.encodePacked(address(this), borrowerToRollover)
                ),
                bidder: borrowerToRollover,
                bidPriceHash: rolloverElection.rolloverBidPriceHash,
                bidPriceRevealed: 0,
                amount: bidAmount,
                collateralTokens: collateralTokens,
                collateralAmounts: collateralAmounts,
                purchaseToken: termRepoServicer.purchaseToken(),
                isRollover: true,
                rolloverPairOffTermRepoServicer: address(termRepoServicer),
                isRevealed: false
            });

            if (termAuctionBidLocker.lockRolloverBid(termAuctionBid)) {
                // slither-disable-start reentrancy-no-eth
                rolloverElections[borrowerToRollover].locked = true;
                // slither-disable-end reentrancy-no-eth

                emitter.emitRolloverBidLockSucceeded(
                    termRepoId,
                    borrowerToRollover
                );
            } else {
                // slither-disable-start reentrancy-no-eth
                rolloverElections[borrowerToRollover].processed = true;
                // slither-disable-end reentrancy-no-eth
                emitter.emitRolloverBidLockFailed(
                    termRepoId,
                    borrowerToRollover
                );
            }
        }
    }

    // solhint-disable no-empty-blocks
    ///@dev required override by the OpenZeppelin UUPS module
    function _authorizeUpgrade(
        address
    ) internal view override onlyRole(DEFAULT_ADMIN_ROLE) {}
    // solhint-enable no-empty-blocks
}