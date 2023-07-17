// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/IRatioAdapter.sol";

// utility contract to support different interfaces of get ratio
contract RatioAdapter is OwnableUpgradeable, IRatioAdapter {

    enum Approach {
        REDIRECT, // value conversion can be executed in token contract
        BY_INCREASING_RATIO, // we can get only ratio that increasing
        BY_DECREASING_RATIO // we can get only ratio that decreasing (ex. ankrETH)
    }

    struct TokenData {
        string ratio; // method signature to get ratio
        string from; // method signature to get lst from asset
        string to; // method signature to get asset from lst
        Approach approach; // Approach of token
        address provider; // target of method call
    }

    mapping(address => TokenData) internal data;

    /// @custom:oz-upgrades-unsafe-allow constructor
    // --- Constructor ---
    constructor() { _disableInitializers(); }

    // --- Init ---
    function initialize() external initializer {
        __Ownable_init();
    }

    /// @notice get token amount of asset value
    function fromValue(address token, uint256 amount) external view returns (uint256) {
        TokenData memory tokenData = data[token];
        address provider = tokenData.provider == address(0) ? token : tokenData.provider;

        if (tokenData.approach == Approach.REDIRECT) {
            return _callWithAm(provider, tokenData.from, amount);
        }

        uint256 ratio = _call(provider, tokenData.ratio);
        if (tokenData.approach == Approach.BY_INCREASING_RATIO) {
            return amount * 1e18 / ratio;
        }
        if (tokenData.approach == Approach.BY_DECREASING_RATIO) {
            return amount * ratio / 1e18;
        }

        return 0;
    }

    /// @notice get value of token amount
    function toValue(address token, uint256 amount) external view returns (uint256) {
        TokenData memory tokenData = data[token];
        address provider = tokenData.provider == address(0) ? token : tokenData.provider;

        if (tokenData.approach == Approach.REDIRECT) {
            return _callWithAm(provider, tokenData.to, amount);
        }

        uint256 ratio = _call(provider, tokenData.ratio);
        if (tokenData.approach == Approach.BY_INCREASING_RATIO) {
            return amount * ratio / 1e18;
        }
        if (tokenData.approach == Approach.BY_DECREASING_RATIO) {
            return amount * 1e18 / ratio;
        }

        return 0;
    }

    function _callWithAm(address provider, string memory method, uint256 amount) internal view returns (uint256) {
        (bool success, bytes memory data) = provider.staticcall(
            abi.encodeWithSignature(method, amount)
        );

        if (!success) {
            return 0;
        }

        (uint256 res) = abi.decode(data, (uint256));

        return res;
    }

    function _call(address provider, string memory method) internal view returns (uint256) {
        (bool success, bytes memory data) = provider.staticcall(
            abi.encodeWithSignature(method)
        );

        if (!success) {
            return 0;
        }

        (uint256 res) = abi.decode(data, (uint256));

        return res;
    }

    function setToken(
        address token,
        string calldata to,
        string calldata from,
        string calldata getRatio,
        bool isIncreasing
    ) external onlyOwner {
        require(token != address(0), "RatioAdapter/0-address");

        TokenData memory tokenData;

        if (bytes(from).length > 0 && bytes(to).length > 0) {
            tokenData = TokenData("", from, to, Approach.REDIRECT, address(0));
        } else if (bytes(getRatio).length > 0) {
            Approach appr;
            if (isIncreasing) {
                appr = Approach.BY_INCREASING_RATIO;
            } else {
                appr = Approach.BY_DECREASING_RATIO;
            }
            tokenData = TokenData(getRatio, "", "", appr, address(0));
        } else {
            revert("RatioAdapter/unknown-approach");
        }

        data[token] = tokenData;
        emit TokenSet(token, uint8(tokenData.approach));
    }

    // set provider if we need to proxy calls to external contract
    function setProviderForToken(
        address token,
        address provider
    ) external onlyOwner {
        require(token != address(0), "RatioAdapter/0-address");
        require(provider != address(0), "RatioAdapter/0-address");
        data[token].provider = provider;
        emit RatioProviderSet(token, provider);
    }
}