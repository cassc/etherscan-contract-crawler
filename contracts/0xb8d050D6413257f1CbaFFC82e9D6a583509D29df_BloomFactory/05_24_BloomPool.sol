// SPDX-License-Identifier: BUSL-1.1
/*
██████╗░██╗░░░░░░█████╗░░█████╗░███╗░░░███╗
██╔══██╗██║░░░░░██╔══██╗██╔══██╗████╗░████║
██████╦╝██║░░░░░██║░░██║██║░░██║██╔████╔██║
██╔══██╗██║░░░░░██║░░██║██║░░██║██║╚██╔╝██║
██████╦╝███████╗╚█████╔╝╚█████╔╝██║░╚═╝░██║
╚═════╝░╚══════╝░╚════╝░░╚════╝░╚═╝░░░░░╚═╝
*/

pragma solidity 0.8.19;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {IBloomPool, State} from "./interfaces/IBloomPool.sol";
import {IEmergencyHandler} from "./interfaces/IEmergencyHandler.sol";
import {ISwapRecipient} from "./interfaces/ISwapRecipient.sol";

import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import {SafeCastLib} from "solady/utils/SafeCastLib.sol";
import {FixedPointMathLib as Math} from "solady/utils/FixedPointMathLib.sol";
import {CommitmentsLib, Commitments, AssetCommitment} from "./lib/CommitmentsLib.sol";

import {IWhitelist} from "./interfaces/IWhitelist.sol";
import {ISwapFacility} from "./interfaces/ISwapFacility.sol";
import {IBPSFeed} from "./interfaces/IBPSFeed.sol";
import {IOracle} from "./interfaces/IOracle.sol";

contract BloomPool is IBloomPool, ISwapRecipient, ERC20 {
    using CommitmentsLib for Commitments;
    using CommitmentsLib for AssetCommitment;
    using SafeTransferLib for address;
    using SafeCastLib for uint256;

    uint256 internal constant BPS = 1e4; // Represents Scaling & Initial BPS Feed Rate
    uint256 internal constant ONE_YEAR = 360 days;

    // =============== Core Parameters ===============

    address public immutable UNDERLYING_TOKEN;
    address public immutable BILL_TOKEN;
    IWhitelist public immutable WHITELIST;
    address public immutable SWAP_FACILITY;
    address public immutable TREASURY;
    address public immutable EMERGENCY_HANDLER;
    address public immutable LENDER_RETURN_BPS_FEED;
    uint256 public immutable LEVERAGE_BPS;
    uint256 public immutable MIN_BORROW_DEPOSIT;
    uint256 public immutable COMMIT_PHASE_END;
    uint256 public immutable PRE_HOLD_SWAP_TIMEOUT_END;
    uint256 public immutable POST_HOLD_SWAP_TIMEOUT_END;
    uint256 public immutable POOL_PHASE_END;
    uint256 public immutable POOL_PHASE_DURATION;
    uint256 public immutable LENDER_RETURN_FEE;
    uint256 public immutable BORROWER_RETURN_FEE;

    // =================== Storage ===================

    Commitments internal borrowers;
    Commitments internal lenders;
    State internal setState = State.Commit;
    State internal stateBeforeEmergency;
    uint128 internal borrowerDistribution;
    uint128 internal totalBorrowerShares;
    uint128 internal lenderDistribution;
    uint128 internal totalLenderShares;

    // ================== Modifiers ==================

    modifier onlyState(State expectedState) {
        State currentState = state();
        if (currentState != expectedState) revert InvalidState(currentState);
        _;
    }

    modifier onlyAfterState(State lastInvalidState) {
        State currentState = state();
        if (currentState <= lastInvalidState) revert InvalidState(currentState);
        _;
    }

    modifier onlyEmergencyHandler() {
        if (msg.sender != EMERGENCY_HANDLER) revert NotEmergencyHandler();
        _;
    }

    constructor(
        address underlyingToken,
        address billToken,
        IWhitelist whitelist,
        address swapFacility,
        address treasury,
        address lenderReturnBpsFeed,
        address emergencyHandler,
        uint256 leverageBps,
        uint256 minBorrowDeposit,
        uint256 commitPhaseDuration,
        uint256 swapTimeout,
        uint256 poolPhaseDuration,
        uint256 lenderReturnFee,
        uint256 borrowerReturnFee,
        string memory name,
        string memory symbol
    ) ERC20(name, symbol, ERC20(underlyingToken).decimals()) {
        UNDERLYING_TOKEN = underlyingToken;
        BILL_TOKEN = billToken;
        WHITELIST = whitelist;
        SWAP_FACILITY = swapFacility;
        TREASURY = treasury;
        LENDER_RETURN_BPS_FEED = lenderReturnBpsFeed;
        EMERGENCY_HANDLER = emergencyHandler;
        LEVERAGE_BPS = leverageBps;
        MIN_BORROW_DEPOSIT = minBorrowDeposit;
        COMMIT_PHASE_END = block.timestamp + commitPhaseDuration;
        PRE_HOLD_SWAP_TIMEOUT_END = block.timestamp + commitPhaseDuration + swapTimeout;
        POOL_PHASE_END = block.timestamp + commitPhaseDuration + poolPhaseDuration;
        POOL_PHASE_DURATION = poolPhaseDuration;
        POST_HOLD_SWAP_TIMEOUT_END = block.timestamp + commitPhaseDuration + poolPhaseDuration + (swapTimeout * 2 );
        LENDER_RETURN_FEE = lenderReturnFee;
        BORROWER_RETURN_FEE = borrowerReturnFee;
    }

    // =============== Deposit Methods ===============

    /**
     * @inheritdoc IBloomPool
     */
    function depositBorrower(uint256 amount, bytes32[] calldata proof)
        external
        onlyState(State.Commit)
        returns (uint256 newId)
    {
        if (amount < MIN_BORROW_DEPOSIT) revert CommitTooSmall();
        if (!IWhitelist(WHITELIST).isWhitelisted(msg.sender, proof)) revert NotWhitelisted();
        UNDERLYING_TOKEN.safeTransferFrom(msg.sender, address(this), amount);
        uint256 cumulativeAmountEnd;
        (newId, cumulativeAmountEnd) = borrowers.add(msg.sender, amount);
        emit BorrowerCommit(msg.sender, newId, amount, cumulativeAmountEnd);
    }

    /**
     * @inheritdoc IBloomPool
     */
    function depositLender(uint256 amount) external onlyState(State.Commit) returns (uint256 newId) {
        if (amount == 0) revert CommitTooSmall();
        UNDERLYING_TOKEN.safeTransferFrom(msg.sender, address(this), amount);
        uint256 cumulativeAmountEnd;
        (newId, cumulativeAmountEnd) = lenders.add(msg.sender, amount);
        emit LenderCommit(msg.sender, newId, amount, cumulativeAmountEnd);
    }

    // =========== Further Deposit Methods ===========

    /**
     * @inheritdoc IBloomPool
     */
    function processBorrowerCommit(uint256 id) external onlyAfterState(State.Commit) {
        AssetCommitment storage commitment = borrowers.commitments[id];
        if (commitment.cumulativeAmountEnd == 0) revert NoCommitToProcess();
        uint256 committedBorrowValue = lenders.totalAssetsCommitted * BPS / LEVERAGE_BPS;
        (uint256 includedAmount, uint256 excludedAmount) = commitment.getAmountSplit(committedBorrowValue);
        commitment.committedAmount = includedAmount.toUint128();
        commitment.cumulativeAmountEnd = 0;
        address owner = commitment.owner;
        emit BorrowerCommitmentProcessed(owner, id, includedAmount, excludedAmount);
        if (excludedAmount > 0) UNDERLYING_TOKEN.safeTransfer(owner, excludedAmount);
    }

    /**
     * @inheritdoc IBloomPool
     */
    function processLenderCommit(uint256 id) external onlyAfterState(State.Commit) {
        AssetCommitment storage commitment = lenders.commitments[id];
        if (commitment.cumulativeAmountEnd == 0) revert NoCommitToProcess();
        uint256 committedBorrowValue = borrowers.totalAssetsCommitted * LEVERAGE_BPS / BPS;
        (uint256 includedAmount, uint256 excludedAmount) = commitment.getAmountSplit(committedBorrowValue);
        address owner = commitment.owner;
        delete lenders.commitments[id];
        _mint(owner, includedAmount);
        emit LenderCommitmentProcessed(owner, id, includedAmount, excludedAmount);
        if (excludedAmount > 0) UNDERLYING_TOKEN.safeTransfer(owner, excludedAmount);
    }

    // ======== Swap State Management Methods ========

    /**
     * @inheritdoc IBloomPool
     */
    function initiatePreHoldSwap(bytes32[] calldata proof) external onlyState(State.ReadyPreHoldSwap) {
        uint256 amountToSwap = totalMatchAmount() * (LEVERAGE_BPS + BPS) / LEVERAGE_BPS;
        // Reset allowance to zero before to ensure can always set for weird tokens like USDT.
        UNDERLYING_TOKEN.safeApprove(SWAP_FACILITY, 0);
        UNDERLYING_TOKEN.safeApprove(SWAP_FACILITY, amountToSwap);
        emit ExplictStateTransition(State.ReadyPreHoldSwap, setState = State.PendingPreHoldSwap);
        ISwapFacility(SWAP_FACILITY).swap(UNDERLYING_TOKEN, BILL_TOKEN, amountToSwap, proof);
    }

    /**
     * @inheritdoc IBloomPool
     */
    function initiatePostHoldSwap(bytes32[] calldata proof) external onlyState(State.ReadyPostHoldSwap) {
        uint256 amountToSwap = ERC20(BILL_TOKEN).balanceOf(address(this));
        // Reset allowance to zero before to ensure can always set for weird tokens like USDT.
        BILL_TOKEN.safeApprove(SWAP_FACILITY, 0);
        BILL_TOKEN.safeApprove(SWAP_FACILITY, amountToSwap);
        emit ExplictStateTransition(State.ReadyPostHoldSwap, setState = State.PendingPostHoldSwap);
        ISwapFacility(SWAP_FACILITY).swap(BILL_TOKEN, UNDERLYING_TOKEN, amountToSwap, proof);
    }

    /**
     * @inheritdoc ISwapRecipient
     */
    function completeSwap(address outToken, uint256 outAmount) external {
        if (msg.sender != SWAP_FACILITY) revert NotSwapFacility();
        State currentState = state();
        if (currentState == State.PendingPreHoldSwap) {
            if (outToken != BILL_TOKEN) revert InvalidOutToken(outToken);
            emit ExplictStateTransition(State.PendingPreHoldSwap, setState = State.Holding);
            return;
        }
        if (currentState == State.PendingPostHoldSwap) {
            if (outToken != UNDERLYING_TOKEN) revert InvalidOutToken(outToken);
            uint256 totalMatched = totalMatchAmount();

            // Lenders get paid first, borrowers carry any shortfalls/excesses due to slippage.
            uint256 lenderReturn = _calculateLenderReturn(totalMatched, outAmount);

            uint256 borrowerReturn = outAmount - lenderReturn;
            uint256 lenderReturnFee = (lenderReturn - totalMatched) * LENDER_RETURN_FEE / BPS;
            uint256 borrowerReturnFee = borrowerReturn * BORROWER_RETURN_FEE / BPS;

            borrowerDistribution = (borrowerReturn - borrowerReturnFee).toUint128();
            totalBorrowerShares = uint256(totalMatched * BPS / LEVERAGE_BPS).toUint128();

            lenderDistribution = (lenderReturn - lenderReturnFee).toUint128();
            totalLenderShares = uint256(totalMatched).toUint128();

            UNDERLYING_TOKEN.safeTransfer(TREASURY, lenderReturnFee + borrowerReturnFee);

            emit ExplictStateTransition(State.PendingPostHoldSwap, setState = State.FinalWithdraw);
            return;
        }
        revert InvalidState(currentState);
    }

    // =========== Final Withdraw Methods ============

    /**
     * @inheritdoc IBloomPool
     */
    function withdrawBorrower(uint256 id) external onlyState(State.FinalWithdraw) {
        AssetCommitment storage commitment = borrowers.commitments[id];
        if (commitment.cumulativeAmountEnd != 0) revert CanOnlyWithdrawProcessedCommit(id);
        address owner = commitment.owner;
        if (owner == address(0)) revert NoCommitToWithdraw();
        uint256 shares = commitment.committedAmount;
        uint256 currentBorrowerDist = borrowerDistribution;
        uint256 sharesLeft = totalBorrowerShares;
        uint256 claimAmount = shares * currentBorrowerDist / sharesLeft;
        borrowerDistribution = (currentBorrowerDist - claimAmount).toUint128();
        totalBorrowerShares = (sharesLeft - shares).toUint128();
        delete borrowers.commitments[id];
        emit BorrowerWithdraw(owner, id, claimAmount);
        UNDERLYING_TOKEN.safeTransfer(owner, claimAmount);
    }

    /**
     * @inheritdoc IBloomPool
     */
    function withdrawLender(uint256 shares) external onlyState(State.FinalWithdraw) {
        _burn(msg.sender, shares);
        uint256 currentLenderDist = lenderDistribution;
        uint256 sharesLeft = totalLenderShares;
        uint256 claimAmount = shares * currentLenderDist / sharesLeft;
        lenderDistribution = (currentLenderDist - claimAmount).toUint128();
        totalLenderShares = (sharesLeft - shares).toUint128();
        emit LenderWithdraw(msg.sender, shares, claimAmount);
        UNDERLYING_TOKEN.safeTransfer(msg.sender, claimAmount);
    }

    // ========= Emergency Withdraw Methods ==========

    function emergencyWithdraw() external onlyState(State.EmergencyExit) {
        uint256 underlyingBalance = UNDERLYING_TOKEN.balanceOf(address(this));
        uint256 billBalance = BILL_TOKEN.balanceOf(address(this));
        uint256 underlyingPrice = 1e8;

        IOracle billOracle = IOracle(ISwapFacility(SWAP_FACILITY).billyTokenOracle());
        uint256 currentBillPrice = uint256(billOracle.latestAnswer());
        if (currentBillPrice <= 0) revert OracleAnswerNegative();

        uint256 underlyingDecimals = ERC20(UNDERLYING_TOKEN).decimals();
        uint256 billDecimals = ERC20(BILL_TOKEN).decimals();
        uint256 scalingFactor = 10 ** (billDecimals - underlyingDecimals);
        
        uint256 additionalValue = BILL_TOKEN.balanceOf(address(this)) * currentBillPrice / underlyingPrice / scalingFactor;
        uint256 expectedTotalBalance = underlyingBalance + additionalValue;
       
        uint256 lenderDistro;
        uint256 borrowerDistro;
        uint256 totalMatched;
        bool yieldGenerating;
        // If we are in the emergency exit state before the end of the pool phase then we
        //    know this exit occured during the pre-hold swap phase, so users should be able
        //    to redeem USDC 1 for 1.
        if (block.timestamp >= POOL_PHASE_END) {
            totalMatched = totalMatchAmount();
            lenderDistro = _calculateLenderReturn(totalMatched, expectedTotalBalance);
            borrowerDistro = expectedTotalBalance - lenderDistro;
            yieldGenerating = true;
        } else {
            lenderDistro = lenders.totalAssetsCommitted;
            borrowerDistro = expectedTotalBalance - lenderDistro;
            yieldGenerating = false;
        }

        if (underlyingBalance > 0) {
            UNDERLYING_TOKEN.safeTransferAll(EMERGENCY_HANDLER);
            emit EmergencyWithdrawExecuted(address(this), EMERGENCY_HANDLER, underlyingBalance);
        }
        
        if (billBalance > 0) {
            BILL_TOKEN.safeTransferAll(EMERGENCY_HANDLER);
            emit EmergencyWithdrawExecuted(address(this), EMERGENCY_HANDLER, billBalance);
        }

        IEmergencyHandler.RedemptionInfo memory redemptionInfo = IEmergencyHandler.RedemptionInfo(
            IEmergencyHandler.Token(UNDERLYING_TOKEN, underlyingPrice, underlyingDecimals),
            IEmergencyHandler.Token(BILL_TOKEN, currentBillPrice, billDecimals),
            IEmergencyHandler.PoolAccounting(
                lenderDistro,
                borrowerDistro,
                totalMatched,
                totalMatched * BPS / LEVERAGE_BPS,
                underlyingBalance,
                billBalance
            ),
            yieldGenerating
        );

        IEmergencyHandler(EMERGENCY_HANDLER).registerPool(redemptionInfo);
    }

    function executeEmergencyBurn(
        address from,
        uint256 amount
    ) external onlyState(State.EmergencyExit) onlyEmergencyHandler {
        emit EmergencyBurn(from, amount);
        _burn(from, amount);
    }

    // ================ View Methods =================

    /// @notice Returns amount of lender-to-borrower demand that was matched.
    function totalMatchAmount() public view returns (uint256) {
        uint256 borrowDemand = borrowers.totalAssetsCommitted * LEVERAGE_BPS / BPS;
        uint256 lendDemand = lenders.totalAssetsCommitted;
        return Math.min(borrowDemand, lendDemand);
    }

    function state() public view returns (State) {
        if (block.timestamp < COMMIT_PHASE_END) {
            return State.Commit;
        }
        State lastState = setState;
        if (lastState == State.Commit && block.timestamp >= COMMIT_PHASE_END) {
            return State.ReadyPreHoldSwap;
        }
        if (lastState == State.PendingPreHoldSwap && block.timestamp >= PRE_HOLD_SWAP_TIMEOUT_END) {
            return State.EmergencyExit;
        }
        if (lastState == State.Holding && block.timestamp >= POOL_PHASE_END) {
            return State.ReadyPostHoldSwap;
        }
        if (lastState == State.PendingPostHoldSwap && block.timestamp >= POST_HOLD_SWAP_TIMEOUT_END) {
            return State.EmergencyExit;
        }
        return lastState;
    }

    function getBorrowCommitment(uint256 id) external view returns (AssetCommitment memory) {
        return borrowers.get(id);
    }

    function getLenderCommitment(uint256 id) external view returns (AssetCommitment memory) {
        return lenders.get(id);
    }

    function getTotalBorrowCommitment()
        external
        view
        returns (uint256 totalAssetsCommitted, uint256 totalCommitmentCount)
    {
        totalAssetsCommitted = borrowers.totalAssetsCommitted;
        totalCommitmentCount = borrowers.commitmentCount;
    }

    function getTotalLendCommitment()
        external
        view
        returns (uint256 totalAssetsCommitted, uint256 totalCommitmentCount)
    {
        totalAssetsCommitted = lenders.totalAssetsCommitted;
        totalCommitmentCount = lenders.commitmentCount;
    }

    function getDistributionInfo() external view returns (uint128, uint128, uint128, uint128) {
        return (borrowerDistribution, totalBorrowerShares, lenderDistribution, totalLenderShares);
    }

    function _calculateLenderReturn(uint256 totalMatched, uint256 outAmount) internal view returns (uint256) {
        uint256 rateAppreciation = IBPSFeed(LENDER_RETURN_BPS_FEED).getWeightedRate() - BPS;
        uint256 yieldEarned = totalMatched * rateAppreciation * POOL_PHASE_DURATION / ONE_YEAR / BPS;
        return Math.min(totalMatched + yieldEarned, outAmount);
    }
}