// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AliGapo
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    /\ |_ | (_, /\ |^ ()    //
//                            //
//                            //
////////////////////////////////


contract GAPO is ERC721Creator {
    constructor() ERC721Creator("AliGapo", "GAPO") {}
}