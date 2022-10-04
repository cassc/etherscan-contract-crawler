// SPDX-License-Identifier: WISE

pragma solidity =0.8.17;

contract RouterEvents {

    event FundsDeposited(
        address indexed pool,
        address indexed user,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );

    event FundsWithdrawn(
        address indexed pool,
        address indexed user,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );

    event FundsBorrowed(
        address indexed pool,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 amount,
        address borrower,
        uint256 timestamp
    );

    event MoreFundsBorrowed(
        address indexed pool,
        address indexed nftAddress,
        address indexed borrower,
        uint256 tokenId,
        uint256 amount,
        uint256 timestamp
    );

    event FundsReturned(
        address indexed pool,
        address indexed nftAddress,
        address indexed tokenOwner,
        uint256 transferAmount,
        uint256 tokenId,
        uint256 timestamp
    );

    event LiquidPoolRegistered(
        address indexed pool,
        uint256 timestamp
    );

    event Liquidated(
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 discountAmount,
        address indexed liquidator,
        uint256 timestamp
    );

    event RootAnnounced(
        address caller,
        uint256 unlockTime,
        address indexed nftAddress,
        bytes32 indexed merkleRoot,
        string indexed ipfsAddress
    );

    event RootUpdated(
        address caller,
        uint256 updateTime,
        address indexed nftAddress,
        bytes32 indexed merkleRoot,
        string indexed ipfsAddress
    );

    event UpdateAnnounced(
        address caller,
        uint256 unlockTime,
        address indexed pool,
        address indexed nftAddress
    );

    event PoolUpdated(
        address caller,
        uint256 updateTime,
        address indexed pool,
        address indexed nftAddress
    );

    event FeeDestinatoinChanged(
        address indexed pool,
        address indexed newDestination
    );

    event ExpansionRevoked(
        address pool
    );
}
