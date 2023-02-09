// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../preclude/Preclude.sol";

abstract contract ReentrancyLayout {

    bool  internal _reentrancyOnceMark;
    uint256 internal _reentrancyOnlySelfCount;
}