// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: T3 Experimental
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//    #### ##   ## ##   ### ###  ##  ##   ### ##       //
//    # ## ##  ##   ##   ##  ##  ### ##    ##  ##      //
//      ##          ##   ##       ###      ##  ##      //
//      ##        ###    ## ##     ###     ##  ##      //
//      ##          ##   ##         ###    ## ##       //
//      ##     ##   ##   ##  ##  ##  ###   ##          //
//     ####     ## ##   ### ###  ##   ##  ####         //
//                                                     //
//                                                     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract T3EXP is ERC721Creator {
    constructor() ERC721Creator("T3 Experimental", "T3EXP") {}
}