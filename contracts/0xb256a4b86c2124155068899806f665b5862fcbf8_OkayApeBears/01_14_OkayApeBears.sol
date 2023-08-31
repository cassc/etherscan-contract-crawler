// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721MACH1.sol";

contract OkayApeBears is ERC721MACH1 {
    constructor()
        ERC721MACH1("OkayApeBears", "OABEARS", 2000, 7950, 50, 0.019 ether, 20)
    {}
}