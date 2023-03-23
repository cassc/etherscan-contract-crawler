// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./library/BitMask.sol";
import "./interfaces/IFlagsStorage.sol";

/**
 * @dev TokenBitMask contract is an internal smart contract for Gateway Token
 * implementation that stores KYC flags per identity token in a bitmask
 */
contract TokenBitMask {
    using BitMask for uint256;

    /**
     * @dev Emitted when token BitMask associated with `tokenId` updated to `bitmask`.
     */
    event BitMaskUpdated(uint256 tokenId, uint256 bitmask);

    /**
     * @dev Emitted when Identity.com Admin updated FlagsStorage contract address from `previousFlagsStorage` to `flagsStorage`.
     */
    event FlagsStorageUpdated(address indexed flagsStorage);

    // Gateway Token system FlagsStorage contract address
    IFlagsStorage public flagsStorage;

    // Mapping for gateway token id to bitmask
    mapping(uint256 => uint256) private bitmasks;

    /**
     * @dev Internal funciton to set FlagsStorage contract address
     * @param _flagsStorage FlagsStorage contract address
     */
    function _setFlagsStorage(address _flagsStorage) internal {
        flagsStorage = IFlagsStorage(_flagsStorage);

        emit FlagsStorageUpdated(_flagsStorage);
    }

    /**
     * @dev Internal function to get gateway token bitmask
     */
    function _getBitMask(uint256 tokenId) internal view returns (uint256) {
        return bitmasks[tokenId];
    }

    /**
     * @dev Internal function to set full bitmask for gateway token
     * @notice This function rewrites previous bitmask, use _addBitmask if you need to add flags to existing bitmask
     */
    function _setBitMask(uint256 tokenId, uint256 mask) internal {
        bitmasks[tokenId] = mask;

        emit BitMaskUpdated(tokenId, mask);
    }
}