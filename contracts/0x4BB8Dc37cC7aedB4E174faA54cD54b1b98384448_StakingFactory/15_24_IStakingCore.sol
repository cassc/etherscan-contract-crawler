//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
    @title IStakingCore
    @author iMe Lab

    @notice General interface for iMe Staking v2
 */
interface IStakingCore {
    error TokenTransferFailed();
    error DepositIsTooEarly();
    error DepositIsTooLate();
    error DepositRankIsUntrusted();
    error DepositRankIsTooLow();
    error DepositDeadlineIsReached();
    error WithdrawalDelayIsUnwanted();
    error WithdrawalIsOffensive();
    error NoTokensReadyForClaim();
    error RewardIsTooEarly();
    error RefundIsTooEarly();

    event Deposit(address from, uint256 amount);
    event Withdrawal(address to, uint256 amount, uint256 fee);
    event DelayedWithdrawal(
        address to, uint256 amount, uint256 fee, uint64 until
    );
    event Claim(address to, uint256 amount);

    /**
        @notice Yields internal staking version

        @dev Version is needed to distinguish staking v1/v2 interfaces
     */
    function version() external pure returns (string memory);

    /**
       @notice Make a deposit

       @dev Should fire StakingDeposit event

       @param amount Amount of token to deposit. Should be approved in advance.
       @param rank Depositor's LIME rank
       @param deadline Deadline for deposit transaction
       @param v V part of the signature, proofing depositor's rank
       @param r R part of the signature, proofing depositor's rank
       @param s S part of the signature, proofing depositor's rank
     */
    function deposit(
        uint256 amount,
        uint8 rank,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
        @notice Withdraw staked and prize tokens

        @dev should fire StakingWithdrawal or StakingDelayedWithdrawal event

        @param amount Amount of tokens to withdraw
        @param delayed Whether withdrawal is delayed
     */
    function withdraw(uint256 amount, bool delayed) external;

    /**
        @notice Claim delayed withdrawn tokens

        @dev Actually doesn't matter who run this method: claimer address
        is passed as a parameter. So, anyone can pay gas to perform claim for
        a friend.

        Should fire StakingClaim event.

        @param depositor Depositor who performs claim
     */
    function claim(address depositor) external;

    /**
        @notice Force withdrawal for specified investor

        @dev Force withdrawals should be available after staking finish only.

        @param depositor Depositor to perform delay for
     */
    function reward(address depositor) external;

    /**
        @notice Take tokens which doesn't participate in staking. Should be
        available only after staking finish and only for tokens owner (partner)

        @param amount Amount of tokens to take. Should not be above free
        tokens. if amount = 0, all free tokens will be withdrawn
     */
    function refund(uint256 amount) external;
}