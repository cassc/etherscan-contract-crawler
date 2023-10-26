// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import { AccessControlEnumerable } from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import { ILPTokenProcessorV2 } from "../interfaces/ILPTokenProcessorV2.sol";
import { IPricingModule } from "../interfaces/IPricingModule.sol";

/**
 * @title Pricing module V1
 * @notice This module calculates the required price to lock a set of tokens on
 * Project L. Pricing is determined by the number of tokens a user is trying to
 * lock in a vault, as well as the type of token. Project L uses the following
 * pricing tiers:
 *  - fungible tokens:           50 USDT flat fee per unique token address.
 *  - non-fungible tokens:       50 USDT flat fee per unique token address.
 *  - vested tokens:            100 USDT flat fee per unique token address.
 *  - liquidity pool tokens:    0.5 percent of the locked tokens.
 *
 * In case of liquidity pool tokens being vested, the pricing tier of 0.5
 * percent is used.
 */
contract PricingModuleV1 is IPricingModule, AccessControlEnumerable {
    /// @notice Price in USDT per unique token in a vault. This includes decimals.
    uint256 public ERC20_TOKEN_PRICE = 50 * 1e6;

    /// @notice Price in USDT per unique NFT in a vault. This includes decimals.
    uint256 public ERC721_TOKEN_PRICE = 100 * 1e6;

    /// @notice Price in USDT per unique token in a vault. This includes decimals.
    uint256 public ERC1155_TOKEN_PRICE = 100 * 1e6;

    /// @notice Price in USDT per unique vested token in a vault. This includes decimals.
    uint256 public ERC20_VESTED_TOKEN_PRICE = 100 * 1e6;

    /// @notice Price in basis points per unique LP token in a vault.
    uint256 public LP_TOKEN_BASIS_POINTS = 50;

    IERC721Enumerable[] public discountNFTs;

    ILPTokenProcessorV2 public lpTokenProcessor;

    uint8 public override priceDecimals;

    enum TokenType {
        ERC20,
        ERC721,
        ERC1155,
        ERC20_VESTED
    }

    event LPTokenProcessorUpdated(address indexed oldAddress, address indexed newAddress);
    event TokenPriceUpdated(uint256 indexed oldPrice, uint256 newPrice, TokenType indexed tokenType);
    event BasisPointsUpdated(uint256 indexed oldBasisPoints, uint256 indexed newBasisPoints);

    constructor(
        address[] memory discountNFTAddresses,
        uint256 lpTokenBasisPoints,
        address lpTokenProcessorAddress,
        uint256 tokenPrice,
        uint256 nftTokenPrice,
        uint256 multiTokenPrice,
        uint256 vestedTokenPrice,
        uint8 _priceDecimals
    ) {
        for (uint256 i = 0; i < discountNFTAddresses.length; i++) {
            require(discountNFTAddresses[i] != address(0), "PricingModuleV1::constructor::ZERO: Discount NFT cannot be zero address.");

            discountNFTs.push(IERC721Enumerable(discountNFTAddresses[i]));
        }
        require(lpTokenProcessorAddress != address(0), "PricingModuleV1::constructor::ZERO: LP Token Processor cannot be zero address.");

        lpTokenProcessor = ILPTokenProcessorV2(lpTokenProcessorAddress);

        ERC20_TOKEN_PRICE = tokenPrice;
        ERC721_TOKEN_PRICE = nftTokenPrice;
        ERC1155_TOKEN_PRICE = multiTokenPrice;
        ERC20_VESTED_TOKEN_PRICE = vestedTokenPrice;
        LP_TOKEN_BASIS_POINTS = lpTokenBasisPoints;

        priceDecimals = _priceDecimals;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function addDiscountNFTs(address[] memory newDiscountNFTs) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < newDiscountNFTs.length; i++) {
            require(newDiscountNFTs[i] != address(0), "PricingModuleV1::addDiscountNFTs::ZERO: Discount NFT cannot be zero address.");

            discountNFTs.push(IERC721Enumerable(newDiscountNFTs[i]));
        }
    }

    function setLPTokenProcessor(address newProcessor) external onlyRole(DEFAULT_ADMIN_ROLE) {
        address oldProcessor = address(lpTokenProcessor);
        lpTokenProcessor = ILPTokenProcessorV2(newProcessor);

        emit LPTokenProcessorUpdated(oldProcessor, newProcessor);
    }

    function setTokenPrice(uint256 newPrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 oldPrice = ERC20_TOKEN_PRICE;
        ERC20_TOKEN_PRICE = newPrice;

        emit TokenPriceUpdated(oldPrice, newPrice, TokenType.ERC20);
    }

    function setMultiTokenPrice(uint256 newPrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 oldPrice = ERC1155_TOKEN_PRICE;
        ERC1155_TOKEN_PRICE = newPrice;

        emit TokenPriceUpdated(oldPrice, newPrice, TokenType.ERC1155);
    }

    function setNftTokenPrice(uint256 newPrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 oldPrice = ERC721_TOKEN_PRICE;
        ERC721_TOKEN_PRICE = newPrice;

        emit TokenPriceUpdated(oldPrice, newPrice, TokenType.ERC721);
    }

    function setVestedTokenPrice(uint256 newPrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 oldPrice = ERC20_VESTED_TOKEN_PRICE;
        ERC20_VESTED_TOKEN_PRICE = newPrice;

        emit TokenPriceUpdated(oldPrice, newPrice, TokenType.ERC20_VESTED);
    }

    function setLPBasisPoints(uint256 newBasisPoints) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 oldBasisPoints = LP_TOKEN_BASIS_POINTS;
        LP_TOKEN_BASIS_POINTS = newBasisPoints;

        emit BasisPointsUpdated(oldBasisPoints, newBasisPoints);
    }

    function getPrice(
        address user,
        FungibleTokenDeposit[] memory fungibleTokenDeposits,
        NonFungibleTokenDeposit[] memory nonFungibleTokenDeposits,
        MultiTokenDeposit[] memory multiTokenDeposits,
        bool isVested
    ) external view override returns (PriceInfo memory) {
        // Array to hold addresses of V2 LP tokens in which payment will be
        // required.
        address[] memory lpV2Tokens = new address[](fungibleTokenDeposits.length);

        // Array containing payment amounts required per LP token. The indices
        // match the ones in `lpV2Tokens`.
        uint256[] memory lpV2Amounts = new uint256[](fungibleTokenDeposits.length);

        // Array to hold addresses of V3 LP tokens in which payment will be
        // required.
        V3LPData[] memory lpV3Tokens = new V3LPData[](nonFungibleTokenDeposits.length);

        // The pricing model for fungible tokens is unique due to the fact that
        // they could be liquidity pool tokens.
        bool hasFungibleToken = false;
        for (uint256 i = 0; i < fungibleTokenDeposits.length; i++) {
            if (lpTokenProcessor.isV2LiquidityPoolToken(fungibleTokenDeposits[i].tokenAddress)) {
                lpV2Tokens[i] = fungibleTokenDeposits[i].tokenAddress;
                lpV2Amounts[i] = (fungibleTokenDeposits[i].amount * LP_TOKEN_BASIS_POINTS) / 10000;
            } else {
                hasFungibleToken = true;
            }
        }
        bool hasNonFungibleToken = false;
        for (uint256 i = 0; i < nonFungibleTokenDeposits.length; i++) {
            address tokenAddress = nonFungibleTokenDeposits[i].tokenAddress;
            uint256 tokenId = nonFungibleTokenDeposits[i].tokenId;
            (address token0, address token1, uint128 liquidity, uint24 fee) = lpTokenProcessor.getV3Position(tokenAddress, tokenId);
            if (token0 != address(0)) {
                lpV3Tokens[i].tokenAddress = tokenAddress;
                lpV3Tokens[i].token0 = token0;
                lpV3Tokens[i].token1 = token1;
                lpV3Tokens[i].liquidityToRemove = uint128((liquidity * LP_TOKEN_BASIS_POINTS) / 10000);
                lpV3Tokens[i].fee = fee;
            } else {
                hasNonFungibleToken = true;
            }
        }
        bool hasMultiToken = multiTokenDeposits.length > 0;
        uint256 usdCost = _calculateFlatPrice(user, isVested, hasFungibleToken, hasNonFungibleToken, hasMultiToken);

        return PriceInfo({ v2LpTokens: lpV2Tokens, v2LpAmounts: lpV2Amounts, v3LpTokens: lpV3Tokens, usdtAmount: usdCost });
    }

    function _calculateFlatPrice(
        address user,
        bool isVested,
        bool hasFungibleToken,
        bool hasNonFungibleToken,
        bool hasMultiToken
    ) private view returns (uint256 usdCost) {
        if (_hasDiscount(user)) {
            return 0;
        }

        // The USDT price per token.
        uint256 tokenPrice = isVested ? ERC20_VESTED_TOKEN_PRICE : ERC20_TOKEN_PRICE;

        if (hasFungibleToken) {
            usdCost += tokenPrice;
        }

        // Non-fungible and multi token pricing is per token and therefore
        // needs no uniqueness checks.
        if (hasNonFungibleToken) {
            usdCost += ERC721_TOKEN_PRICE;
        }
        if (hasMultiToken) {
            usdCost += ERC1155_TOKEN_PRICE;
        }
    }

    function _hasDiscount(address user) private view returns (bool) {
        for (uint256 i = 0; i < discountNFTs.length; i++) {
            uint256 balance = discountNFTs[i].balanceOf(user);
            if (balance > 0) {
                return true;
            }
        }
        return false;
    }
}