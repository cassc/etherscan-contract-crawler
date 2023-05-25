// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @title BooleanPacking
 * @author @NiftyMike, NFT Culture
 * @dev Credit to Zimri Leijen
 * See https://ethereum.stackexchange.com/a/92235
 */
library BooleanPacking {
    function getBoolean(uint256 _packedBools, uint256 _columnNumber)
        internal
        pure
        returns (bool)
    {
        uint256 flag = (_packedBools >> _columnNumber) & uint256(1);
        return (flag == 1 ? true : false);
    }

    function setBoolean(
        uint256 _packedBools,
        uint256 _columnNumber,
        bool _value
    ) internal pure returns (uint256) {
        if (_value) {
            _packedBools = _packedBools | (uint256(1) << _columnNumber);
            return _packedBools;
        } else {
            _packedBools = _packedBools & ~(uint256(1) << _columnNumber);
            return _packedBools;
        }
    }
}