// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../libraries/LibAppStorage.sol";

import "../interfaces/IMultiPart.sol";

abstract contract MultipartData  {

    function _addData(bytes memory _data)
        internal returns (uint256 _index)
    {
        MultiPartContract storage ds = LibAppStorage.diamondStorage().multiParts[address(this)];
        _index = ds.data_.length;
        ds.data_.push(_data);
    }

    function _getData(uint256 _index)
        internal view  returns (bytes memory data)
    {
        MultiPartContract storage ds = LibAppStorage.diamondStorage().multiParts[address(this)];
        data = ds.data_[_index];
    }

    function _fromBytes() internal view returns (string memory output) {
         MultiPartContract storage ds = LibAppStorage.diamondStorage().multiParts[address(this)];
        string memory result = "";
        for (uint256 i = 0; i < ds.data_.length; i++) {
            result = string(abi.encodePacked(result, ds.data_[i]));
        }
        output = result;
    }

    function data__() internal view returns (bytes[] storage) {
        MultiPartContract storage ds = LibAppStorage.diamondStorage().multiParts[address(this)];
        return ds.data_;
    }

    function _clear() internal {
        MultiPartContract storage ds = LibAppStorage.diamondStorage().multiParts[address(this)];
        delete ds.data_;
    }
}