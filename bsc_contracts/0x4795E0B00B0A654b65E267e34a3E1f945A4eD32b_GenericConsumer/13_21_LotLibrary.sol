// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Entry, EntryLibrary } from "./EntryLibrary.sol";

library LotLibrary {
    using EntryLibrary for EntryLibrary.Map;

    error LotLibrary__LotIsNotInserted(uint256 lot);
    error LotLibrary__LotIsNotEmpty(uint256 lot);

    struct Map {
        uint256[] lots;
        mapping(uint256 => EntryLibrary.Map) lotToEntryMap;
        mapping(uint256 => uint256) indexOf;
        mapping(uint256 => bool) inserted;
    }

    function getLot(Map storage _self, uint256 _lot) internal view returns (EntryLibrary.Map storage) {
        return _self.lotToEntryMap[_lot];
    }

    function isInserted(Map storage _self, uint256 _lot) internal view returns (bool) {
        return _self.inserted[_lot];
    }

    function size(Map storage _self) internal view returns (uint256) {
        return _self.lots.length;
    }

    function remove(Map storage _self, uint256 _lot) internal {
        if (!_self.inserted[_lot]) {
            revert LotLibrary__LotIsNotInserted(_lot);
        }

        if (_self.lotToEntryMap[_lot].size() != 0) {
            revert LotLibrary__LotIsNotEmpty(_lot);
        }
        delete _self.inserted[_lot];

        uint256 index = _self.indexOf[_lot];
        uint256 lastIndex = _self.lots.length - 1;
        uint256 lastKey = _self.lots[lastIndex];

        _self.indexOf[lastKey] = index;
        delete _self.indexOf[_lot];

        _self.lots[index] = lastKey;
        _self.lots.pop();
    }

    function set(Map storage _self, uint256 _lot) internal {
        if (!_self.inserted[_lot]) {
            _self.inserted[_lot] = true;
            _self.indexOf[_lot] = _self.lots.length;
            _self.lots.push(_lot);
        }
    }
}