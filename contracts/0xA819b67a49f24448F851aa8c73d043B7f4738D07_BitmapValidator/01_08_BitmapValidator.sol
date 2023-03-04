// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {BitMaps} from "./libraries/BitMaps.sol";
import {IWrapperValidator} from "./interfaces/IWrapperValidator.sol";

contract BitmapValidator is IWrapperValidator, OwnableUpgradeable {
    event BitMapValueUpdated(address indexed asset, uint256 key, uint256 value);
    event TokenIdUpdated(address indexed asset, uint256 tokenId, bool enabled);

    struct KeyEntry {
        uint256 key;
        uint256 value;
    }
    using BitMaps for BitMaps.BitMap;
    address public override underlyingToken;
    BitMaps.BitMap private _bitmap;

    function initialize(address underlyingToken_, uint256[] memory data_) public initializer {
        __Ownable_init();

        underlyingToken = underlyingToken_;
        _bitmap.init(data_);
    }

    function initBitMapValues(uint256[] memory data_) external onlyOwner {
        require(_bitmap.getKeyCount() == 0, "BitmapValidator: already inited");

        _bitmap.init(data_);
    }

    function isValid(address collection, uint256 tokenId) external view returns (bool) {
        require(collection == address(underlyingToken), "BitmapValidator: collection mismatch");
        return _bitmap.get(tokenId);
    }

    function setBitMapValues(KeyEntry[] calldata entries) external onlyOwner {
        for (uint256 i = 0; i < entries.length; i++) {
            KeyEntry memory entry = entries[i];
            _bitmap.setValue(entry.key, entry.value);

            emit BitMapValueUpdated(underlyingToken, entry.key, entry.value);
        }
    }

    function setBitMapValue(uint256 key, uint256 value) external onlyOwner {
        _bitmap.setValue(key, value);

        emit BitMapValueUpdated(underlyingToken, key, value);
    }

    function enableTokenIds(uint256[] calldata tokenIds) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _bitmap.set(tokenIds[i]);

            emit TokenIdUpdated(underlyingToken, tokenIds[i], true);
        }
    }

    function disableTokenIds(uint256[] calldata tokenIds) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _bitmap.unset(tokenIds[i]);

            emit TokenIdUpdated(underlyingToken, tokenIds[i], false);
        }
    }

    function viewBitMapValue(uint256 key) external view returns (uint256) {
        return _bitmap.getValue(key);
    }

    function viewBitmapKeys(uint256 cursor, uint256 size) external view returns (uint256[] memory, uint256) {
        return _bitmap.viewKeys(cursor, size);
    }

    function viewBitMapKeyCount() external view returns (uint256) {
        return _bitmap.getKeyCount();
    }
}