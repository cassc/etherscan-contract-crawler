//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utilities/MultipartData.sol";

import "../libraries/StringsLib.sol";
import "../libraries/SVGTemplatesLib.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/// @notice a single SVG image
contract SVGTemplate is MultipartData, Ownable, Initializable {

    event SVGImageAdded(address indexed _from, address indexed _to, string _name, string _data);
    event SVGImagePartAdded(address indexed _from, address indexed _to, string _name, string _data);

    function initialize(string memory _name, string[] memory _svg) external initializer {
        MultiPartContract storage ds = SVGTemplatesLib.svgStorage().multiPart;
        ds.name_ = _name;
        for(uint i = 0; i < _svg.length; i++) {
            ds.data_.push(bytes(_svg[i]));
        }
    }

    /// @notice the name of the svg
    function svgName() external view returns (string memory _name) {
        MultiPartContract storage ds = SVGTemplatesLib.svgStorage().multiPart;
        _name = ds.name_;
    }

    /// @notice the data of the svg
    function svgString() external view returns (string memory _data) {
        _data = _fromBytes();
    }

    /// @notice the data of the svg
    function svgBytes() external view returns (bytes[] memory _data) {
        _data = data__();
    }
    
    /// @notice clear the data of the svg
    function clear() external onlyOwner {
        _clear();
    }

    /// @notice add data to the end of the data
    function add(string memory _data) external onlyOwner returns (uint256 _index) {
        _index = _addData(bytes(_data));
        emit SVGImagePartAdded(msg.sender, address(this), SVGTemplatesLib.svgStorage().multiPart.name_, _data);
    }

    /// @notice add all SVG lines at
    function addAll(string[] memory _data) external onlyOwner returns (uint256 _count) {
        for(uint256 i = 0; i < _data.length; i++) {
            _addData(bytes(_data[i]));
        }
        _count = _data.length;
        MultiPartContract storage ds = SVGTemplatesLib.svgStorage().multiPart;
        emit SVGImageAdded(msg.sender, address(this), ds.name_, _fromBytes());
    }

    /// @notice get the svg, replacing the data with the data from the given replacements
    function buildSVG(Replacement[] memory replacements) external view returns (string memory) {
        return StringsLib.replace(data__(), replacements);
    }
}