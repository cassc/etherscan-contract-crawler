// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeCast.sol';

import '../interfaces/IBaseOracle.sol';
import '../interfaces/chainlink/IFeedRegistry.sol';

contract ChainlinkAdapterOracle is IBaseOracle, Ownable {
    using SafeCast for int256;

    event SetMaxDelayTime(address indexed token, uint256 maxDelayTime);
    event SetTokenRemapping(
        address indexed token,
        address indexed remappedToken
    );

    // Chainlink denominations
    // (source: https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/Denominations.sol)
    IFeedRegistry public registry;
    address public constant USD = address(840);

    /// @dev Mapping from original token to remapped token for price querying (e.g. WBTC -> BTC, renBTC -> BTC)
    mapping(address => address) public remappedTokens;
    /// @dev Mapping from token address to max delay time
    mapping(address => uint256) public maxDelayTimes;

    constructor(IFeedRegistry registry_) {
        registry = registry_;
    }

    /// @dev Set max delay time for each token
    /// @param _remappedTokens List of remapped tokens to set max delay
    /// @param _maxDelayTimes List of max delay times to set to
    function setMaxDelayTimes(
        address[] calldata _remappedTokens,
        uint256[] calldata _maxDelayTimes
    ) external onlyOwner {
        require(
            _remappedTokens.length == _maxDelayTimes.length,
            '_remappedTokens & _maxDelayTimes length mismatched'
        );
        for (uint256 idx = 0; idx < _remappedTokens.length; idx++) {
            maxDelayTimes[_remappedTokens[idx]] = _maxDelayTimes[idx];
            emit SetMaxDelayTime(_remappedTokens[idx], _maxDelayTimes[idx]);
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
        require(
            _tokens.length == _remappedTokens.length,
            '_tokens & _remappedTokens length mismatched'
        );
        for (uint256 idx = 0; idx < _tokens.length; idx++) {
            remappedTokens[_tokens[idx]] = _remappedTokens[idx];
            emit SetTokenRemapping(_tokens[idx], _remappedTokens[idx]);
        }
    }

    /// @dev Return the USD based price of the given input, multiplied by 10**18.
    /// @param _token Token address to get price of
    function getPrice(address _token) external view override returns (uint256) {
        // remap token if possible
        address token = remappedTokens[_token];
        if (token == address(0)) token = _token;

        uint256 maxDelayTime = maxDelayTimes[token];
        require(maxDelayTime != 0, 'max delay time not set');

        // try to get token-USD price
        uint256 decimals = registry.decimals(token, USD);
        (, int256 answer, , uint256 updatedAt, ) = registry.latestRoundData(
            token,
            USD
        );
        require(
            updatedAt >= block.timestamp - maxDelayTime,
            'delayed token-eth update time'
        );
        return (answer.toUint256() * 1e18) / 10**decimals;
    }
}