// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./WERC20.sol";

contract HAVAHToken is WERC20 {

    constructor() WERC20(4, "cx0000000000000000000000000000000000000000", "HAVAH", "HVH", 18) {

    }

}