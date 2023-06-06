// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Royalties.sol";

// @author: miinded.com

contract MekaDriversRoyalties is Royalties {
    constructor(Part[] memory _parts) Royalties(_parts){}
}