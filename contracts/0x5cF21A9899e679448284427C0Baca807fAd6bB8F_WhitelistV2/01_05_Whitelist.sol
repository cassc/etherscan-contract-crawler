// SPDX-License-Identifier: UNLICENSED
// Copyright (c) Eywa.Fi, 2021-2023 - all rights reserved
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/IWhitelist.sol";


contract WhitelistV2 is IWhitelist, Ownable {

    /// @dev fee denominator
    uint256 public constant FEE_DENOMINATOR = 10000;

    /// @dev array of token indices
    mapping(address => uint256) private _tokenIds;
    /// @dev tokens
    IWhitelist.TokenStatus[] private _tokens;
    /// @dev array of pool indices
    mapping(address => uint256) private _poolIds;
    /// @dev pools
    IWhitelist.PoolStatus[] private _pools;

    event TokenSet(address token, uint256 max, uint256 min, uint256 fee, IWhitelist.TokenState state);
    event PoolSet(address pool, uint256 fee, IWhitelist.PoolState state);

    function tokenMin(address token_) external view returns (uint256) {
        return _getToken(token_).min;
    }
    
    function tokenMax(address token_) external view returns (uint256) {
        return _getToken(token_).max;
    }

    function tokenMinMax(address token_) external view returns (uint256, uint256) {
        IWhitelist.TokenStatus memory token = _getToken(token_);
        return (token.min, token.max);
    }

    function bridgeFee(address token_) external view returns (uint256) {
        return _getToken(token_).bridgeFee;
    }

    function tokenState(address token_) external view returns (uint8) {
        return uint8(_getToken(token_).state);
    }

    function tokenStatus(address token_) external view returns (IWhitelist.TokenStatus memory) {
        return _getToken(token_);
    }

    function aggregationFee(address pool_) external view returns (uint256) {
        return _getPool(pool_).aggregationFee;
    }

    function poolState(address pool_) external view returns (uint8){
        return uint8(_getPool(pool_).state);
    }

    function poolStatus(address pool_) external view returns (IWhitelist.PoolStatus memory) {
        return _getPool(pool_);
    }

    function tokens(uint256 offset, uint256 count) external view returns (IWhitelist.TokenStatus[] memory) {
        require(offset <= _tokens.length, "Whitelist: wrong offset");
        count = Math.min(_tokens.length, count + offset);
        IWhitelist.TokenStatus[] memory tokens_ = new IWhitelist.TokenStatus[](count - offset);
        for (uint256 i = offset; i < count; ++i) {
            tokens_[i] = _tokens[i];
        }
        return tokens_;
    }

    function pools(uint256 offset, uint256 count) external view returns (IWhitelist.PoolStatus[] memory) {
        require(offset <= _pools.length, "Whitelist: wrong offset");
        count = Math.min(_pools.length, count + offset);
        IWhitelist.PoolStatus[] memory pools_ = new IWhitelist.PoolStatus[](count - offset);
        for (uint256 i = offset; i < count; ++i) {
            pools_[i] = _pools[i];
        }
        return pools_;
    }

    function setTokens(IWhitelist.TokenStatus[] memory tokens_) external onlyOwner {
        uint256 count = tokens_.length;
        for (uint256 i; i < count; ++i) {
            IWhitelist.TokenStatus memory status = tokens_[i];
            require(status.token != address(0), "Whitelist: zero address");
            require(status.max >= status.min, "Whitelist: min max wrong");
            require(status.bridgeFee <= FEE_DENOMINATOR, "Whitelist: fee > 100%");
            uint256 id = _tokenIds[status.token];
            if (id == 0) {
                _tokens.push(status);
                _tokenIds[status.token] = _tokens.length;
            } else {
                --id;
                _tokens[id] = status;
            }
            emit TokenSet(status.token, status.max, status.min, status.bridgeFee, status.state);
        }
    }

    function setPools(IWhitelist.PoolStatus[] memory pools_) external onlyOwner {
        uint256 count = pools_.length;
        for (uint256 i; i < count; ++i) {
            IWhitelist.PoolStatus memory status = pools_[i];
            require(status.pool != address(0), "Whitelist: zero address");
            require(status.aggregationFee <= FEE_DENOMINATOR, "Whitelist: fee > 100%");
            uint256 id = _poolIds[status.pool];
            if (id == 0) {
                _pools.push(status);
                _poolIds[status.pool] = _pools.length;
            } else {
                --id;
                _pools[id] = status;
            }
            emit PoolSet(status.pool, status.aggregationFee, status.state);
        }
    }

    function _getToken(address token) private view returns (IWhitelist.TokenStatus memory) {
        uint256 id = _tokenIds[token];
        require(id != 0, "Whitelist: token not set");
        --id;
        return _tokens[id];
    }

    function _getPool(address pool) private view returns (IWhitelist.PoolStatus memory) {
        uint256 id = _poolIds[pool];
        require(id != 0, "Whitelist: pool not set");
        --id;
        return _pools[id];
    }

}