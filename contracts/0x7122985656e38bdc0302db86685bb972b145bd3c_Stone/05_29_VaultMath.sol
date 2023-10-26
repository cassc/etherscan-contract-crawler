// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

library VaultMath {
    uint256 internal constant DECIMALS = 18;

    function assetToShares(
        uint256 _assetAmount,
        uint256 _assetPerShare
    ) internal pure returns (uint256) {
        require(_assetPerShare > 1, "Vault Lib: invalid assetPerShare");
        return (_assetAmount * (10 ** DECIMALS)) / _assetPerShare;
    }

    function sharesToAsset(
        uint256 _shares,
        uint256 _assetPerShare
    ) internal pure returns (uint256) {
        require(_assetPerShare > 1, "Vault Lib: invalid assetPerShare");
        return (_shares * _assetPerShare) / (10 ** DECIMALS);
    }
}