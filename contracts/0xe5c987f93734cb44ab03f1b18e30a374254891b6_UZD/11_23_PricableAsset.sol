// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './interfaces/IAssetPriceOracle.sol';

abstract contract PricableAsset {
    uint256 private _cachedBlock;
    uint256 private _cachedAssetPrice;

    event CachedAssetPrice(uint256 blockNumber, uint256 assetPrice);

    function assetPrice() public view virtual returns (uint256);

    function assetPriceCachedParams()
        public
        view
        virtual
        returns (uint256 cachedBlock, uint256 cachedAssetPrice)
    {
        cachedBlock = _cachedBlock;
        cachedAssetPrice = _cachedAssetPrice;
    }

    function assetPriceCached() public virtual returns (uint256) {
        if (block.number != _cachedBlock) {
            _cachedBlock = block.number;
            uint256 currentAssetPrice = assetPrice();
            if (_cachedAssetPrice < currentAssetPrice) {
                _cachedAssetPrice = currentAssetPrice;
                emit CachedAssetPrice(_cachedBlock, _cachedAssetPrice);
            }
        }

        return _cachedAssetPrice;
    }

    function resetPriceCache() internal virtual {
        _cachedBlock = 0;
        _cachedAssetPrice = 0;
    }
}