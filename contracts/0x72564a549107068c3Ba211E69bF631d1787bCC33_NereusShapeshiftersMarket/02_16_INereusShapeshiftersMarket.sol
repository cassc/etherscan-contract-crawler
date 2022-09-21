// SPDX-License-Identifier: MIT

pragma solidity >=0.8.7 <0.9.0;

interface INereusShapeshiftersMarket {
    struct SaleWave {
        bool isWhitelistable;
        bytes32 merkleRoot;
        uint256 claimAllowance;
        uint256 totalWaveAllocation;
        uint256 wavePurchased;
        uint256 waveNumber;
        bool active;
    }

    struct SaleWaveTokenPrice {
        uint8 tokenNumber;
        uint256 price;
    }

    // emits when new sales wave added
    event SalesWaveAdded(uint256 waveId, bool isWhitelistable);
    // emits when current sales wave set
    event SalesWaveSet(uint256 waveId);
    // emits when new erc20 token allowed to use for buys
    event BuyTokenAllowed(address tokenAddress);
    // emits when erc20 token disallowed for buy
    event BuyTokenDisallowed(address tokenAddress);
    // emits when user performs a purchase of nft
    event NFTPurchased(address buyer, uint256 tokenId, string tokenUri, uint256 waveId);
    // emits when admin withdraws contract balance
    event BalanceWithdrawn(uint256 amount);
    // emits when admin giveaways collection minter to deBridge
    event CollectionRevokeOwnerAndMinters();
}