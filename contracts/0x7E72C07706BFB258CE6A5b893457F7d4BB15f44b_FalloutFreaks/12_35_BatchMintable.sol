// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract BatchMintable
{
    uint256 public maxBatchMint;

    error MaxBatchMintLimitExceeded(uint256 limit);

    modifier checkMaxBatchMint(uint8 _quantity) {
        if (_quantity > maxBatchMint)
            revert MaxBatchMintLimitExceeded(maxBatchMint);
        _;
    }
    
    function _setMaxBatchMint(uint256 _maxBatchMint) internal {
        maxBatchMint = _maxBatchMint;
    }
}