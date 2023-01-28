//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

error ExceedsCollectionMaxSupply(uint256 supplyLeft, uint256 mintAmount);
error ExceedsMaxWalletMint(
    uint256 maxWalletMint,
    uint256 mintAmount,
    uint256 userMinted
);
error CollectionDoesNotExist();
error PublicSaleNotStarted(uint256 startTime);
error PublicSaleEnded(uint256 endTime);
error IncorrectPaymentAmount(uint256 price, uint256 paymentAmount);
error WhitelistNotStarted(uint256 startTime);
error WhitelistEnded(uint256 endTime);
error ExceedsMaxWhitelistMint(
    uint256 maxWhitelistMint,
    uint256 mintAmount,
    uint256 userMinted
);
error WhitelistMerkleRootNotSet();
error NotWhitelisted();