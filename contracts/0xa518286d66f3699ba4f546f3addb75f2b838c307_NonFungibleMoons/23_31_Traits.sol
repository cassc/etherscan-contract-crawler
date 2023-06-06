// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Utils} from "./Utils.sol";

/// @title Traits
/// @author Aspyn Palatnick (aspyn.eth, stuckinaboot.eth)
library Traits {
    function _getTrait(
        string memory traitType,
        string memory value,
        bool includeTrailingComma,
        bool includeValueQuotes
    ) internal pure returns (string memory) {
        return
            string.concat(
                '{"trait_type":"',
                traitType,
                '","value":',
                includeValueQuotes ? string.concat('"', value, '"') : value,
                "}",
                includeTrailingComma ? "," : ""
            );
    }

    function getTrait(
        string memory traitType,
        string memory value,
        bool includeTrailingComma
    ) internal pure returns (string memory) {
        return _getTrait(traitType, value, includeTrailingComma, true);
    }

    function getTrait(
        string memory traitType,
        uint256 value,
        bool includeTrailingComma
    ) internal pure returns (string memory) {
        return
            _getTrait(
                traitType,
                Utils.uint2str(value),
                includeTrailingComma,
                false
            );
    }
}