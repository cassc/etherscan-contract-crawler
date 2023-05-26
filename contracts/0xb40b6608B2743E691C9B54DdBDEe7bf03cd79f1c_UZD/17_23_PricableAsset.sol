// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './interfaces/IAssetPriceOracle.sol';

abstract contract PricableAsset {
    uint256 private _blockCached;
    uint256 private _assetPriceCached;

    event CachedAssetPrice(uint256 blockNumber, uint256 assetPrice);

    function assetPriceCacheDuration() public view virtual returns (uint256);

    function assetPrice() public view virtual returns (uint256);

    function assetPriceCached() public view virtual returns (uint256) {
        return _assetPriceCached;
    }

    function blockCached() public view virtual returns (uint256) {
        return _blockCached;
    }

    /**
     * @dev Being the main rebasing mechanism, this function allows anyone
     to sync cached priced with the oracle by minting needed supply.
     An arbitrary user can arbitrage by sandwiched trade-rebase-trade operations.
     Any contracts wanting to support UZD tokens should take into account this possibility
     of potentially non-synced price.
     */
    function cacheAssetPrice() public virtual {
        _blockCached = block.number;
        uint256 currentAssetPrice = assetPrice();
        if (_assetPriceCached < currentAssetPrice) {
            _assetPriceCached = currentAssetPrice;
            emit CachedAssetPrice(_blockCached, _assetPriceCached);
        }
    }

    function _cacheAssetPriceByBlock() internal virtual {
        if (block.number >= _blockCached + assetPriceCacheDuration()) {
            cacheAssetPrice();
        }
    }

    function _resetPriceCache() internal virtual {
        _blockCached = 0;
        _assetPriceCached = 0;
    }
}