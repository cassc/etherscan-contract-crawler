// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library BasisPointLib {
    using SafeMath for uint256;

    uint256 constant _BPS_BASE = 10000;

    function bp(uint256 value, uint256 bpValue)
        internal
        pure
        returns (uint256)
    {
        return value.mul(bpValue).div(_BPS_BASE);
    }
}