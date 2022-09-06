// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IStrings.sol";

struct SVGTemplatesContract {
    mapping(string => address) _templates;
    string[] _templateNames;
}

interface ISVG {
    function getSVG() external view returns (string memory);
}

interface ISVGTemplate {
    function svgName() external view returns (string memory _name);
    function svgString() external view returns (string memory _data);
    function svgBytes() external view returns (bytes[] memory _data);
    function clear() external;
    function add(string memory _data) external returns (uint256 _index);
    function addAll(string[] memory _data) external returns (uint256 _count);
    function buildSVG(Replacement[] memory replacements) external view returns (string memory);
}