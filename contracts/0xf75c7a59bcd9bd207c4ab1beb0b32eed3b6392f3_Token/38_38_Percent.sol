// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

library Percent {

    uint256 internal constant BASE_PERCENT = type(uint16).max;

    function validPercent(uint256 nb) internal pure returns (bool) {
        return nb <= BASE_PERCENT;
    }

    function validatePercent(uint256 nb) internal pure {
        require(validPercent(nb), 'Percent: INVALID');
    }

    function applyPercent(uint256 nb, uint256 _percent) internal pure returns (uint256) {
        return (nb * _percent) / BASE_PERCENT;
    }

    function inversePercent(uint256 nb, uint256 _percent) internal pure returns (uint256) {
        return percent(nb) / (BASE_PERCENT - _percent);
    }

    function percentValueOf(uint256 value, uint256 total) internal pure returns (uint256) {
        return total == 0 ? BASE_PERCENT : percent(value) / total;
    }

    function percent(uint256 value) internal pure returns (uint256) {
        return value * BASE_PERCENT;
    }
}