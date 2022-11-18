// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../interfaces/periphery/IOracle.sol";
import "../access/Governable.sol";

/**
 * @title MasterOracle
 */
contract MasterOracle is IOracle, Governable {
    /**
     * @notice Default oracle to use when token hasn't custom oracle
     */
    IOracle public defaultOracle;

    /**
     * @notice Custom tokens' oracles
     * @dev Useful when dealing with special tokens (e.g. LP, IB, etc)
     */
    mapping(address => IOracle) public oracles;

    /// @notice Emitted when a token's oracle is set
    event TokenOracleUpdated(address indexed token, IOracle indexed oracle);

    /// @notice Emitted when the default oracle is updated
    event DefaultOracleUpdated(IOracle indexed defaultOracle);

    constructor(IOracle defaultOracle_) {
        defaultOracle = defaultOracle_;
    }

    /// @inheritdoc IOracle
    function getPriceInUsd(address token_) public view override returns (uint256 _priceInUsd) {
        IOracle _oracle = oracles[token_];

        if (address(_oracle) != address(0)) {
            _priceInUsd = _oracle.getPriceInUsd(token_);
        } else if (address(defaultOracle) != address(0)) {
            _priceInUsd = defaultOracle.getPriceInUsd(token_);
        } else {
            revert("token-without-oracle");
        }

        require(_priceInUsd > 0, "invalid-token-price");
    }

    /// @inheritdoc IOracle
    function quote(
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_
    ) external view virtual override returns (uint256 _amountOut) {
        _amountOut = quoteUsdToToken(tokenOut_, quoteTokenToUsd(tokenIn_, amountIn_));
    }

    /// @inheritdoc IOracle
    function quoteTokenToUsd(address token_, uint256 amountIn_) public view override returns (uint256 _amountOut) {
        _amountOut = (amountIn_ * getPriceInUsd(token_)) / 10**IERC20Metadata(token_).decimals();
    }

    /// @inheritdoc IOracle
    function quoteUsdToToken(address token_, uint256 amountIn_) public view override returns (uint256 _amountOut) {
        _amountOut = (amountIn_ * 10**IERC20Metadata(token_).decimals()) / getPriceInUsd(token_);
    }

    /// @notice Set custom oracle for a token
    function _updateTokenOracle(address token_, IOracle oracle_) private {
        oracles[token_] = oracle_;
        emit TokenOracleUpdated(token_, oracle_);
    }

    /// @notice Update the default oracle
    function updateDefaultOracle(IOracle defaultOracle_) external onlyGovernor {
        defaultOracle = defaultOracle_;
        emit DefaultOracleUpdated(defaultOracle_);
    }

    /// @notice Set custom oracle for a token
    function updateTokenOracle(address token_, IOracle oracle_) external onlyGovernor {
        _updateTokenOracle(token_, oracle_);
    }

    /**
     * @notice Set custom oracles for a set of tokens
     * @dev We allow null address inside of the `oracles_` array in order to turn off oracle for a given asset
     */
    function updateTokenOracles(address[] calldata tokens_, IOracle[] calldata oracles_) external onlyGovernor {
        uint256 _tokensLength = tokens_.length;
        require(_tokensLength > 0 && _tokensLength == oracles_.length, "invalid-arrays-length");

        for (uint256 i; i < _tokensLength; ++i) {
            address _token = tokens_[i];
            require(_token != address(0), "a-token-has-null-address");
            _updateTokenOracle(_token, oracles_[i]);
        }
    }
}