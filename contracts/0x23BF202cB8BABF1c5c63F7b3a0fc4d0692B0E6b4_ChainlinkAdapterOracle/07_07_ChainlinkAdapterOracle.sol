// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeCast.sol';

import '../BlueBerryErrors.sol';
import '../interfaces/IBaseOracle.sol';
import '../interfaces/chainlink/IFeedRegistry.sol';

contract ChainlinkAdapterOracle is IBaseOracle, Ownable {
    using SafeCast for int256;

    // Chainlink denominations
    // (source: https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/Denominations.sol)
    IFeedRegistry public registry;
    address public constant USD = address(840);

    /// @dev Mapping from original token to remapped token for price querying (e.g. WBTC -> BTC, renBTC -> BTC)
    mapping(address => address) public remappedTokens;
    /// @dev Mapping from token address to max delay time
    mapping(address => uint256) public maxDelayTimes;

    event SetRegistry(address registry);
    event SetMaxDelayTime(address indexed token, uint256 maxDelayTime);
    event SetTokenRemapping(
        address indexed token,
        address indexed remappedToken
    );

    constructor(IFeedRegistry registry_) {
        if (address(registry_) == address(0)) revert ZERO_ADDRESS();

        registry = registry_;
    }

    /// @dev Set chainlink feed registry source
    /// @param _registry Chainlink feed registry source
    function setFeedRegistry(IFeedRegistry _registry) external onlyOwner {
        if (address(_registry) == address(0)) revert ZERO_ADDRESS();
        registry = _registry;
        emit SetRegistry(address(_registry));
    }

    /// @dev Set max delay time for each token
    /// @param tokens List of remapped tokens to set max delay
    /// @param maxDelays List of max delay times to set to
    function setMaxDelayTimes(
        address[] calldata tokens,
        uint256[] calldata maxDelays
    ) external onlyOwner {
        if (tokens.length != maxDelays.length) revert INPUT_ARRAY_MISMATCH();
        for (uint256 idx = 0; idx < tokens.length; idx++) {
            if (maxDelays[idx] > 2 days) revert TOO_LONG_DELAY(maxDelays[idx]);
            if (tokens[idx] == address(0)) revert ZERO_ADDRESS();
            maxDelayTimes[tokens[idx]] = maxDelays[idx];
            emit SetMaxDelayTime(tokens[idx], maxDelays[idx]);
        }
    }

    /// @dev Set token remapping
    /// @param _tokens List of tokens to set remapping
    /// @param _remappedTokens List of tokens to set remapping to
    /// @notice Token decimals of the original and remapped tokens should be the same
    function setTokenRemappings(
        address[] calldata _tokens,
        address[] calldata _remappedTokens
    ) external onlyOwner {
        if (_remappedTokens.length != _tokens.length)
            revert INPUT_ARRAY_MISMATCH();
        for (uint256 idx = 0; idx < _tokens.length; idx++) {
            if (_remappedTokens[idx] == address(0)) revert ZERO_ADDRESS();
            if (_tokens[idx] == address(0)) revert ZERO_ADDRESS();
            remappedTokens[_tokens[idx]] = _remappedTokens[idx];
            emit SetTokenRemapping(_tokens[idx], _remappedTokens[idx]);
        }
    }

    /**
     * @notice Returns the USD based price of given token, price value has 18 decimals
     * @param _token Token address to get price of
     * @return price USD price of token in 18 decimal
     */
    function getPrice(address _token) external view override returns (uint256) {
        // remap token if possible
        address token = remappedTokens[_token];
        if (token == address(0)) token = _token;

        uint256 maxDelayTime = maxDelayTimes[token];
        if (maxDelayTime == 0) revert NO_MAX_DELAY(_token);

        // try to get token-USD price
        uint256 decimals = registry.decimals(token, USD);
        (, int256 answer, , uint256 updatedAt, ) = registry.latestRoundData(
            token,
            USD
        );
        if (updatedAt < block.timestamp - maxDelayTime)
            revert PRICE_OUTDATED(_token);

        return (answer.toUint256() * 1e18) / 10**decimals;
    }
}