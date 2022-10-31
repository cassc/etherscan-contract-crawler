//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
    @title IImeStakingCore
    @author iMe Group
    @notice Interface for general staking functionality.
 */
interface IImeStakingCore {
    /**
        @notice Yields staking name

        @return name Human-readable staking name. As example, "LIME Polygon v1"
     */
    function name() external view returns (string memory);

    /**
        @notice Yields human-readable staking author.

        @return author Identifier of staking author. As example, "iMe Lab", "Tether ltd"
     */
    function author() external view returns (string memory);

    /**
        @notice Yields staking version

        @return version Staking version
     */
    function version() external view returns (string memory);

    /**
        @notice Yields staking erc20-token address
     */
    function token() external view returns (address);

    /**
        @notice Yields erc20-token for fees
     */
    function feeToken() external view returns (address);

    /**
        @notice Yields staking start timestamp
        Participants can't make deposits before this moment
     */
    function startsAt() external view returns (uint256);

    /**
        @notice Yields staking finish timestamp
        Participants can't make deposits after this moment
     */
    function endsAt() external view returns (uint256);

    /**
        @notice Yields one-time profit for deposit of 1e9 tokens
     */
    function income() external view returns (uint256);

    /**
        @notice Yields income period

        @return period Income period in seconds
     */
    function incomePeriod() external view returns (uint256 period);

    /**
        @notice Yields fee for premature withdrawals

        @return fee Fee amount, taken from 1e9 withdrawn tokens
     */
    function prematureWithdrawalFee() external view returns (uint256 fee);

    /**
        @notice Yields fee for safe withdrawals

        @return fee Fee amount, taken from 1e9 withdrawn tokens
     */
    function safeWithdrawalFee() external view returns (uint256 fee);

    /**
        @notice Yields duration of safe withdrawal
     */
    function safeWithdrawalDuration() external view returns (uint256);

    /**
        @notice Yields minimal amount of impact, needed to enable
        compound interest accrual
     */
    function compoundAccrualThreshold() external view returns (uint256);

    /**
        @notice Yields staking's debt for certain participant, for present moment
     */
    function debtOf(address account) external view returns (uint256);

    /**
        @notice Yields certain account's impact in this staking
     */
    function impactOf(address account) external view returns (uint256);

    /**
        @notice Yields certain account's safely withdrawn tokens status for present moment
     */
    function safelyWithdrawnTokensOf(address account)
        external
        view
        returns (uint256 pending, uint256 ready);

    /**
        @notice Estimates solvency status by the time of staking finish

        @return lack Amount of tokens, needed to cover a debt
        @return excess Redundant tokens in contract balance, which may be rescued
     */
    function estimateSolvency(uint256 at)
        external
        view
        returns (uint256 lack, uint256 excess);

    /**
        @notice Stake tokens
    
        @param amount Deposit amount

        @dev
        Reverts with **DepositTooEarly** on attempt of deposit before staking start
        Reverts with **DepositTooLate** on attempt of deposit after staking finish
        Reverts with **DepositDisabled** of deposits are disabled at the moment
        Emits **Deposit** on successful deposit
     */
    function stake(uint256 amount) external;

    error DepositTooEarly(uint256 at, uint256 minimalTime);
    error DepositTooLate(uint256 at, uint256 maximalTime);
    error DepositDisabled();
    event Deposit(address indexed from, uint256 amount);

    /**
        @notice Withdraw tokens
    
        @param amount Withdrawn tokens amount
        @param safe Use safe withdrawal or not

        @dev
        Reverts with **WithdrawalOverLimit** on attempt to withdraw over withdrawal limit
        Reverts with **WithdrawalDisabled** if withdrawals are disabled at the moment
        Emits **Withdrawal** event on successful withdrawal
     */
    function withdraw(uint256 amount, bool safe) external;

    error WithdrawalOverLimit(uint256 requested, uint256 available);
    error WithdrawalDisabled();
    event Withdrawal(address indexed to, uint256 amount, uint256 fee);

    /**
        @notice Claim safely withdrawn tokens

        @dev
        Emits **Claim** event on successful claim
     */
    function claim() external;

    event Claim(address indexed to, uint256 amount);
}