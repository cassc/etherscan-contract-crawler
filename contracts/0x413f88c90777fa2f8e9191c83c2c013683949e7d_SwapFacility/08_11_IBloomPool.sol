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

import {AssetCommitment} from "../lib/CommitmentsLib.sol";
import {IWhitelist} from "../interfaces/IWhitelist.sol";

enum State {
    Other,
    Commit,
    ReadyPreHoldSwap,
    PendingPreHoldSwap,
    Holding,
    ReadyPostHoldSwap,
    PendingPostHoldSwap,
    EmergencyExit,
    FinalWithdraw
}

interface IBloomPool {
    // Initialization errors
    error ZeroAddress();

    error NotSwapFacility();
    error InvalidOutToken(address outToken);

    error NotWhitelisted();
    error NoCommitToProcess();
    error CommitTooSmall();

    error CanOnlyWithdrawProcessedCommit(uint256 id);
    error NoCommitToWithdraw();

    error InvalidState(State current);

    error NotEmergencyHandler();

    event BorrowerCommit(address indexed owner, uint256 indexed id, uint256 amount, uint256 cumulativeAmountEnd);
    event LenderCommit(address indexed owner, uint256 indexed id, uint256 amount, uint256 cumulativeAmountEnd);
    event BorrowerCommitmentProcessed(
        address indexed owner, uint256 indexed id, uint256 includedAmount, uint256 excludedAmount
    );
    event LenderCommitmentProcessed(
        address indexed owner, uint256 indexed id, uint256 includedAmount, uint256 excludedAmount
    );
    event ExplictStateTransition(State prevState, State newState);
    event BorrowerWithdraw(address indexed owner, uint256 indexed id, uint256 amount);
    event LenderWithdraw(address indexed owner, uint256 sharesRedeemed, uint256 amount);

    event EmergencyWithdraw(address indexed to);

    /// @notice Initiates the pre-hold swap.
    function initiatePreHoldSwap(bytes32[] calldata proof) external;

    /// @notice Initiates the post-hold swap.
    function initiatePostHoldSwap(bytes32[] calldata proof) external;

    /**
     * @notice Deposits funds from the borrower committing them for the duration of the commit
     * phase.
     * @param amount The amount of tokens to deposit.
     * @param proof The whitelist proof data, format dependent on implementation.
     * @return newCommitmentId The commitment ID for the borrower's new deposit.
     */
    function depositBorrower(uint256 amount, bytes32[] calldata proof) external returns (uint256 newCommitmentId);
    /**
     * @notice Deposits funds from the lender committing them for the duration of the commit phase.
     * @param amount The amount of stablecoins to deposit.
     * @return newCommitmentId The commitment ID for the lender deposit.
     */
    function depositLender(uint256 amount) external returns (uint256 newCommitmentId);

    /**
     * @notice Processes a borrower's commit, calculates the included and excluded amounts, and refunds any unmatched amounts.
     * @param commitId The borrower's commitment ID.
     */
    function processBorrowerCommit(uint256 commitId) external;

    /**
     * @notice Processes a lender's commit, calculates the included and excluded amounts, mints shares, and refunds any unmatched amounts.
     * @param commitId The lender's commitment ID.
     */
    function processLenderCommit(uint256 commitId) external;

    /**
     * @notice Allows borrowers to withdraw their share of the returned stablecoins after the pool phase has ended and swaps have been completed.
     * @param id The borrower's commitment ID.
     */
    function withdrawBorrower(uint256 id) external;

    /**
     * @notice Allows lenders to withdraw their share of the returned stablecoins and earned interest after the pool phase has ended and swaps have been completed.
     * @param shares The number of lender shares to withdraw.
     */
    function withdrawLender(uint256 shares) external;

    function UNDERLYING_TOKEN() external view returns (address);
    function BILL_TOKEN() external view returns (address);
    function WHITELIST() external view returns (IWhitelist);
    function SWAP_FACILITY() external view returns (address);
    function TREASURY() external view returns (address);
    function LENDER_RETURN_BPS_FEED() external view returns (address);
    function LEVERAGE_BPS() external view returns (uint256);
    function MIN_BORROW_DEPOSIT() external view returns (uint256);
    function COMMIT_PHASE_END() external view returns (uint256);
    function PRE_HOLD_SWAP_TIMEOUT_END() external view returns (uint256);
    function POOL_PHASE_END() external view returns (uint256);
    function POOL_PHASE_DURATION() external view returns (uint256);
    function LENDER_RETURN_FEE() external view returns (uint256);
    function BORROWER_RETURN_FEE() external view returns (uint256);

    function state() external view returns (State currentState);
    function totalMatchAmount() external view returns (uint256);

    function getBorrowCommitment(uint256 id) external view returns (AssetCommitment memory);
    function getLenderCommitment(uint256 id) external view returns (AssetCommitment memory);

    function getTotalBorrowCommitment()
        external
        view
        returns (uint256 totalAssetsCommited, uint256 totalCommitmentCount);
    function getTotalLendCommitment()
        external
        view
        returns (uint256 totalAssetsCommited, uint256 totalCommitmentCount);

    function getDistributionInfo()
        external
        view
        returns (
            uint128 borrowerDistribution,
            uint128 totalBorrowerShares,
            uint128 lenderDistribution,
            uint128 totalLenderShares
        );
}