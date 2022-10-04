// SPDX-License-Identifier: WISE

pragma solidity =0.8.17;

contract LiquidEvents {

    event CollectionAdded(
        address nftAddress
    );

    event FundsDeposited(
        address indexed user,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );

    event FundsWithdrawn(
        address indexed user,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );

    event FundsBorrowed(
        address indexed nftAddress,
        uint256 indexed nftTokenId,
        address indexed borrower,
        uint256 amount,
        uint256 timestamp
    );

    event MoreFundsBorrowed(
        address indexed nftAddress,
        uint256 indexed nftTokenId,
        address indexed borrower,
        uint256 amount,
        uint256 timestamp
    );

    event FundsReturned(
        address indexed nftAddress,
        address indexed tokenOwner,
        uint256 totalPayment,
        uint256 nftTokenId,
        uint256 timestamp
    );

    event DiscountChanged(
        uint256 oldFactor,
        uint256 newFactor
    );

    event Liquidated(
        address indexed nftAddress,
        uint256 nftTokenId,
        address previousOwner,
        address currentOwner,
        uint256 discountAmount,
        uint256 timestamp
    );

    event PoolFunded(
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 badDebt,
        uint256 timestamp
    );

    event DecreaseBadDebt(
        uint256 newBadDebt,
        uint256 paybackAmount,
        uint256 timestamp
    );

    event ManualSyncPool(
        uint256 indexed updateTime
    );
}
