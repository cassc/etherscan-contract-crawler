// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Beeple XXV // Allowlist
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    [🏁☑️🔒🔑XXV]    //
//                     //
//                     //
/////////////////////////


contract XXVA is ERC721Creator {
    constructor() ERC721Creator("Beeple XXV // Allowlist", "XXVA") {}
}