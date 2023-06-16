// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Util} from "./Util.sol";

library Traits {
    /*//////////////////////////////////////////////////////////////
                                 TRAITS
    //////////////////////////////////////////////////////////////*/

    function attributes(bytes32[] memory _attributeLabels, bytes32[] memory _attributeValues) internal pure returns (string memory) {
        string memory result = "[";
        // result = string.concat(result, _attribute("Density", densityTrait(_seed, _tokenId)));
        for (uint i; i < _attributeValues.length; i++) {
            result = string.concat(result, _attribute(string(abi.encodePacked(_attributeLabels[i])), string(abi.encodePacked(_attributeValues[i]))));
        }
        return string.concat(result, "]");
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _attribute(string memory _traitType, string memory _value) internal pure returns (string memory) {
        return string.concat("{", Util.keyValue("trait_type", _traitType), ",", Util.keyValue("value", _value), "}");
    }

    // function _rarity(bytes32 _seed, string memory _salt) internal pure returns (uint256) {
    //     return uint256(keccak256(abi.encodePacked(_seed, _salt))) % 100;
    // }
}