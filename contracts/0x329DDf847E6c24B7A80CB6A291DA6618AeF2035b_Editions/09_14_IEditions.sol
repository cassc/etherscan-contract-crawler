// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface IEditionsEvents {
    event EditionPurchased(
        uint256 indexed tokenId,
        address indexed nftRecipient,
        uint256 amountPaid
    );

    event RoyaltyChange(
        address indexed oldRoyaltyRecipient,
        uint256 oldRoyaltyBPS,
        address indexed newRoyaltyRecipient,
        uint256 newRoyaltyBPS
    );

    event RendererSet(address indexed renderer);

    event EditionLimitSet(uint256 oldLimit, uint256 newLimit);

    event Withdrawal(address indexed recipient, uint256 amount, uint256 fee);

    event FundingRecipientSet(
        address indexed oldFundingRecipient,
        address indexed newFundingRecipient
    );

    event PriceSet(uint256 price);
}

interface IEditions {
    struct Edition {
        // Edition price
        uint256 price;
        // Edition supply limit
        uint256 limit;
        // Edition contentHash
        bytes32 contentHash;
    }

    // ============ Authorization ============

    function factory() external returns (address);

    // ============ Fee Configuration ============

    function feeConfig() external returns (address);

    function treasuryConfig() external returns (address);

    // ============ Edition Data ============

    function price() external returns (uint256);

    function limit() external returns (uint256);

    function contentHash() external returns (bytes32);

    // ============ Royalty Info (ERC2981) ============

    function royaltyRecipient() external returns (address);

    function royaltyBPS() external returns (uint256);

    // ============ Rendering ============

    function renderer() external view returns (address);

    // ============ Initializing ============

    function initialize(
        address owner_,
        string memory name_,
        string memory symbol_,
        string memory contentURI_,
        string memory contractURI_,
        Edition memory edition_,
        bool paused_
    ) external;

    // ============ Pause Methods ============

    function unpause() external;

    function pause() external;

    // ============ Allocation ============

    function allocate(address recipient, uint256 count) external;

    // ============ Purchase ============

    function purchase(address recipient)
        external
        payable
        returns (uint256 tokenId);

    // ============ Minting ============

    function mint(address recipient) external returns (uint256 tokenId);

    function setLimit(uint256 limit_) external;

    // ============ ERC2981 Methods ============

    function setRoyaltyInfo(
        address payable royaltyRecipient_,
        uint256 royaltyPercentage_
    ) external;

    // ============ Rendering Methods ============

    function setRenderer(address renderer_) external;

    function contractURI() external view returns (string memory);

    // ============ Withdrawal ============

    function setPrice(uint256 price_) external;

    function withdraw(uint16 feeBPS, address fundingRecipient) external;
}