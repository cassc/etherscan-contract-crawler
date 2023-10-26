// SPDX-License-Identifier: MIT
// @author: NFT Studios

pragma solidity ^0.8.18;

abstract contract TimeProtected {
    function isMintOpen(
        uint256 _fromTimestamp,
        uint256 _toTimestamp
    ) internal view {
        require(
            block.timestamp >= _fromTimestamp,
            "TimeProtected: Mint is not open"
        );

        require(
            block.timestamp <= _toTimestamp,
            "TimeProtected: Mint window is closed"
        );
    }
}