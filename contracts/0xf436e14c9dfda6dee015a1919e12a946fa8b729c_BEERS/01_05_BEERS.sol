// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BEERS - SIGNATURE EDITION
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//     :::====  :::===== :::===== :::====  :::===     //
//     :::  === :::      :::      :::  === :::        //
//     =======  ======   ======   =======   =====     //
//     ===  === ===      ===      === ===      ===    //
//     =======  ======== ======== ===  === ======     //
//                                                    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract BEERS is ERC721Creator {
    constructor() ERC721Creator("BEERS - SIGNATURE EDITION", "BEERS") {}
}