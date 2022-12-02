// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: INSPIRATION
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//      ##      ## ##     ##       ####   ###  ##      //
//       ##    ##   ##     ##       ##      ## ##      //
//     ## ##   ##        ## ##      ##     # ## #      //
//     ##  ##  ##  ###   ##  ##     ##     ## ##       //
//     ## ###  ##   ##   ## ###     ##     ##  ##      //
//     ##  ##  ##   ##   ##  ##     ##     ##  ##      //
//    ###  ##   ## ##   ###  ##    ####   ###  ##      //
//                                                     //
//                                                     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract INSP is ERC721Creator {
    constructor() ERC721Creator("INSPIRATION", "INSP") {}
}