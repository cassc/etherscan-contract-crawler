// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISodiumFreePool {
    struct InitializeStruct {
        address sodiumPass;
        address oracle;
        address manager721;
        address manager1155;
        address weth;
    }

    struct BorrowingTerms {
        uint256 APR;
        uint256 LTV; // percentage which is allowed for a loan; should be expressed in thousands; if LTV - 70% => 7000 or LTV - 5% => 500
    }

    struct Message {
        bytes32 id;
        bytes payload;
        uint256 timestamp; // The UNIX timestamp when the message was signed by the oracle
        bytes signature; // ECDSA signature or EIP-2098 compact signature
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event FixedValueSet(address[] collections, uint256[] values);
    event PoolLiquidityAdded(uint256 amount);
    event PoolLiquidityWithdrawn(uint256 amount);
    event PoolBorrowingTermsAdded(address[] collections, BorrowingTerms[] borrowingTerms);
    event PoolBorrowingTermsRemoved(address[] collections);

    /// @notice Borrow from pools; can be called only by erc721Manager or erc1155Manager
    /// @param collectionCollateral_ nft which will be used as a collateral
    /// @param borrower_ borrower address
    /// @param amount_ amount to borrow
    /// @param amountBorrowed_ total liquidity added to a loan,
    /// @param loanLength_ loan length
    /// @param message_ oracle message
    function borrow(
        address collectionCollateral_,
        address borrower_,
        uint256 amount_,
        uint256 amountBorrowed_,
        uint256 loanLength_,
        Message calldata message_
    ) external returns (uint256);

    /// @notice Makes a bid through a pool to erc721 manager
    /// @param auctionId_ auction id
    /// @param amount_ bid size
    /// @param index_ index of a pool in the lender queue inside the manager; if used a bid will be boosted with liquidity added to a loan
    function bidERC721(
        uint256 auctionId_,
        uint256 amount_,
        uint256 index_
    ) external;

    /// @notice Makes a bid through a pool to erc1155 manager
    /// @param auctionId_ auction id
    /// @param amount_ bid size
    /// @param index_ index of a pool in the lender queue inside the manager; if used a bid will be boosted with liquidity added to a loan
    function bidERC1155(
        uint256 auctionId_,
        uint256 amount_,
        uint256 index_
    ) external;

    /// @notice Makes a purchase through a pool to erc721 manager
    /// @param auctionId_ auction id
    /// @param amount_ which will be spent
    function purchaseERC721(uint256 auctionId_, uint256 amount_) external;

    /// @notice Makes a purchase through a pool to erc1155 manager
    /// @param auctionId_ auction id
    /// @param amount_ which will be spent
    function purchaseERC1155(uint256 auctionId_, uint256 amount_) external;

    /// @notice Makes an auction resolution through a pool to erc721 manager
    /// @param auctionId_ auction id
    /// @param amount_ which will be spent
    function resolveAuctionERC721(uint256 auctionId_, uint256 amount_) external;

    /// @notice Makes an auction resolution through a pool to erc1155 manager
    /// @param auctionId_ auction id
    /// @param amount_ which will be spent
    function resolveAuctionERC1155(uint256 auctionId_, uint256 amount_) external;

    /// @notice Used to set fixed floor price for a collection
    /// @param collections_ array of collections
    /// @param fixedValues_ array of floor price values
    function setFixedValue(address[] calldata collections_, uint256[] calldata fixedValues_) external;

    /// @notice Used to set fixed floor price for a collection
    /// @param collection_ collection
    function getFixedValue(address collection_) external view returns (uint256);

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155Received(
        address operator,
        address from,
        uint256 tokenId,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    function depositETH() external payable;

    function withdrawWETH(uint256 amount_) external;

    function depositWETH(uint256 amount_) external;

    function setTermsForCollection(
        address[] calldata collectionsToRemove_,
        address[] calldata collections_,
        BorrowingTerms[] calldata borrowingTerms_
    ) external;

    function setfloorPriceLifetime(uint256 floorPriceLifetime_) external;
}