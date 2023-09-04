// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "./IERC20Token.sol";
import "./ITypeTokens.sol";
import "./ITokenPairs.sol";

interface ITokenManager is ITypeTokens, ITokenPairs {
    enum TokenType {
        Undefined, // 0 indicates not in the pool
        Asset, // Asset tokens for reserve, e.g., USDT
        Stable // Stable tokens of Unitas protocol, e.g., USD1, USD91
    }

    struct PairConfig {
        address baseToken;
        address quoteToken;
        /**
         * @notice The numerator of swapping fee ratio when buying `baseToken`
         */
        uint24 buyFee;
        uint232 buyReserveRatioThreshold;
        /**
         * @notice The numerator of swapping fee ratio when selling `baseToken`
         */
        uint24 sellFee;
        uint232 sellReserveRatioThreshold;
    }

    struct TokenConfig {
        address token;
        TokenType tokenType;
        uint256 minPrice;
        uint256 maxPrice;
    }

    function setUSD1(address token) external;

    function setMinMaxPriceTolerance(address token, uint256 minPrice, uint256 maxPrice) external;

    function addTokensAndPairs(TokenConfig[] calldata tokens, PairConfig[] calldata pairs) external;

    function removeTokensAndPairs(address[] calldata tokens, address[] calldata pairTokensX, address[] calldata pairTokensY) external;

    function updatePairs(PairConfig[] calldata pairs) external;

    function RESERVE_RATIO_BASE() external view returns (uint256);

    function SWAP_FEE_BASE() external view returns (uint256);

    function usd1() external view returns (IERC20Token);

    function listPairsByIndexAndCount(uint256 index, uint256 count) external view returns (PairConfig[] memory);

    function getPriceTolerance(address token) external view returns (uint256 minPrice, uint256 maxPrice);

    function getTokenType(address token) external view returns (TokenType);

    function getPair(address tokenX, address tokenY) external view returns (PairConfig memory pair);

    function pairByIndex(uint256 index) external view returns (PairConfig memory pair);
}