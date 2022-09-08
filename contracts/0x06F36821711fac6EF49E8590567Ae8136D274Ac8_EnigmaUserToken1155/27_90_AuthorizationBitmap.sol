// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;

/**
 * @dev This implementation is similar to the OZ one but due to the fact we are using an old version
 *			we weren't able to import it.
 */
library AuthorizationBitmap {
    struct Bitmap {
        mapping(uint256 => uint256) map_;
    }

    function isAuthProcessed(Bitmap storage bitmap, uint256 index) internal view returns (bool) {
        return isAuthProcessed(bitmap.map_, index);
    }

    function setAuthProcessed(Bitmap storage bitmap, uint256 index) internal {
        setAuthProcessed(bitmap.map_, index);
    }

    /**
     * @notice Verifies if this authorization index has already been processed
     * @param _index of the Authorization signature you want to know it's been processed
     */
    function isAuthProcessed(mapping(uint256 => uint256) storage _map, uint256 _index) internal view returns (bool) {
        uint256 wordIndex = _index / 256;
        uint256 bitIndex = _index % 256;
        uint256 processedWord = _map[wordIndex];
        uint256 mask = (1 << bitIndex);
        return processedWord & mask == mask;
    }

    /**
     * @notice Sets this authorization index as processed
     * @param _index of the Authorization signature you want to mark as processed
     */
    function setAuthProcessed(mapping(uint256 => uint256) storage _map, uint256 _index) internal {
        uint256 wordIndex = _index / 256;
        uint256 bitIndex = _index % 256;
        _map[wordIndex] = _map[wordIndex] | (1 << bitIndex);
    }
}