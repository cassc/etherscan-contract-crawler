// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "../utilities/Controllable.sol";
import "../interfaces/ISVG.sol";

import "../interfaces/IStrings.sol";

import "../libraries/StringsLib.sol";
import "../libraries/SVGTemplatesLib.sol";

contract SVGManager is Controllable {

    using SVGTemplatesLib for SVGTemplatesContract;

    event SVGTemplateCreated(string name, address template);

    constructor() {
        _addController(msg.sender);
    }

    /// @notice get all the svg namea in the contract
    function svgs() external view returns (string[] memory) {
        return SVGTemplatesLib.svgStorage().svgTemplates._svgs();
    }

    /// @notice get the svg address of the given svg name. does not mean the file exists
    function svgAddress(string memory _name) external view returns (address _svgAddress) {
        _svgAddress = SVGTemplatesLib.svgStorage().svgTemplates._svgAddress(_name);
    }

    /// @notice get the svg data of the given svg name as a string
    function svgString(string memory _name) external view returns (string memory data_) {

        try SVGTemplate(SVGTemplatesLib.svgStorage().svgTemplates._svgAddress(_name)).svgString() returns (string memory _data) {
            data_ = _data;
        } catch (bytes memory) {}
    }

    /// @notice add a new gem pool
    function createSVG(address sender, string memory _name) external onlyController returns(address _tplAddress) {

        _tplAddress = SVGTemplatesLib.svgStorage().svgTemplates._createSVG(sender, _name);
        emit SVGTemplateCreated(_name, _tplAddress);
    }
}