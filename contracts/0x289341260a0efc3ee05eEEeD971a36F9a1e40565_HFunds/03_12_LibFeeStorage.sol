// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LibCache.sol";
import "../Storage.sol";

library LibFeeStorage {
    using LibCache for mapping(bytes32 => bytes32);

    // keccak256 hash of "furucombo.fee.rate"
    // prettier-ignore
    bytes32 public constant FEE_RATE_KEY = 0x142183525227cae0e4300fd0fc77d7f3b08ceb0fd9cb2a6c5488668fa0ea5ffa;

    // keccak256 hash of "furucombo.fee.collector"
    // prettier-ignore
    bytes32 public constant FEE_COLLECTOR_KEY = 0x60d7a7cc0a45d852bd613e4f527aaa2e4b81fff918a69a2aab88b6458751d614;

    function _setFeeRate(
        mapping(bytes32 => bytes32) storage _cache,
        uint256 _feeRate
    ) internal {
        require(_getFeeRate(_cache) == 0, "Fee rate not zero");
        _cache.setUint256(FEE_RATE_KEY, _feeRate);
    }

    function _resetFeeRate(mapping(bytes32 => bytes32) storage _cache)
        internal
    {
        _cache.setUint256(FEE_RATE_KEY, 0);
    }

    function _getFeeRate(mapping(bytes32 => bytes32) storage _cache)
        internal
        view
        returns (uint256)
    {
        return _cache.getUint256(FEE_RATE_KEY);
    }

    function _setFeeCollector(
        mapping(bytes32 => bytes32) storage _cache,
        address _collector
    ) internal {
        require(
            _getFeeCollector(_cache) == address(0),
            "Fee collector is initialized"
        );
        _cache.setAddress(FEE_COLLECTOR_KEY, _collector);
    }

    function _resetFeeCollector(mapping(bytes32 => bytes32) storage _cache)
        internal
    {
        _cache.setAddress(FEE_COLLECTOR_KEY, address(0));
    }

    function _getFeeCollector(mapping(bytes32 => bytes32) storage _cache)
        internal
        view
        returns (address)
    {
        return _cache.getAddress(FEE_COLLECTOR_KEY);
    }
}