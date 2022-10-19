//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ISVG.sol";
import "../interfaces/IStrings.sol";

import "../libraries/StringsLib.sol";
import "../libraries/SVGTemplatesLib.sol";

import "../utilities/Modifiers.sol";

/// @title SVGTemplatesFacet
/// @notice This contract is used to create and manage SVG templates
contract SVGTemplatesFacet is Modifiers {

    using SVGTemplatesLib for SVGTemplatesContract;

    // @notice an SVG templte has been created
    event SVGTemplateCreated(string name, address template);

    /// @notice set the svg manager
    /// @param _manager the address of the svg manager
    function setSVGManager(address _manager) external onlyOwner {
        SVGTemplatesLib.svgStorage().svgManager = _manager;
    }

    /// @notice get all the svgs stored in the contract
    /// @return the names of the svgs
    function svgs() external view returns (string[] memory) {
        address svgManager = SVGTemplatesLib.svgStorage().svgManager;
        return ISVGTemplate(svgManager).svgs();
    }

    /// @notice get the svg address of the given svg name. does not mean the file exists.
    /// @param _name the name of the svg
    /// @return _svgAddress the address of the svg
    function svgAddress(string memory _name) external view returns (address _svgAddress) {
        address svgManager = SVGTemplatesLib.svgStorage().svgManager;
        _svgAddress = ISVGTemplate(svgManager).svgAddress(_name);
    }

    /// @notice get the svg data of the given svg name as a string
    /// @param _name the name of the svg
    /// @return data_ the svg data as a string
    function svgString(string memory _name) external view returns (string memory data_) {
        address svgManager = SVGTemplatesLib.svgStorage().svgManager;
        data_ = ISVGTemplate(svgManager).svgString(_name);
    }
    
    /// @notice add a new svg template and return the template address to the caller
    /// @param _name the name of the svg
    /// @param _tplAddress the svg data as a string
    function createSVG(string memory _name) external onlyOwner returns(address _tplAddress) {
         address svgManager = SVGTemplatesLib.svgStorage().svgManager;
        _tplAddress = ISVGTemplate(svgManager).createSVG(msg.sender, _name);
    }

}