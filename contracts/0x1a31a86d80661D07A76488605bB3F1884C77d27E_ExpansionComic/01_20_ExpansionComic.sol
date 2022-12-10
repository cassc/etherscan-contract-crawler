// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {ERC721OwnableRoyaltyOperatorFilterBase} from "./ERC721OwnableRoyaltyOperatorFilterBase.sol";
import {ExpansionComicErrorsAndEvents} from "./ExpansionComicErrorsAndEvents.sol";
import {IExpansionComic} from "./IExpansionComic.sol";

/**
 * @title Expansion Comic
 * @custom:artist @mattylaboosh
 * @custom:developer @renshawdev
 */
contract ExpansionComic is
    ERC721OwnableRoyaltyOperatorFilterBase,
    ExpansionComicErrorsAndEvents,
    IExpansionComic
{
    using Strings for uint256;

    struct Issue {
        uint16 maxSubscribers;
        uint16 pageCount;
        uint64 price;
        uint16 subscribers;
    }

    struct Page {
        uint16 copyCount;
        uint16 maxSupply;
        uint64 price;
        uint64 releaseDate;
        uint64 saleDuration;
        IERC721 tokenGate;
        string uri;
    }

    /// @dev mapping from an issue id to issue data
    mapping(uint16 => Issue) public issues;

    /// @dev mapping from an issue id and page id to page data
    mapping(uint16 => mapping(uint16 => Page)) public issuePages;

    /// @dev mapping to represent if a page is doubled up i.e. 2 for 1
    mapping(uint16 => mapping(uint16 => bool)) public doublePage;

    /// @dev mapping from issue id and page id to royalty details
    mapping(uint16 => mapping(uint16 => Royalty)) issuePageRoyalties;

    /// @dev used to calculate the issue counterpart of a token id
    uint256 constant ISSUE_MULTIPLIER = 1_000_000;

    /// @dev used to calculate the page counterpart of a token id
    uint256 constant PAGE_MULTIPLIER = 1_000;

    /// @dev the maximum possible number of copies of a page
    uint256 constant MAX_COPIES = 999;

    /// @dev the maximum possible number of pages of an issue
    uint256 constant MAX_PAGES = 999;

    /// @dev the number of issues
    uint16 public issueCount;

    /// @dev the number of tokens minted
    uint256 public totalSupply;

    // * MODIFIERS * //

    modifier onlyExistingIssue(uint16 issueId) {
        if (_issueDoesNotExist(issueId)) revert IssueDoesNotExist();
        _;
    }

    modifier onlyExistingPage(uint16 issueId, uint16 pageId) {
        if (_issuePageDoesNotExist(issueId, pageId)) revert PageDoesNotExist();
        _;
    }

    // * CONSTRUCTOR * //

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        string memory contractURI_,
        address royaltyReceiver,
        uint96 royaltyBps
    )
        ERC721OwnableRoyaltyOperatorFilterBase(
            name_,
            symbol_,
            baseURI_,
            contractURI_,
            royaltyReceiver,
            royaltyBps
        )
    {}

    // * PAYABLE * //

    /// @inheritdoc IExpansionComic
    function claimPageCopy(
        uint16 issueId,
        uint16 pageId,
        uint16 copyNumber
    ) public payable whenNotPaused {
        if (_issuePageDoesNotExist(issueId, pageId)) revert PageDoesNotExist();
        uint256 subscriptionTokenId = getTokenId(issueId, 0, copyNumber);
        if (!_exists(subscriptionTokenId)) revert InvalidSubscription();
        if (msg.sender != ownerOf(subscriptionTokenId))
            revert InvalidSubscription();

        uint256 tokenId = getTokenId(issueId, pageId, copyNumber);
        if (_exists(tokenId)) revert PageAlreadyClaimed();

        totalSupply++;
        _safeMint(msg.sender, tokenId);
        emit PageCopyClaimed(issueId, pageId, copyNumber, msg.sender);
    }

    /// @inheritdoc IExpansionComic
    function purchasePageCopy(
        uint16 issueId,
        uint16 pageId
    ) public payable whenNotPaused nonReentrant {
        if (pageId == 0) revert InvalidPageId();
        if (!issuePageReleased(issueId, pageId)) revert PageNotForSale();
        if (issuePageSoldOut(issueId, pageId)) revert PageSoldOut();

        if (msg.value < issuePages[issueId][pageId].price)
            revert NotEnoughEtherSent();

        IERC721 TokenGate = issuePages[issueId][pageId].tokenGate;
        if (address(TokenGate) != address(0)) {
            if (TokenGate.balanceOf(msg.sender) == 0)
                revert TokenGateNFTNotOwned();
        }

        unchecked {
            uint16 copyCount = issuePages[issueId][pageId].copyCount;
            uint256 tokenId = _nextTokenId(issueId, pageId, copyCount);
            issuePages[issueId][pageId].copyCount++;
            uint256 count = 1;
            _safeMint(msg.sender, tokenId);

            emit PageCopyPurchased(issueId, pageId, copyCount + 1, msg.sender);

            if (doublePage[issueId][pageId]) {
                tokenId = _nextTokenId(issueId, pageId + 1, copyCount);
                issuePages[issueId][pageId + 1].copyCount++;
                ++count;
                _safeMint(msg.sender, tokenId);

                emit PageCopyPurchased(
                    issueId,
                    pageId + 1,
                    copyCount + 1,
                    msg.sender
                );
            }

            totalSupply += count;
        }
    }

    /// @inheritdoc IExpansionComic
    function subscribeToIssue(
        uint16 issueId
    ) public payable whenNotPaused nonReentrant {
        if (!issueReleased(issueId)) revert SubscriptionNotAvailable();
        if (issueSubscriptionsSoldOut(issueId))
            revert IssueSubscriptionsSoldOut();

        if (msg.value < issues[issueId].price) revert NotEnoughEtherSent();

        IERC721 TokenGate = issuePages[issueId][0].tokenGate;
        if (address(TokenGate) != address(0)) {
            if (TokenGate.balanceOf(msg.sender) == 0)
                revert TokenGateNFTNotOwned();
        }

        unchecked {
            uint16 subscriberCount = issues[issueId].subscribers;
            uint256 tokenId = _nextSubscriberTokenId(issueId, subscriberCount);
            issues[issueId].subscribers++;
            totalSupply++;
            _safeMint(msg.sender, tokenId);
            emit IssueSubscriptionPurchased(
                issueId,
                subscriberCount + 1,
                msg.sender
            );
        }
    }

    // * PUBLIC * //

    /// @inheritdoc IExpansionComic
    function getTokenId(
        uint16 issueId,
        uint16 pageId,
        uint16 copyNumber
    ) public pure returns (uint256 tokenId) {
        unchecked {
            tokenId =
                _tokenIssueCounterpart(issueId) +
                _tokenPageCounterpart(pageId) +
                copyNumber;
        }
    }

    /// @inheritdoc IExpansionComic
    function issueReleased(uint16 issueId) public view returns (bool) {
        return issuePageReleased(issueId, 0);
    }

    /// @inheritdoc IExpansionComic
    function issuePageReleased(
        uint16 issueId,
        uint16 pageId
    ) public view onlyExistingPage(issueId, pageId) returns (bool) {
        return block.timestamp >= issuePages[issueId][pageId].releaseDate;
    }

    /// @inheritdoc IExpansionComic
    function issuePageSaleEnds(
        uint16 issueId,
        uint16 pageId
    ) public view returns (uint256) {
        return
            issuePages[issueId][pageId].releaseDate +
            issuePages[issueId][pageId].saleDuration;
    }

    /// @inheritdoc IExpansionComic
    function issuePageSoldOut(
        uint16 issueId,
        uint16 pageId
    ) public view returns (bool) {
        return
            block.timestamp > issuePageSaleEnds(issueId, pageId) ||
            issuePages[issueId][pageId].copyCount ==
            issuePages[issueId][pageId].maxSupply;
    }

    /// @inheritdoc IExpansionComic
    function issueSubscriptionsSoldOut(
        uint16 issueId
    ) public view returns (bool) {
        return issues[issueId].subscribers == issues[issueId].maxSubscribers;
    }

    /// @inheritdoc IExpansionComic
    function ownerOfCopy(
        uint16 issueId,
        uint16 pageId,
        uint16 copyNumber
    ) public view returns (address) {
        return ownerOf(getTokenId(issueId, pageId, copyNumber));
    }

    /// @inheritdoc IERC2981
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) public view override returns (address, uint256) {
        uint16 issueId = tokenIssueId(tokenId);
        uint16 pageId = tokenPageId(tokenId);
        Royalty memory royalty = issuePageRoyalties[issueId][pageId];
        if (royalty.receiver == address(0))
            royalty = issuePageRoyalties[issueId][0];
        if (royalty.receiver == address(0)) royalty = _defaultRoyalty;

        uint256 royaltyAmount = (salePrice * royalty.royaltyFraction) /
            ROYALTY_DENOMINATOR;

        return (royalty.receiver, royaltyAmount);
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(
        bytes4 interfaceId
    ) public view override returns (bool) {
        return
            interfaceId == type(IExpansionComic).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @inheritdoc IExpansionComic
    function tokenPageCopyNumber(
        uint256 tokenId
    ) public view returns (uint16 copyNumber) {
        uint16 issueId = tokenIssueId(tokenId);
        uint16 pageId = tokenPageId(tokenId);
        copyNumber = uint16(
            tokenId -
                _tokenIssueCounterpart(issueId) -
                _tokenPageCounterpart(pageId)
        );

        if (copyNumber == 0) revert InvalidTokenId();

        if (pageId == 0) {
            if (copyNumber > issues[issueId].maxSubscribers) {
                revert InvalidTokenId();
            }
        }

        if (copyNumber > issuePages[issueId][pageId].copyCount) {
            revert InvalidTokenId();
        }
    }

    /// @inheritdoc IExpansionComic
    function tokenIssueId(
        uint256 tokenId
    ) public view returns (uint16 issueId) {
        issueId = uint16(tokenId / ISSUE_MULTIPLIER);
        if (issueId == 0 || issueId > issueCount) revert InvalidTokenId();
    }

    /// @inheritdoc IExpansionComic
    function tokenPageId(uint256 tokenId) public view returns (uint16 pageId) {
        uint16 issueId = tokenIssueId(tokenId);
        pageId = uint16(
            (tokenId - _tokenIssueCounterpart(issueId)) / PAGE_MULTIPLIER
        );
        if (pageId > issues[issueId].pageCount) revert InvalidTokenId();
    }

    /// @inheritdoc IERC721Metadata
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (!_exists(tokenId)) revert InvalidTokenId();

        uint16 issueId = tokenIssueId(tokenId);
        uint16 pageId = tokenPageId(tokenId);
        uint16 copyNumber = tokenPageCopyNumber(tokenId);
        string memory pageURI = issuePages[issueId][pageId].uri;

        if (bytes(pageURI).length > 0)
            return
                string(
                    abi.encodePacked(
                        pageURI,
                        "/",
                        uint256(copyNumber).toString(),
                        ".json"
                    )
                );

        if (bytes(baseURI).length > 0) {
            return
                string(
                    abi.encodePacked(
                        baseURI,
                        "/",
                        uint256(issueId).toString(),
                        "-",
                        uint256(pageId).toString(),
                        "-",
                        uint256(copyNumber).toString(),
                        ".json"
                    )
                );
        }

        return "";
    }

    // * OWNER * //

    /// @inheritdoc IExpansionComic
    function addIssue(
        uint16 maxSubscribers,
        uint64 price,
        uint64 releaseDate,
        address tokenGateAddress
    ) public onlyOwner {
        if (maxSubscribers > MAX_COPIES) revert MaxSubscribersExceeded();
        issueCount++;
        uint16 issueId = issueCount;

        issues[issueId].maxSubscribers = maxSubscribers;
        issues[issueId].price = price;

        issuePages[issueId][0].copyCount = maxSubscribers;
        issuePages[issueId][0].maxSupply = maxSubscribers;
        issuePages[issueId][0].releaseDate = releaseDate;
        issuePages[issueId][0].tokenGate = IERC721(tokenGateAddress);

        emit IssueAdded(issueId);
    }

    /// @inheritdoc IExpansionComic
    function addPage(
        uint16 issueId,
        uint16 maxSupply,
        uint64 price,
        uint64 releaseDate,
        uint64 saleDuration,
        address tokenGateAddress
    ) public onlyOwner onlyExistingIssue(issueId) {
        if (maxSupply > MAX_COPIES) revert MaxCopiesExceeded();

        uint16 minCopies = issues[issueId].maxSubscribers;
        if (maxSupply < minCopies) revert InvalidMaxSupply();

        uint16 pageId = issues[issueId].pageCount + 1;
        if (pageId > MAX_PAGES) revert MaxPagesExceeded();
        issues[issueId].pageCount++;

        if (releaseDate < issuePages[issueId][0].releaseDate)
            revert InvalidReleaseDate();

        issuePages[issueId][pageId] = Page({
            copyCount: minCopies,
            maxSupply: maxSupply,
            price: price,
            releaseDate: releaseDate,
            saleDuration: saleDuration,
            tokenGate: IERC721(tokenGateAddress),
            uri: ""
        });

        emit PageAdded(issueId, pageId);
    }

    /// @inheritdoc IExpansionComic
    function giftIssueSubscription(
        uint16 issueId,
        address recipient
    ) public onlyOwner {
        if (issueSubscriptionsSoldOut(issueId))
            revert IssueSubscriptionsSoldOut();

        unchecked {
            uint16 subscriberCount = issues[issueId].subscribers;
            uint256 tokenId = _nextSubscriberTokenId(issueId, subscriberCount);
            issues[issueId].subscribers++;
            totalSupply++;
            _safeMint(recipient, tokenId);
            emit IssueSubscriptionGifted(
                issueId,
                subscriberCount + 1,
                recipient
            );
        }
    }

    /// @inheritdoc IExpansionComic
    function giftPageCopy(
        uint16 issueId,
        uint16 pageId,
        address recipient
    ) public onlyOwner {
        if (pageId == 0) revert InvalidPageId();
        if (issuePageSoldOut(issueId, pageId)) revert PageSoldOut();

        unchecked {
            uint16 copyCount = issuePages[issueId][pageId].copyCount;
            uint256 tokenId = _nextTokenId(issueId, pageId, copyCount);
            issuePages[issueId][pageId].copyCount++;
            totalSupply++;
            _safeMint(recipient, tokenId);
            emit PageCopyGifted(issueId, pageId, copyCount + 1, recipient);
        }
    }

    /// @inheritdoc IExpansionComic
    function setDoublePage(
        uint16 issueId,
        uint16 pageId
    ) public onlyOwner onlyExistingPage(issueId, pageId + 1) {
        doublePage[issueId][pageId] = true;
        emit DoublePage(issueId, pageId);
    }

    /// @inheritdoc IExpansionComic
    function updateIssuePrice(
        uint16 issueId,
        uint64 price
    ) public onlyOwner onlyExistingIssue(issueId) {
        issues[issueId].price = price;
        emit IssuePriceUpdated(issueId, price);
    }

    /// @inheritdoc IExpansionComic
    function updateIssueReleaseDate(
        uint16 issueId,
        uint64 releaseDate
    ) public onlyOwner onlyExistingIssue(issueId) {
        if (issueReleased(issueId)) revert AlreadyReleased();
        if (releaseDate < block.timestamp) revert InvalidReleaseDate();
        issuePages[issueId][0].releaseDate = releaseDate;
        emit IssueReleaseDateUpdated(issueId, releaseDate);
    }

    /// @inheritdoc IExpansionComic
    function updatePageMaxSupply(
        uint16 issueId,
        uint16 pageId,
        uint16 maxSupply
    ) public onlyOwner onlyExistingPage(issueId, pageId) {
        if (maxSupply < issuePages[issueId][pageId].copyCount)
            revert InvalidValue();
        if (maxSupply > MAX_COPIES) revert MaxCopiesExceeded();
        issuePages[issueId][pageId].maxSupply = maxSupply;
        emit PageMaxSupplyUpdated(issueId, pageId, maxSupply);
    }

    /// @inheritdoc IExpansionComic
    function updatePagePrice(
        uint16 issueId,
        uint16 pageId,
        uint64 price
    ) public onlyOwner onlyExistingPage(issueId, pageId) {
        if (pageId == 0) revert InvalidPageId();
        issuePages[issueId][pageId].price = price;
        emit PagePriceUpdated(issueId, pageId, price);
    }

    /// @inheritdoc IExpansionComic
    function updatePageReleaseDate(
        uint16 issueId,
        uint16 pageId,
        uint64 releaseDate
    ) public onlyOwner onlyExistingPage(issueId, pageId) {
        if (pageId == 0) revert InvalidPageId();
        if (issuePageReleased(issueId, pageId)) revert AlreadyReleased();
        if (releaseDate < block.timestamp) revert InvalidReleaseDate();
        if (releaseDate < issuePages[issueId][0].releaseDate)
            revert InvalidReleaseDate();
        issuePages[issueId][pageId].releaseDate = releaseDate;
        emit PageReleaseDateUpdated(issueId, pageId, releaseDate);
    }

    /// @inheritdoc IExpansionComic
    function updatePageRoyaltyInfo(
        uint16 issueId,
        uint16 pageId,
        address receiver,
        uint96 royaltyBps
    ) public onlyOwner onlyExistingPage(issueId, pageId) {
        if (royaltyBps > ROYALTY_DENOMINATOR) revert RoyaltyBpsTooHigh();
        if (receiver != address(0)) {
            issuePageRoyalties[issueId][pageId] = Royalty(receiver, royaltyBps);
            emit PageRoyaltyUpdated(issueId, pageId, receiver, royaltyBps);
        } else {
            delete issuePageRoyalties[issueId][pageId];
            emit PageRoyaltyUpdated(issueId, pageId, address(0), 0);
        }
    }

    /// @inheritdoc IExpansionComic
    function updatePageSaleDuration(
        uint16 issueId,
        uint16 pageId,
        uint64 saleDuration
    ) public onlyOwner onlyExistingPage(issueId, pageId) {
        if (pageId == 0) revert InvalidPageId();
        if (
            issuePages[issueId][pageId].copyCount ==
            issuePages[issueId][pageId].maxSupply
        ) revert PageSoldOut();
        issuePages[issueId][pageId].saleDuration = saleDuration;
        emit PageSaleDurationUpdated(issueId, pageId, saleDuration);
    }

    /// @inheritdoc IExpansionComic
    function updatePageTokenGate(
        uint16 issueId,
        uint16 pageId,
        address tokenGateAddress
    ) public onlyOwner onlyExistingPage(issueId, pageId) {
        issuePages[issueId][pageId].tokenGate = IERC721(tokenGateAddress);
        emit PageTokenGateUpdated(issueId, pageId, tokenGateAddress);
    }

    /// @inheritdoc IExpansionComic
    function updatePageURI(
        uint16 issueId,
        uint16 pageId,
        string calldata uri
    ) public onlyOwner onlyExistingPage(issueId, pageId) {
        issuePages[issueId][pageId].uri = uri;
        emit PageURIUpdated(issueId, pageId, uri);
    }

    // * INTERNAL * //

    /**
     * @dev calculates whether an issue exists or for an id
     */
    function _issueDoesNotExist(uint16 issueId) internal view returns (bool) {
        return issueId == 0 || issueId > issueCount;
    }

    /**
     * @dev calculates whether a page exists or for an issue id and page id
     */
    function _issuePageDoesNotExist(
        uint16 issueId,
        uint16 pageId
    ) internal view returns (bool) {
        return
            _issueDoesNotExist(issueId) || pageId > issues[issueId].pageCount;
    }

    /**
     * @dev calculates the next token id to mint for an issue subscription / front cover page
     */
    function _nextSubscriberTokenId(
        uint16 issueId,
        uint16 subscriberCount
    ) internal pure returns (uint256) {
        unchecked {
            return _tokenIssueCounterpart(issueId) + subscriberCount + 1;
        }
    }

    /**
     * @dev calculates the next token id to mint a copy of an issue page
     */
    function _nextTokenId(
        uint16 issueId,
        uint16 pageId,
        uint16 copyCount
    ) internal pure returns (uint256) {
        return getTokenId(issueId, pageId, copyCount + 1);
    }

    /**
     * @dev calculates the value used to represent an issue as part of a token id
     */
    function _tokenIssueCounterpart(
        uint16 issueId
    ) internal pure returns (uint256) {
        unchecked {
            return issueId * ISSUE_MULTIPLIER;
        }
    }

    /**
     * @dev calculates the value used to represent a page as part of a token id
     */
    function _tokenPageCounterpart(
        uint16 pageId
    ) internal pure returns (uint256) {
        unchecked {
            return pageId * PAGE_MULTIPLIER;
        }
    }
}