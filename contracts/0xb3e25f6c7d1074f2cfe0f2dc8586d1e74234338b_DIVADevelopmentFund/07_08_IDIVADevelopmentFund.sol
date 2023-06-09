// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import {IDIVAOwnershipShared} from "./IDIVAOwnershipShared.sol";

interface IDIVADevelopmentFund {
    // Thrown in constructor if zero address is provided for DIVA ownership address
    error ZeroDIVAOwnershipAddress();

    // Thrown in `withdraw` if `msg.sender` is not the owner of DIVA protocol
    error NotDIVAOwner(address _user, address _divaOwner);

    // Thrown in `deposit` if `_releasePeriodInSeconds` argument is zero or
    // exceeds 30 years    
    error InvalidReleasePeriod();

    // Thrown in ERC20 `deposit` function if the token implements a fee on transfers
    error FeeTokensNotSupported();

    // Thrown in `withdraw` and `withdrawDirectDeposit` if the transfer of the
    // native asset failed
    error FailedToSendNativeAsset();

    // Thrown in `withdraw` if token addresses for indices passed are
    // different
    error DifferentTokens();

    // Struct for deposits
    struct Deposit {
        address token; // Address of deposited token (zero address for native asset)
        uint256 amount; // Deposit amount
        uint256 startTime; // Timestamp in seconds since epoch when user can start claiming the deposit
        uint256 endTime; // Timestamp in seconds since epoch when release period ends at
        uint256 lastClaimedAt; // Timestamp in seconds since epoch when user last claimed deposit at
    }
    // Note: Before the first claim, the `lastClaimedAt` variable represents the timestamp of the deposit.

    /**
     * @notice Emitted when a user deposits a token or a native asset via
     * one of the two `deposit` functions.
     * @param sender Address of user who deposits token (`msg.sender`).
     * @param depositIndex Index of deposit in deposits array variable.
     */
    event Deposited(address indexed sender, uint256 indexed depositIndex);

    /**
     * @notice Emitted when a user withdraws a token via `withdraw`
     * or `withdrawDirectDeposit`.
     * @param withdrawnBy Address of user who withdraws token (same as
     * current DIVA owner).
     * @param token Address of withdrawn token.
     * @param amount Token amount withdrawn.
     */
    event Withdrawn(
        address indexed withdrawnBy,
        address indexed token,
        uint256 amount
    );

    /**
     * @notice Function to deposit the native asset, such as ETH on
     * Ethereum.
     * @dev Creates a new entry in the `Deposit` struct array with the
     * `token` parameter set to `address(0)` and the `amount` parameter to
     * `msg.value`. Emits a `Deposited` event on success.
     * @param _releasePeriodInSeconds Release period of deposit in seconds.
     */
    function deposit(uint256 _releasePeriodInSeconds) external payable;

    /**
     * @notice Function to deposit ERC20 token.
     * @dev Creates a new entry in the `Deposit` struct array with the
     * `token` and `amount` parameters set equal to the ones provided by the user.
     * The deposit transaction will revert if `_releasePeriodInSeconds = 0`, `msg.sender`
     * has insufficient allowance/balance or the deposit token implements a fee on transfers.
     * When tokens with a flexible supply are considered, only tokens with a constant
     * balance mechanism such as Compound's cToken or the wrapped version of Lido's staked
     * ETH (wstETH) should be used.
     * Emits a `Deposited` event on success.
     * @param _token Address of token to deposit.
     * @param _amount ERC20 token amount to deposit.
     * @param _releasePeriodInSeconds Release period of deposit in seconds.
     */
    function deposit(
        address _token,
        uint256 _amount,
        uint256 _releasePeriodInSeconds
    ) external;

    /**
     * @notice Function to withdraw a deposited `_token`.
     * @dev Use the zero address for the native asset (e.g., ETH on Ethereum).
     * @param _token Address of token to withdraw.
     * @param _indices Array of deposit indices to withdraw (indices can be
     * obtained via `getDepositIndices`).
     */
    function withdraw(address _token, uint256[] calldata _indices)
        external
        payable;

    /**
     * @notice Function to withdraw a given `_token` that has been sent
     * to the contract directly without calling the deposit function.
     * @dev Use the zero address for the native asset (e.g., ETH on Ethereum).
     * @param _token Address of token to withdraw.
     */
    function withdrawDirectDeposit(address _token) external payable;

    /**
     * @notice Function to return the number of deposits.
     * @return The number of deposits.
     */
    function getDepositsLength() external view returns (uint256);

    /**
     * @notice Function to return the DIVAOwnership contract address on
     * the corresponding chain.
     * @return The address of the DIVAOwnership contract.
     */
    function getDivaOwnership() external view returns (IDIVAOwnershipShared);

    /**
     * @notice Function to get the deposit info for a given `_index`.
     * @param _index Deposit index.
     * @return Deposit info.
     */
    function getDepositInfo(uint256 _index)
        external
        view
        returns (Deposit memory);

    /**
     * @notice Function to get the deposit indices for a given `_token`.
     * @dev Use the zero address for the native asset (e.g., ETH on Ethereum).
     * `_startIndex` and `_endIndex` allow the caller to control the array
     * range to return to avoid exceeding the gas limit. Returns an empty
     * array if `_endIndex <= _startIndex`.
     * @param _token Token address.
     * @param _startIndex Start index of deposit indices list to get.
     * @param _endIndex End index of deposit indices list to get.
     * @return An array of deposit indices for `_token` within the specified
     * range.
     */
    function getDepositIndices(
        address _token,
        uint256 _startIndex,
        uint256 _endIndex
    ) external view returns (uint256[] memory);

    /**
     * @notice Function to get the length of deposit indices for a given `_token`.
     * @dev Use the zero address for the native asset (e.g., ETH on Ethereum).
     * @param _token Token address.
     * @return The length of deposit indices for the specified `_token`.
     */
    function getDepositIndicesLengthForToken(address _token)
        external
        view
        returns (uint256);

    /**
     * @notice Function to get the unclaimed deposit amount for a given `_token`.
     * @dev Use the zero address for the native asset (e.g., ETH on Ethereum).
     * @param _token Token address.
     * @return The unclaimed deposit amount for the specified `_token`.
     */
    function getUnclaimedDepositAmount(address _token)
        external
        view
        returns (uint256);
}