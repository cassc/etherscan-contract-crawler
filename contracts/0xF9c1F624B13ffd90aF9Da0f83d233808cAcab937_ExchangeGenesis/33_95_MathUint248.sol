// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 DeGate DAO
pragma solidity ^0.7.0;


/// @title Utility Functions for uint
/// @author Daniel Wang - <[email protected]>
library MathUint248
{
    function add(
        uint248 a,
        uint248 b
        )
        internal
        pure
        returns (uint248 c)
    {
        c = a + b;
        require(c >= a, "ADD_OVERFLOW");
    }

    function sub(
        uint248 a,
        uint248 b
        )
        internal
        pure
        returns (uint248 c)
    {
        require(b <= a, "SUB_UNDERFLOW");
        return a - b;
    }
}