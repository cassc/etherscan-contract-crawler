// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {EditionsV2} from "./EditionsV2.sol";

contract ZogzEditions is EditionsV2 {
    constructor() EditionsV2("ZOGZ Editions by Matt Furie", "ZOGZ") {}
}