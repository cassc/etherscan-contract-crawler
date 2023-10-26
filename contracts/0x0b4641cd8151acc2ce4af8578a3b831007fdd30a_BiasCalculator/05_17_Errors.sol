pragma solidity 0.8.16;
//SPDX-License-Identifier: MIT

library Errors {

    // Common Errors
    error AddressZero();
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

    error CannotBeOwner();
    error CallerNotPendingOwner();

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
    error QuestNotStarted();

    error NotInitialized();
    error NoDistributorSet();
    error DisitributorFail();
    error InvalidGauge();
    error InvalidQuestID();
    error InvalidPeriod();
    error ObjectiveTooLow();
    error NewObjectiveTooLow();
    error RewardPerVoteTooLow();
    error MinValueOverMaxValue();
    error IncorrectDuration();
    error IncorrectAddDuration();
    error IncorrectTotalRewardAmount();
    error IncorrectAddedRewardAmount();
    error IncorrectFeeAmount();
    error InvalidQuestType();
    error QuestTypesIncompatible();
    error CalletNotQuestCreator();
    error LowerRewardPerVote();
    error LowerObjective();
    error CreatorNotAllowed();
    error AlreadyListed();
    error NotListed();
    error MaxListSize();
    error BoardIsNotAllowedDistributor();


    //Math
    error NumberExceed48Bits();

}