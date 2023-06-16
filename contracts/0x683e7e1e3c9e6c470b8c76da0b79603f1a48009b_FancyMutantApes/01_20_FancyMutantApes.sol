// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "./Fancy721.sol";

contract FancyMutantApes is Fancy721 {
    constructor(string memory  _URI, IERC721Enumerable _referenceContract)
    Fancy721("Fancy Mutant Apes", "FMA", _URI, _referenceContract) 
    {}
}