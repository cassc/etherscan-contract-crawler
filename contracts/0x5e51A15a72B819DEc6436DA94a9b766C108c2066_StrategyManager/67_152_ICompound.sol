// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.9.0;
pragma experimental ABIEncoderV2;

interface ICompound {
    enum PriceSource {
        FIXED_ETH, /// implies the fixedPrice is a constant multiple of the ETH price (which varies)
        FIXED_USD, /// implies the fixedPrice is a constant multiple of the USD price (which is 1)
        REPORTER /// implies the price is set by the reporter
    }

    struct TokenConfig {
        address cToken;
        address underlying;
        bytes32 symbolHash;
        uint256 baseUnit;
        PriceSource priceSource;
        uint256 fixedPrice;
        address uniswapMarket;
        bool isUniswapReversed;
    }

    struct CompBalanceMetadata {
        uint256 balance;
        uint256 votes;
        address delegate;
    }

    struct CompBalanceMetadataExt {
        uint256 balance;
        uint256 votes;
        address delegate;
        uint256 allocated;
    }

    function getCompBalanceMetadataExt(
        address comp,
        address comptroller,
        address account
    ) external returns (CompBalanceMetadataExt memory);

    function mint(uint256 mintAmount) external returns (uint256);

    function mint() external payable;

    function redeem(uint256 redeemTokens) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function claimComp(address holder) external;

    function getCompBalanceMetadata(address comp, address account) external view returns (CompBalanceMetadata memory);

    function exchangeRateStored() external view returns (uint256);

    function totalBorrows() external view returns (uint256);

    function totalReserves() external view returns (uint256);

    function getCash() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function underlying() external view returns (address);

    function decimals() external view returns (uint8);

    function compAccrued(address holder) external view returns (uint256);

    function getTokenConfigByUnderlying(address) external view returns (TokenConfig memory);

    function supplyRatePerBlock() external view returns (uint256);

    function comptroller() external view returns (address);

    function getCompAddress() external view returns (address);
}