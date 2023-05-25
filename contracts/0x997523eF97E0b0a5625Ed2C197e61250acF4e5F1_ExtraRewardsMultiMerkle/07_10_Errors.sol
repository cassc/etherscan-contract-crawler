pragma solidity 0.8.10;
//SPDX-License-Identifier: MIT

library Errors {

    // Common Errors
    error ZeroAddress();
    error NullAmount();
    error CallerNotAllowed();
    error IncorrectRewardToken();
    error SameAddress();
    error InequalArraySizes();
    error EmptyArray();
    error EmptyParameters();
    error AlreadyInitialized();
    error InvalidParameter();
    error CannotRecoverToken();
    error ForbiddenCall();

    error Killed();
    error AlreadyKilled();
    error NotKilled();
    error KillDelayExpired();
    error KillDelayNotExpired();


    // Merkle Errors
    error MerkleRootNotUpdated();
    error AlreadyClaimed();
    error InvalidProof();
    error EmptyMerkleRoot();
    error IncorrectRewardAmount();
    error MerkleRootFrozen();
    error NotFrozen();
    error AlreadyFrozen();


    // Quest Errors
    error CallerNotQuestBoard();
    error IncorrectQuestID();
    error IncorrectPeriod();
    error TokenNotWhitelisted();
    error QuestAlreadyListed();
    error QuestNotListed();
    error PeriodAlreadyUpdated();
    error PeriodNotClosed();
    error PeriodStillActive();
    error PeriodNotListed();
    error EmptyQuest();
    error EmptyPeriod();
    error ExpiredQuest();

    error NoDistributorSet();
    error DisitributorFail();
    error InvalidGauge();
    error InvalidQuestID();
    error InvalidPeriod();
    error ObjectiveTooLow();
    error RewardPerVoteTooLow();
    error IncorrectDuration();
    error IncorrectAddDuration();
    error IncorrectTotalRewardAmount();
    error IncorrectAddedRewardAmount();
    error IncorrectFeeAmount();
    error CalletNotQuestCreator();
    error LowerRewardPerVote();
    error LowerObjective();
    error AlreadyBlacklisted();


    //Math
    error NumberExceed48Bits();

}