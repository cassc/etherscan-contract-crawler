// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IExpansionComic {
    /**
     * @notice Claim a Copy of a Page
     * @dev allows an issue front cover token holder to claim a copy of subsequent pages matching the front cover copy number
     * @param issueId the id of the issue that the claimer owns a subscription of
     * @param pageId the id of the page to claim which belongs to the same issue as the front cover
     * @param copyNumber the copy numbner to claim
     *
     * Requirements:
     *
     * - the sender must own the corresponding front cover from the issue
     * - the copy number must match the the front cover copy number owned
     *
     * Emits a {PageCopyClaimed} event.
     */
    function claimPageCopy(
        uint16 issueId,
        uint16 pageId,
        uint16 copyNumber
    ) external payable;

    /**
     * @notice Purchase a Copy of a Page
     * @dev allows a token gate NFT holder (if set) to mint a copy of a released page
     * @param issueId the id of the issue the page belongs to
     * @param pageId the id of the page to mint
     *
     * Emits a {PageCopyPurchased} event.
     */
    function purchasePageCopy(uint16 issueId, uint16 pageId) external payable;

    /**
     * @notice Subscribe to an Issue
     * @dev allows a token gate NFT holder (if set) to mint a copy of the front cover of a released issue
     * @param issueId the id of the issue to subscribe to
     *
     * Emits an {IssueSubscriptionPurchased} event.
     */
    function subscribeToIssue(uint16 issueId) external payable;

    /**
     * @notice Get Token ID
     * @dev gets the token id corresponding to a copy of an issue page
     * @param issueId the id of the issue
     * @param pageId the id of the page
     * @param copyNumber the number of the copy of the issue page
     * @return tokenId the resulting token id
     */
    function getTokenId(
        uint16 issueId,
        uint16 pageId,
        uint16 copyNumber
    ) external view returns (uint256 tokenId);

    /**
     * @notice Issue Released?
     * @dev checks if an issue is available to subscribe to based on its release date
     * @param issueId the id of the issue
     * @return bool has the issue been released
     */
    function issueReleased(uint16 issueId) external view returns (bool);

    /**
     * @notice Issue Page Released?
     * @dev checks if an issue page is available to mint based on its release date
     * @param issueId the id of the issue the page belngs to
     * @param pageId the id of the page to check
     * @return bool has the page been released
     */
    function issuePageReleased(
        uint16 issueId,
        uint16 pageId
    ) external view returns (bool);

    /**
     * @notice Issue Page Sale Ends
     * @dev calculates the time at which iisue page minting will end based on release date and sale duration
     * @param issueId the id of the issue the page belngs to
     * @param pageId the id of the page to check
     * @return uint256 the time in seconds at which minting will end
     */
    function issuePageSaleEnds(
        uint16 issueId,
        uint16 pageId
    ) external view returns (uint256);

    /**
     * @notice Issue Page Sold Out?
     * @dev calculates if an issue page has sold out based on supply and the sale end date
     * @param issueId the id of the issue the page belongs to
     * @param pageId the id of the page to check
     * @return bool has the page sold out
     */
    function issuePageSoldOut(
        uint16 issueId,
        uint16 pageId
    ) external view returns (bool);

    /**
     * @notice Issue Subscriptions Sold Out?
     * @dev check if all available subscriptions of an issue have been minted
     * @param issueId the id of the issue to check
     * @return bool have the issue subscriptions sold out
     */
    function issueSubscriptionsSoldOut(
        uint16 issueId
    ) external view returns (bool);

    /**
     * @notice Get Token Owner of Issue, Page, CopyNumber
     * @dev helper method to get the owner of a token from issue id, page id, and copy number
     * @param issueId id of the issue
     * @param pageId id of the issue page
     * @param copyNumber number of the page copy
     * @return address the address of the token owner
     */
    function ownerOfCopy(
        uint16 issueId,
        uint16 pageId,
        uint16 copyNumber
    ) external view returns (address);

    /**
     * @notice Token Copy Number
     * @dev calculates the copy number of an issue page from the tokenId
     * @param tokenId the id of the token for an issue page copy
     * @return copyNumber the number of the copy the token corresponds to
     */
    function tokenPageCopyNumber(
        uint256 tokenId
    ) external view returns (uint16 copyNumber);

    /**
     * @notice Token Issue ID
     * @dev calculates the issue id of an issue page copy from the tokenId
     * @param tokenId the id of the token to check
     * @return issueId the id of the issue the token corresponds to
     */
    function tokenIssueId(
        uint256 tokenId
    ) external view returns (uint16 issueId);

    /**
     * @notice Token Page ID
     * @dev calculates the page id of an issue page copy from the tokenId
     * @param tokenId the id of the token to check
     * @return pageId the id of the page the token corresponds to
     */
    function tokenPageId(uint256 tokenId) external view returns (uint16 pageId);

    /**
     * @notice Add Issue
     * @dev allows the contract owner to add a new issue
     * @param maxSubscribers the maximum number of subscriptions / front covers available to mint
     * @param price the price of a subscription to the issue
     * @param releaseDate the date from which subscriptions will be available to mint
     * @param tokenGateAddress the address of an external contract used to token gate subscriptions
     *
     * Emits an {IssueAdded} event.
     */
    function addIssue(
        uint16 maxSubscribers,
        uint64 price,
        uint64 releaseDate,
        address tokenGateAddress
    ) external;

    /**
     * @notice Add Page
     * @dev allows the contract owner to add a new page to an issue
     * @param issueId the id of the issue the page will belong to
     * @param maxSupply the number of copies of a page available to mint
     * @param price the price of a subscription to the issue
     * @param releaseDate the date from which subscriptions will be available to mint
     * @param saleDuration the duration of time the page will be available to mint after release
     * @param tokenGateAddress the address of an external contract used to token gate page minting
     *
     * Emits a {PageAdded} event.
     */
    function addPage(
        uint16 issueId,
        uint16 maxSupply,
        uint64 price,
        uint64 releaseDate,
        uint64 saleDuration,
        address tokenGateAddress
    ) external;

    /**
     * @notice Gift Issue Subscription
     * @dev allows the owner to airdrop an issue subscription/front cover
     *
     * Emits an {IssueSubscriptionGifted} event.
     */
    function giftIssueSubscription(uint16 issueId, address recipient) external;

    /**
     * @notice Gift Page Copy
     * @dev allows the owner to airdrop a copy of a page
     *
     * Emits an {PageCopyGifted} event.
     */
    function giftPageCopy(
        uint16 issueId,
        uint16 pageId,
        address recipient
    ) external;

    /**
     * @notice Mark Page as Double
     * @dev allows the owner to indicate that a page is a double page i.e. when purchased, the next page will also be minted automatically
     *
     * Emits a {DoublePage} event.
     */
    function setDoublePage(uint16 issueId, uint16 pageId) external;

    /**
     * @notice Update Issue Price
     * @dev allows the contract owner to update the price to subscribe to an issue
     *
     * Emits an {IssuePriceUpdated} event.
     */
    function updateIssuePrice(uint16 issueId, uint64 price) external;

    /**
     * @notice Update Issue Release Date
     * @dev allows the contract owner to update the time at which it will be possible to subscribe to an issue
     *
     * Requirements:
     *
     * - `releaseDate` must not be before the current block time
     *
     * Emits an {IssueReleaseDateUpdated} event.
     */
    function updateIssueReleaseDate(
        uint16 issueId,
        uint64 releaseDate
    ) external;

    /**
     * @notice Update Page Max Supply
     * @dev allows the contract owner to update the maximum number of page copies available to mint
     *
     * Requirements:
     *
     * - `maxSupply` must not be less than the number of page copies already minted
     *
     * Emits a {PageMaxSupplyUpdated} event.
     */
    function updatePageMaxSupply(
        uint16 issueId,
        uint16 pageId,
        uint16 maxSupply
    ) external;

    /**
     * @notice Update Page Price
     * @dev allows the contract owner to update the price to mint page copies
     *
     * Requirements:
     *
     * - `pageId` must not be 0 as this is the issue front cover page id which uses the issue price
     *
     * Emits a {PagePriceUpdated} event.
     */
    function updatePagePrice(
        uint16 issueId,
        uint16 pageId,
        uint64 price
    ) external;

    /**
     * @notice Update Page Release Date
     * @dev allows the contract owner to update the time at which it will be possible to mint page copies
     *
     * Requirements:
     *
     * - `releaseDate` must not be before the current block time
     * - `releaseDate` must not be before the release date of the issue the page belongs to
     *
     * Emits a {PageReleaseDateUpdated} event.
     */
    function updatePageReleaseDate(
        uint16 issueId,
        uint16 pageId,
        uint64 releaseDate
    ) external;

    /**
     * @notice Update Page Royalty Details
     * @dev allows the contract owner to update the receiver and royalty percentage for secondary page copy sales
     *
     * Requirements:
     *
     * - issue `issueId` page `pageId` must exist
     * - `receiver` must not be the zero address
     * - `bps` must not be greater than the fee denominator
     *
     * Emits a {PageRoyaltyUpdated} event.
     */
    function updatePageRoyaltyInfo(
        uint16 issueId,
        uint16 pageId,
        address receiver,
        uint96 royaltyBps
    ) external;

    /**
     * @notice Update Page Sale Duration
     * @dev allows the contract owner to update the duration that page copies are available to mint
     *
     * Requirements:
     *
     * - `pageId` must not be 0 as this is the issue front cover page id which does not have a sale duration
     *
     * Emits a {PageSaleDurationUpdated} event.
     */
    function updatePageSaleDuration(
        uint16 issueId,
        uint16 pageId,
        uint64 saleDuration
    ) external;

    /**
     * @notice Update Page Token Gate
     * @dev allows the contract owner to update the address of a contract used to token gate minting a page copy
     *
     * Emits a {PagePriceUpdated} event.
     */
    function updatePageTokenGate(
        uint16 issueId,
        uint16 pageId,
        address tokenGateAddress
    ) external;

    /**
     * @notice Update Page URI
     * @dev allows the contract owner to update the metadata uri for a page
     *
     * Emits a {PageURIUpdated} event.
     */
    function updatePageURI(
        uint16 issueId,
        uint16 pageId,
        string calldata uri
    ) external;
}