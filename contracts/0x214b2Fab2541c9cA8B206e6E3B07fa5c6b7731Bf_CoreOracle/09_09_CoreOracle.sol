// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

import '../BlueBerryErrors.sol';
import '../interfaces/IOracle.sol';
import '../interfaces/IBaseOracle.sol';
import '../interfaces/IERC20Wrapper.sol';

contract CoreOracle is IOracle, IBaseOracle, Ownable {
    struct TokenSetting {
        address route;
        uint16 liqThreshold; // The liquidation threshold, multiplied by 1e4.
    }

    /// The owner sets oracle token factor for a token.
    event SetTokenSetting(address indexed token, TokenSetting tokenFactor);
    /// The owner unsets oracle token factor for a token.
    event RemoveTokenSetting(address indexed token);
    /// The owner sets token whitelist for an ERC1155 token.
    event SetWhitelist(address indexed token, bool ok);
    event SetRoute(address indexed token, address route);

    mapping(address => TokenSetting) public tokenSettings; // Mapping from token address to oracle info.
    mapping(address => bool) public whitelistedERC1155; // Mapping from token address to whitelist status

    /// @dev Set oracle source routes for tokens
    /// @param tokens List of tokens
    /// @param routes List of oracle source routes
    function setRoute(address[] calldata tokens, address[] calldata routes)
        external
        onlyOwner
    {
        if (tokens.length != routes.length) revert INPUT_ARRAY_MISMATCH();
        for (uint256 idx = 0; idx < tokens.length; idx++) {
            if (tokens[idx] == address(0) || routes[idx] == address(0))
                revert ZERO_ADDRESS();

            tokenSettings[tokens[idx]].route = routes[idx];
            emit SetRoute(tokens[idx], routes[idx]);
        }
    }

    /// @dev Set oracle token factors for the given list of token addresses.
    /// @param tokens List of tokens to set info
    /// @param settings List of oracle token factors
    function setTokenSettings(
        address[] memory tokens,
        TokenSetting[] memory settings
    ) external onlyOwner {
        if (tokens.length != settings.length) revert INPUT_ARRAY_MISMATCH();
        for (uint256 idx = 0; idx < tokens.length; idx++) {
            if (tokens[idx] == address(0) || settings[idx].route == address(0))
                revert ZERO_ADDRESS();
            if (settings[idx].liqThreshold > 10000)
                revert LIQ_THRESHOLD_TOO_HIGH(settings[idx].liqThreshold);
            tokenSettings[tokens[idx]] = settings[idx];
            emit SetTokenSetting(tokens[idx], settings[idx]);
        }
    }

    /// @dev Unset token factors for the given list of token addresses
    /// @param tokens List of tokens to unset info
    function removeTokenSettings(address[] memory tokens) external onlyOwner {
        for (uint256 idx = 0; idx < tokens.length; idx++) {
            delete tokenSettings[tokens[idx]];
            emit RemoveTokenSetting(tokens[idx]);
        }
    }

    /// @dev Whitelist ERC1155(wrapped tokens)
    /// @param tokens List of tokens to set whitelist status
    /// @param ok Whitelist status
    function setWhitelistERC1155(address[] memory tokens, bool ok)
        external
        onlyOwner
    {
        for (uint256 idx = 0; idx < tokens.length; idx++) {
            if (tokens[idx] == address(0)) revert ZERO_ADDRESS();
            whitelistedERC1155[tokens[idx]] = ok;
            emit SetWhitelist(tokens[idx], ok);
        }
    }

    function _getPrice(address token) internal view returns (uint256) {
        uint256 px = IBaseOracle(tokenSettings[token].route).getPrice(token);
        if (px == 0) revert PRICE_FAILED(token);
        return px;
    }

    /// @dev Return the USD based price of the given input, multiplied by 10**18.
    /// @param token The ERC-20 token to check the value.
    function getPrice(address token) external view override returns (uint256) {
        return _getPrice(token);
    }

    /// @dev Return whether the oracle supports evaluating collateral value of the given token.
    /// @param token ERC1155 token address to check for support
    /// @param tokenId ERC1155 token id to check for support
    function supportWrappedToken(address token, uint256 tokenId)
        external
        view
        override
        returns (bool)
    {
        if (!whitelistedERC1155[token]) return false;
        address tokenUnderlying = IERC20Wrapper(token).getUnderlyingToken(
            tokenId
        );
        return tokenSettings[tokenUnderlying].route != address(0);
    }

    /**
     * @dev Return whether the ERC20 token is supported
     * @param token The ERC20 token to check for support
     */
    function support(address token) external view override returns (bool) {
        uint256 price = _getPrice(token);
        return price != 0;
    }

    /**
     * @dev Return the USD value of the given input for collateral purpose.
     * @param token ERC1155 token address to get collateral value
     * @param id ERC1155 token id to get collateral value
     * @param amount Token amount to get collateral value, based 1e18
     */
    function getCollateralValue(
        address token,
        uint256 id,
        uint256 amount
    ) external view override returns (uint256) {
        if (!whitelistedERC1155[token]) revert ERC1155_NOT_WHITELISTED(token);
        address uToken = IERC20Wrapper(token).getUnderlyingToken(id);
        TokenSetting memory tokenSetting = tokenSettings[uToken];
        if (tokenSetting.route == address(0)) revert NO_ORACLE_ROUTE(uToken);

        // Underlying token is LP token, and it always has 18 decimals
        // so skipped getting LP decimals
        uint256 underlyingValue = (_getPrice(uToken) * amount) / 1e18;
        return underlyingValue;
    }

    /**
     * @dev Return the USD value of the given input for borrow purpose.
     * @param token ERC20 token address to get borrow value
     * @param amount ERC20 token amount to get borrow value
     */
    function getDebtValue(address token, uint256 amount)
        external
        view
        override
        returns (uint256)
    {
        TokenSetting memory tokenSetting = tokenSettings[token];
        if (tokenSetting.route == address(0)) revert NO_ORACLE_ROUTE(token);
        uint256 decimals = IERC20Metadata(token).decimals();
        uint256 debtValue = (_getPrice(token) * amount) / 10**decimals;
        return debtValue;
    }

    /**
     * @dev Return the USD value of isolated collateral.
     * @param token ERC20 token address to get collateral value
     * @param amount ERC20 token amount to get collateral value
     */
    function getUnderlyingValue(address token, uint256 amount)
        external
        view
        returns (uint256 collateralValue)
    {
        uint256 decimals = IERC20Metadata(token).decimals();
        collateralValue = (_getPrice(token) * amount) / 10**decimals;
    }

    /// @dev Return the amount of token out as liquidation reward for liquidating token in.
    /// @param tokenIn Input ERC20 token
    /// @param tokenOut Output ERC1155 token
    /// @param tokenOutId Output ERC1155 token id
    /// @param amountIn Input ERC20 token amount
    function convertForLiquidation(
        address tokenIn,
        address tokenOut,
        uint256 tokenOutId,
        uint256 amountIn
    ) external view override returns (uint256) {
        if (!whitelistedERC1155[tokenOut])
            revert ERC1155_NOT_WHITELISTED(tokenOut);
        address tokenOutUnderlying = IERC20Wrapper(tokenOut).getUnderlyingToken(
            tokenOutId
        );
        TokenSetting memory tokenSettingIn = tokenSettings[tokenIn];
        TokenSetting memory tokenSettingOut = tokenSettings[tokenOutUnderlying];

        if (tokenSettingIn.route == address(0)) revert NO_ORACLE_ROUTE(tokenIn);
        if (tokenSettingOut.route == address(0))
            revert NO_ORACLE_ROUTE(tokenOutUnderlying);

        uint256 priceIn = _getPrice(tokenIn);
        uint256 priceOut = _getPrice(tokenOutUnderlying);
        uint256 decimalIn = IERC20Metadata(tokenIn).decimals();
        uint256 decimalOut = IERC20Metadata(tokenOutUnderlying).decimals();

        uint256 amountOut = (amountIn * priceIn * 10**decimalOut) /
            (priceOut * 10**decimalIn);
        return amountOut;
    }

    /**
     * @notice Returns the Liquidation Threshold setting of collateral token.
     * @notice 80% for volatile tokens, 90% for stablecoins
     * @param token Underlying token address
     * @return liqThreshold of given token
     */
    function getLiqThreshold(address token) external view returns (uint256) {
        return tokenSettings[token].liqThreshold;
    }
}