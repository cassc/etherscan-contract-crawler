// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

library Errors {
    /**
     * @notice max period 0 or greater than MAX_PERIODS
     */
    error InvalidMaxPeriod();

    /**
     * @notice period duration 0 or greater than MAX_PERIOD_DURATION
     */
    error InvalidPeriodDuration();

    /**
     * @notice address provided is not a contract
     */
    error NotAContract();

    /**
     * @notice not authorized
     */
    error NotAuthorized();

    /**
     * @notice contract already initialized
     */
    error AlreadyInitialized();

    /**
     * @notice address(0)
     */
    error InvalidAddress();

    /**
     * @notice empty bytes identifier
     */
    error InvalidIdentifier();

    /**
     * @notice invalid protocol name
     */
    error InvalidProtocol();

    /**
     * @notice invalid number of choices
     */
    error InvalidChoiceCount();

    /**
     * @notice invalid input amount
     */
    error InvalidAmount();

    /**
     * @notice not team member
     */
    error NotTeamMember();

    /**
     * @notice cannot whitelist BRIBE_VAULT
     */
    error NoWhitelistBribeVault();

    /**
     * @notice token already whitelisted
     */
    error TokenWhitelisted();

    /**
     * @notice token not whitelisted
     */
    error TokenNotWhitelisted();

    /**
     * @notice voter already blacklisted
     */
    error VoterBlacklisted();

    /**
     * @notice voter not blacklisted
     */
    error VoterNotBlacklisted();

    /**
     * @notice deadline has passed
     */
    error DeadlinePassed();

    /**
     * @notice invalid period
     */
    error InvalidPeriod();

    /**
     * @notice invalid deadline
     */
    error InvalidDeadline();

    /**
     * @notice invalid max fee
     */
    error InvalidMaxFee();

    /**
     * @notice invalid fee
     */
    error InvalidFee();

    /**
     * @notice invalid fee recipient
     */
    error InvalidFeeRecipient();

    /**
     * @notice invalid distributor
     */
    error InvalidDistributor();

    /**
     * @notice invalid briber
     */
    error InvalidBriber();

    /**
     * @notice address does not have DEPOSITOR_ROLE
     */
    error NotDepositor();

    /**
     * @notice no array given
     */
    error InvalidArray();

    /**
     * @notice invalid reward identifier
     */
    error InvalidRewardIdentifier();

    /**
     * @notice bribe has already been transferred
     */
    error BribeAlreadyTransferred();

    /**
     * @notice distribution does not exist
     */
    error InvalidDistribution();

    /**
     * @notice invalid merkle root
     */
    error InvalidMerkleRoot();

    /**
     * @notice token is address(0)
     */
    error InvalidToken();

    /**
     * @notice claim does not exist
     */
    error InvalidClaim();

    /**
     * @notice reward is not yet active for claiming
     */
    error RewardInactive();

    /**
     * @notice timer duration is invalid
     */
    error InvalidTimerDuration();

    /**
     * @notice merkle proof is invalid
     */
    error InvalidProof();

    /**
     * @notice ETH transfer failed
     */
    error ETHTransferFailed();

    /**
     * @notice Invalid operator address
     */
    error InvalidOperator();

    /**
     * @notice call to TokenTransferProxy contract
     */
    error TokenTransferProxyCall();

    /**
     * @notice calling TransferFrom
     */
    error TransferFromCall();

    /**
     * @notice external call failed
     */
    error ExternalCallFailure();

    /**
     * @notice returned tokens too few
     */
    error InsufficientReturn();

    /**
     * @notice swapDeadline expired
     */
    error DeadlineBreach();

    /**
     * @notice expected tokens returned are 0
     */
    error ZeroExpectedReturns();

    /**
     * @notice arrays in SwapData.exchangeData have wrong lengths
     */
    error ExchangeDataArrayMismatch();
}