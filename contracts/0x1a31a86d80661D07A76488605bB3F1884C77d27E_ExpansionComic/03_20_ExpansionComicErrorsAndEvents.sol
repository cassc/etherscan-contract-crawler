// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract ExpansionComicErrorsAndEvents {
    error AlreadyReleased();
    error InvalidClaim();
    error InvalidMaxSupply();
    error InvalidPageId();
    error InvalidReceiver();
    error InvalidReleaseDate();
    error InvalidSubscription();
    error InvalidTokenId();
    error InvalidValue();
    error IssueDoesNotExist();
    error IssueSubscriptionsSoldOut();
    error MaxCopiesExceeded();
    error MaxPagesExceeded();
    error MaxSubscribersExceeded();
    error NoMoreCopiesAvailable();
    error NotEnoughEtherSent();
    error NotTheTokenOwner();
    error PageAlreadyClaimed();
    error PageDoesNotExist();
    error PageNotForSale();
    error PageSoldOut();
    error RoyaltyBpsTooHigh();
    error SubscriptionNotAvailable();
    error TokenGateNFTNotOwned();

    event DoublePage(uint16 indexed issueId, uint16 indexed pageId);
    event IssueAdded(uint16 indexed issueId);
    event IssuePriceUpdated(uint16 indexed issueId, uint64 price);
    event IssueReleaseDateUpdated(uint16 indexed issueId, uint64 releaseDate);
    event IssueSubscriptionGifted(
        uint16 indexed issueId,
        uint16 indexed subscriberNumber,
        address indexed subscriber
    );
    event IssueSubscriptionPurchased(
        uint16 indexed issueId,
        uint16 indexed subscriberNumber,
        address indexed subscriber
    );
    event PageAdded(uint16 indexed issueId, uint16 indexed pageId);
    event PageCopyClaimed(
        uint16 indexed issueId,
        uint16 indexed pageId,
        uint16 copyNumber,
        address indexed subscriber
    );
    event PageCopyGifted(
        uint16 indexed issueId,
        uint16 indexed pageId,
        uint16 copyNumber,
        address indexed recipient
    );
    event PageCopyPurchased(
        uint16 indexed issueId,
        uint16 indexed pageId,
        uint16 copyNumber,
        address indexed buyer
    );
    event PageMaxSupplyUpdated(
        uint16 indexed issueId,
        uint16 indexed pageId,
        uint16 supply
    );
    event PagePriceUpdated(
        uint16 indexed issueId,
        uint16 indexed pageId,
        uint64 price
    );
    event PageReleaseDateUpdated(
        uint16 indexed issueId,
        uint16 indexed pageId,
        uint64 releaseDate
    );
    event PageRoyaltyUpdated(
        uint16 indexed issueId,
        uint16 indexed pageId,
        address indexed receiver,
        uint96 royaltyBps
    );
    event PageSaleDurationUpdated(
        uint16 indexed issueId,
        uint16 indexed pageId,
        uint64 saleDuration
    );
    event PageTokenGateUpdated(
        uint16 indexed issueId,
        uint16 indexed pageId,
        address indexed tokenGateAddress
    );
    event PageURIUpdated(
        uint16 indexed issueId,
        uint16 indexed pageId,
        string uri
    );
}