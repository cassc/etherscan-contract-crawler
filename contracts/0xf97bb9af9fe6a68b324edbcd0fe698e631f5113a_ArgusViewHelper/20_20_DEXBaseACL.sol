// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "EnumerableSet.sol";

import "BaseACL.sol";

/// @title DEXBaseACL - ACL template for DEX.
/// @author Cobo Safe Dev Team https://www.cobo.com/
abstract contract DEXBaseACL is BaseACL {
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant override TYPE = AuthType.DEX;

    EnumerableSet.AddressSet swapInTokenWhitelist;
    EnumerableSet.AddressSet swapOutTokenWhitelist;

    event SwapInTokenAdded(address indexed token);
    event SwapInTokenRemoved(address indexed token);
    event SwapOutTokenAdded(address indexed token);
    event SwapOutTokenRemoved(address indexed token);

    struct SwapInToken {
        address token;
        bool tokenStatus;
    }

    struct SwapOutToken {
        address token;
        bool tokenStatus;
    }

    constructor(address _owner, address _caller) BaseACL(_owner, _caller) {}

    // External set functions.

    function addSwapInTokens(address[] calldata _tokens) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            if (swapInTokenWhitelist.add(token)) {
                emit SwapInTokenAdded(token);
            }
        }
    }

    function removeSwapInTokens(address[] calldata _tokens) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            if (swapInTokenWhitelist.remove(token)) {
                emit SwapInTokenRemoved(token);
            }
        }
    }

    function addSwapOutTokens(address[] calldata _tokens) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            if (swapOutTokenWhitelist.add(token)) {
                emit SwapOutTokenAdded(token);
            }
        }
    }

    function removeSwapOutTokens(address[] calldata _tokens) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            if (swapOutTokenWhitelist.remove(token)) {
                emit SwapOutTokenRemoved(token);
            }
        }
    }

    // External view functions.
    function hasSwapInToken(address _token) public view returns (bool) {
        return swapInTokenWhitelist.contains(_token);
    }

    function getSwapInTokens() external view returns (address[] memory tokens) {
        return swapInTokenWhitelist.values();
    }

    function hasSwapOutToken(address _token) public view returns (bool) {
        return swapOutTokenWhitelist.contains(_token);
    }

    function getSwapOutTokens() external view returns (address[] memory tokens) {
        return swapOutTokenWhitelist.values();
    }

    // Internal check utility functions.

    function _swapInTokenCheck(address _token) internal view {
        require(hasSwapInToken(_token), "In token not allowed");
    }

    function _swapOutTokenCheck(address _token) internal view {
        require(hasSwapOutToken(_token), "Out token not allowed");
    }

    function _swapInOutTokenCheck(address _inToken, address _outToken) internal view {
        _swapInTokenCheck(_inToken);
        _swapOutTokenCheck(_outToken);
    }
}