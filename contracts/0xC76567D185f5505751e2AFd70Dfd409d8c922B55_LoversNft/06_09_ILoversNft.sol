// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ILoversNft {
    error MintingNotAllowed();
    error ExceedMaximumForTheRound();
    error ExceedMaximumSupply();
    error ExceedAllowedQuantity(uint16 maximumAllowedQuantity);
    error MaxMintingIdLowerThanCurrentId();
    error NoMatchingFee();
    error NonExistingToken(uint256 tokenId);
    error FailedToSendBalance();
    error BadRequest(string reason);
    error AlreadyRevealed();
    error ImmutableState();

    enum MintingType {
        REGULAR,
        ADMIN_ONLY
    }

    enum State {
        DEPLOYED,
        PREPARE_MINTING,
        ON_MINTING,
        END_MINTING,
        ALL_MINTING_DONE
    }

    struct Round {
        uint16 roundNumber; // round number
        MintingType mintingType;
        uint256 startTime; // round start time
        uint256 endTime; // round end time (if zero, no end time)
        uint16 maxMintingQuantity; // max number of tokens for an account (if zero, no limit)
        uint256 mintingFee; // minting for the round

        uint256 maxMintingId; // maximum token id for this round
        uint256 startId; // beginning of the tokenId for the round
        uint256 lastMintedId; // last token id actually minted before the next round starts
        string tokenURIPrefix; // directory hash value for token uri
        bool revealed; // released token is revealed or not
        uint256 revealBlockNumber; // blocknubmer which entropy will calculated
        uint256 randomSelection;
        uint256 closedTime;  // round closed timestamp
    }

    event NewRoundCreated(uint16 roundNumber);
    event RoundEnded(uint16 roundNumber);
    event MintingTypeChanged(uint16 roundNumber, MintingType mintingType);
    event MaxMintingIdChanged(uint16 roundNumber, uint256 maxId);
    event StartTimeChanged(uint16 roundNumber, uint256 time);
    event EndTimeChanged(uint16 roundNumber, uint256 time);
    event MaxMintingQuantityChanged(uint16 roundNumber, uint16 count);
    event MintingFeeChanged(uint16 roundNumber, uint256 newFee);
    event AdminUpdated(uint16 roundNumber, address admin);
    event TokenURIPrefixUpdated(uint16 roundNumber, string prefix);
    event SetRevealBlock(uint256 revealBlockNumber);
    event Revealed(uint16 roundNumber);
    event BaseURIUpdated(string baseURI);
    event DefaultUnrevealedURIUpdated(string defaultUnrevealedURI);
    event Received(address called, uint256 amount);
    event Withdraw(address receiver, uint256 amount);
}