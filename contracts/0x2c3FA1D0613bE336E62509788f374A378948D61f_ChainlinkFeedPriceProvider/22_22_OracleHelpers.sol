// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

library OracleHelpers {
    function scaleDecimal(
        uint256 amount,
        uint256 _fromDecimal,
        uint256 _toDecimal
    ) internal pure returns (uint256) {
        if (_fromDecimal > _toDecimal) {
            return amount / (10**(_fromDecimal - _toDecimal));
        } else if (_fromDecimal < _toDecimal) {
            return amount * (10**(_toDecimal - _fromDecimal));
        }
        return amount;
    }
}