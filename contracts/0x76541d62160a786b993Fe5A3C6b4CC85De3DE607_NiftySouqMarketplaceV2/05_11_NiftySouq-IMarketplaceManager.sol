// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

enum ContractType {
    NIFTY_V1,
    NIFTY_V2,
    COLLECTOR,
    EXTERNAL,
    UNSUPPORTED
}
struct CalculatePayout {
    uint256 tokenId;
    address contractAddress;
    address seller;
    uint256 price;
    uint256 quantity;
}

interface NiftySouqIMarketplaceManager {
    struct LazyMintSellData {
        address tokenAddress;
        string uri;
        address seller;
        address[] creators;
        uint256[] royalties;
        address[] investors;
        uint256[] revenues;
        uint256 minPrice;
        uint256 quantity;
        bytes signature;
    }

    struct LazyMintAuctionData {
        address tokenAddress;
        string uri;
        address seller;
        address[] creators;
        uint256[] royalties;
        address[] investors;
        uint256[] revenues;
        uint256 startTime;
        uint256 duration;
        uint256 startBidPrice;
        uint256 reservePrice;
        bytes signature;
    }

    struct CryptoTokens {
        address tokenAddress;
        uint256 tokenValue;
        bool isEnabled;
    }

    function owner() external returns (address);

    function isAdmin(address caller_) external view returns (bool);

    function serviceFeeWallet() external returns (address);

    function serviceFeePercent() external returns (uint256);

    function cryptoTokenList(string memory)
        external
        returns (CryptoTokens memory);

    function verifyFixedPriceLazyMint(LazyMintSellData calldata lazyData_)
        external
        returns (address);

    function verifyAuctionLazyMint(LazyMintAuctionData calldata lazyData_)
        external
        returns (address);

    function getContractDetails(address contractAddress_, uint256 quantity_)
        external
        returns (ContractType contractType_, bool isERC1155_, address tokenAddress_);

    function isOwnerOfNFT(
        address address_,
        uint256 tokenId_,
        address contractAddress_
    )
        external
        returns (
            ContractType contractType_,
            bool isERC1155_,
            bool isOwner_,
            uint256 quantity_
        );

    function calculatePayout(CalculatePayout memory calculatePayout_)
        external
        returns (
            address[] memory recepientAddresses_,
            uint256[] memory paymentAmount_,
            bool isTokenTransferable_,
            bool isOwner_
        );
}