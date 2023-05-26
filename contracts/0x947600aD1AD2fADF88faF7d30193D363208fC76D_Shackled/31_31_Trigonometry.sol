// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/Trigonometry.sol";

contract XTrigonometry {
    constructor() {}

    function xsin(uint256 _angle) external pure returns (int256) {
        return Trigonometry.sin(_angle);
    }

    function xcos(uint256 _angle) external pure returns (int256) {
        return Trigonometry.cos(_angle);
    }
}