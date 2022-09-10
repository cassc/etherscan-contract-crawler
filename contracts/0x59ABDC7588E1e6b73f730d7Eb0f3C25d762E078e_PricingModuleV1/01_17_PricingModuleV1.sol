// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import "../interfaces/IDepositHandler.sol";
import "../interfaces/ILPTokenProcessor.sol";

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
contract PricingModuleV1 is IDepositHandler, AccessControlEnumerable {
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
    IERC20Metadata public USDT;

    ILPTokenProcessor public lpTokenProcessor;

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
        address usdtAddress,
        uint256 vestedTokenPrice
    ) {
        for (uint256 i = 0; i < discountNFTAddresses.length; i++) {
            require(
                discountNFTAddresses[i] != address(0),
                "PricingModuleV1::constructor::ZERO: Discount NFT cannot be zero address."
            );

            discountNFTs.push(IERC721Enumerable(discountNFTAddresses[i]));
        }
        require(
            lpTokenProcessorAddress != address(0),
            "PricingModuleV1::constructor::ZERO: LP Token Processor cannot be zero address."
        );
        require(usdtAddress != address(0), "PricingModuleV1::constructor::ZERO: USDT cannot be zero address.");

        lpTokenProcessor = ILPTokenProcessor(lpTokenProcessorAddress);
        USDT = IERC20Metadata(usdtAddress);

        ERC20_TOKEN_PRICE = tokenPrice;
        ERC721_TOKEN_PRICE = nftTokenPrice;
        ERC1155_TOKEN_PRICE = multiTokenPrice;
        ERC20_VESTED_TOKEN_PRICE = vestedTokenPrice;
        LP_TOKEN_BASIS_POINTS = lpTokenBasisPoints;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setLPTokenProcessor(address newProcessor) external onlyRole(DEFAULT_ADMIN_ROLE) {
        address oldProcessor = address(lpTokenProcessor);
        lpTokenProcessor = ILPTokenProcessor(newProcessor);

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
        address, /* vault */
        address user,
        address, /* referrer */
        FungibleTokenDeposit[] memory fungibleTokenDeposits,
        NonFungibleTokenDeposit[] memory nonFungibleTokenDeposits,
        MultiTokenDeposit[] memory multiTokenDeposits,
        bool isVested
    )
        external
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256
        )
    {
        // The USDT part of the pricing model.
        uint256 usdtCost = 0;

        // The USDT price per token.
        uint256 tokenPrice = isVested ? ERC20_VESTED_TOKEN_PRICE : ERC20_TOKEN_PRICE;

        // Array to hold addresses of LP tokens in which payment will be
        // required.
        address[] memory paymentTokens = new address[](fungibleTokenDeposits.length);

        // Array containing payment amounts requires per LP token. The indices
        // match the ones in `paymentTokens`.
        uint256[] memory paymentAmounts = new uint256[](fungibleTokenDeposits.length);

        // The pricing model for fungible tokens is unique due to the fact that
        // they could be liquidity pool tokens. Even though this might also be
        // the case for Uniswap V3 liquidity positions, we do not differentiate
        // between those positions and regular non-fungible tokens yet.
        for (uint256 i = 0; i < fungibleTokenDeposits.length; i++) {
            if (lpTokenProcessor.isLiquidityPoolToken(fungibleTokenDeposits[i].tokenAddress)) {
                paymentTokens[i] = fungibleTokenDeposits[i].tokenAddress;
                paymentAmounts[i] = (fungibleTokenDeposits[i].amount * LP_TOKEN_BASIS_POINTS) / 10000;
            } else {
                usdtCost += tokenPrice;
            }
        }

        // Vesting vaults can only contain fungible tokens. For this reason,
        // the non-fungible and multi tokens are entirely disregarded in the
        // pricing model. It is assumed that the vault factory will block any
        // attempts at creating such a vault until the feature is supported.
        if (!isVested) {
            // Non-fungible and multi token pricing is per token and therefor
            // needs no uniqueness checks.
            usdtCost += nonFungibleTokenDeposits.length * ERC721_TOKEN_PRICE;
            usdtCost += multiTokenDeposits.length * ERC1155_TOKEN_PRICE;
        }

        if (_hasDiscount(user)) {
            usdtCost = 0;
        }

        return (paymentTokens, paymentAmounts, usdtCost);
    }

    function _hasDiscount(address user) private view returns (bool) {
        for (uint256 i = 0; i < discountNFTs.length; i++) {
            try discountNFTs[i].tokenOfOwnerByIndex(user, 0) returns (uint256) {
                return true;
            } catch (
                bytes memory /* lowLevelData */
            ) {}
        }

        return false;
    }
}