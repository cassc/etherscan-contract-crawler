// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../libraries/SVGTemplatesLib.sol";

import "../interfaces/IMultiPart.sol";

abstract contract MultipartData  {
    /// @notice add a new multipart to the contract
    /// @param _data the data of the multipart
    function _addData(bytes memory _data)
        internal returns (uint256 _index) {
        _index = SVGTemplatesLib.svgStorage().multiPart.data_.length;
        SVGTemplatesLib.svgStorage().multiPart.data_.push(_data);
    }

    /// @notice get the data of the given index
    /// @param _index the index of the data
    function _getData(uint256 _index)
        internal view  returns (bytes memory data) {
        data = SVGTemplatesLib.svgStorage().multiPart.data_[_index];
    }

    /// @notice get the data as a string
    function _fromBytes() internal view returns (string memory output) {
        string memory result = "";
        for (uint256 i = 0; i < SVGTemplatesLib.svgStorage().multiPart.data_.length; i++) {
            result = string(abi.encodePacked(result, SVGTemplatesLib.svgStorage().multiPart.data_[i]));
        }
        output = result;
    }

    /// @notice get the data as a  bytes array
    function data__() internal view returns (bytes[] storage) {
        return SVGTemplatesLib.svgStorage().multiPart.data_;
    }

    /// @notice clear the contents of the data array
    function _clear() internal {
        delete SVGTemplatesLib.svgStorage().multiPart.data_;
    }
}