//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Create2.sol";

import "../interfaces/ISVG.sol";
import "../interfaces/IStrings.sol";

import "../libraries/LibAppStorage.sol";
import "../libraries/StringsLib.sol";

import "../utilities/SVGTemplate.sol";

library SVGTemplatesLib {

    event SVGTemplateCreated(string name, address template);

    /// @notice get the stored template names in the contract
    function _svgs(SVGTemplatesContract storage self)
        internal
        view
        returns (string[] memory) { return self._templateNames; }

    /// @notice get the create2 address of the given name
    function _svgAddress(
        SVGTemplatesContract storage,
        string memory _name) 
        internal 
        view returns (address) {
        return Create2.computeAddress(
            keccak256(abi.encodePacked(address(this), _name)), 
            keccak256(type(SVGTemplate).creationCode)
        );  
    }

    /// @notice the svg string or an empty string
    function _svgString(
        SVGTemplatesContract storage self,
        string memory _name
    ) internal view returns (string memory data_) {
        try SVGTemplate(_svgAddress(self, _name)).svgString() returns (string memory _data) {
            data_ = _data;
        } catch (bytes memory) {}
    }

    /// @notice the sstored address for the name storage. empty is no svg
    function _svgData(
        SVGTemplatesContract storage self,
        string memory _name
    ) internal view returns (address) {
        return self._templates[_name];
    }

    /// @notice create a new SVG image with the given name
    function _createSVG(SVGTemplatesContract storage self, string memory _name)
        internal
        returns (address _tplAddress)
    {
        // make sure the name is unique
        require(
            self._templates[_name] == address(0),
            "template already deployed"
        );

        // get the address for the given name, create using create2,
        // then verify that create2 returned the expected address
        address targetTplAddress = _svgAddress(self, _name);
        _tplAddress = Create2.deploy(
            0,
            keccak256(abi.encodePacked(address(this), _name)),
            type(SVGTemplate).creationCode
        );
        require(targetTplAddress == _tplAddress, "template address mismatch");

        // transfer ownership to the creator and update storage
        Ownable(_tplAddress).transferOwnership(msg.sender);
        self._templateNames.push(_name);
        self._templates[_name] = _tplAddress;
    }
}