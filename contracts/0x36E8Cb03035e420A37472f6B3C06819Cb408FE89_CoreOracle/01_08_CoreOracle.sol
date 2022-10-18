// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

import '../interfaces/IOracle.sol';
import '../interfaces/IBaseOracle.sol';
import '../interfaces/IERC20Wrapper.sol';

contract CoreOracle is IOracle, IBaseOracle, Ownable {
    struct TokenSetting {
        address route;
        uint16 liqThreshold; // The liquidation threshold, multiplied by 1e4.
    }

    /// The governor sets oracle token factor for a token.
    event SetTokenFactor(address indexed token, TokenSetting tokenFactor);
    /// The governor unsets oracle token factor for a token.
    event UnsetTokenFactor(address indexed token);
    /// The governor sets token whitelist for an ERC1155 token.
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
        require(tokens.length == routes.length, 'inconsistent length');
        for (uint256 idx = 0; idx < tokens.length; idx++) {
            tokenSettings[tokens[idx]].route = routes[idx];
            emit SetRoute(tokens[idx], routes[idx]);
        }
    }

    function _getPrice(address token) internal view returns (uint256) {
        uint256 px = IBaseOracle(tokenSettings[token].route).getPrice(token);
        require(px != 0, 'price oracle failure');
        return px;
    }

    /// @dev Return the USD based price of the given input, multiplied by 10**18.
    /// @param token The ERC-20 token to check the value.
    function getPrice(address token) external view override returns (uint256) {
        return _getPrice(token);
    }

    /// @dev Set oracle token factors for the given list of token addresses.
    /// @param tokens List of tokens to set info
    /// @param _tokenFactors List of oracle token factors
    function setTokenSettings(
        address[] memory tokens,
        TokenSetting[] memory _tokenFactors
    ) external onlyOwner {
        require(tokens.length == _tokenFactors.length, 'inconsistent length');
        for (uint256 idx = 0; idx < tokens.length; idx++) {
            require(
                _tokenFactors[idx].liqThreshold <= 10000,
                'borrow factor must be at least 100%'
            );
            tokenSettings[tokens[idx]] = _tokenFactors[idx];
            emit SetTokenFactor(tokens[idx], _tokenFactors[idx]);
        }
    }

    /// @dev Unset token factors for the given list of token addresses
    /// @param tokens List of tokens to unset info
    function unsetTokenSettings(address[] memory tokens) external onlyOwner {
        for (uint256 idx = 0; idx < tokens.length; idx++) {
            delete tokenSettings[tokens[idx]];
            emit UnsetTokenFactor(tokens[idx]);
        }
    }

    /// @dev Set whitelist status for the given list of token addresses.
    /// @param tokens List of tokens to set whitelist status
    /// @param ok Whitelist status
    function setWhitelistERC1155(address[] memory tokens, bool ok)
        external
        onlyOwner
    {
        for (uint256 idx = 0; idx < tokens.length; idx++) {
            whitelistedERC1155[tokens[idx]] = ok;
            emit SetWhitelist(tokens[idx], ok);
        }
    }

    /// @dev Return whether the oracle supports evaluating collateral value of the given token.
    /// @param token ERC1155 token address to check for support
    /// @param id ERC1155 token id to check for support
    function supportWrappedToken(address token, uint256 id)
        external
        view
        override
        returns (bool)
    {
        if (!whitelistedERC1155[token]) return false;
        address tokenUnderlying = IERC20Wrapper(token).getUnderlyingToken(id);
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
        require(whitelistedERC1155[token], 'bad token');
        address tokenUnderlying = IERC20Wrapper(token).getUnderlyingToken(id);
        uint256 rateUnderlying = IERC20Wrapper(token).getUnderlyingRate(id);
        uint256 amountUnderlying = (amount * rateUnderlying) / 1e18;
        TokenSetting memory tokenSetting = tokenSettings[tokenUnderlying];
        require(tokenSetting.route != address(0), 'bad underlying collateral');
        uint256 underlyingValue = (_getPrice(tokenUnderlying) *
            amountUnderlying) / 1e18;
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
        require(tokenSetting.liqThreshold != 0, 'bad underlying borrow');
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

    function getLiqThreshold(address token) external view returns (uint256) {
        return tokenSettings[token].liqThreshold;
    }
}