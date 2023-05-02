// SPDX-License-Identifier: MIT

// @author: Fair.xyz dev

pragma solidity 0.8.17;

contract RugStubsErrorsAndEvents {
    /// @dev Events
    event Airdrop(uint256 tokenCount, uint256 newTotal, address[] recipients);
    event BurnableSet(bool burnState);
    event SignatureReleased();
    event NewCloneTicker(address _newClone, address _owner, string symbol);
    event NewMaxMintsPerWalletSet(uint128 newGlobalMintsPerWallet);
    event NewPathURI(string newPathURI);
    event NewPrimarySaleReceiver(address newPrimaryReceiver);
    event NewSecondaryRoyalties(
        address newSecondaryReceiver,
        uint96 newRoyalty
    );
    event NewTokenURI(string newTokenURI);
    event Mint(address minterAddress, uint256 stage, uint256 mintCount);
    event URILocked();

    /// @dev Errors
    error AddressLimitPerTx();
    error AlreadyLockedURI();
    error BurnerIsNotApproved();
    error BurningOff();
    error CannotDeleteOngoingStage();
    error CannotEditPastStages();
    error ETHSendFail();
    error EndTimeInThePast();
    error EndTimeLessThanStartTime();
    error ExceedsMintsPerWallet();
    error ExceedsNFTsOnSale();
    error IncorrectIndex();
    error InvalidNonce();
    error InvalidStartTime();
    error InvalidTokenId();
    error LessNFTsOnSaleThanBefore();
    error MerkleProofFail();
    error MerkleStage();
    error NotEnoughETH();
    error NotEnoughStubsToBurn();
    error NotEnoughSupplyRemaining();
    error PhaseLimitEnd();
    error PhaseLimitExceedsTokenCount();
    error PhaseStartsBeforePriorPhaseEnd();
    error PublicStage();
    error ReusedHash();
    error SaleEnd();
    error SaleNotActive();
    error StageDoesNotExist();
    error StageLimitPerTx();
    error StartTimeInThePast();
    error TimeLimit();
    error TokenCountExceedsPhaseLimit();
    error TokenDoesNotExist();
    error TokenLimitPerTx();
    error TooManyStagesInTheFuture();
    error UnauthorisedUser();
    error UnrecognizableHash();
    error ZeroAddress();
}