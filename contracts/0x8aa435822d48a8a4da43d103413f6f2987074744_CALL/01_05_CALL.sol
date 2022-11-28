// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Calling Out
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//     ## ##     ##     ####     ####         //
//    ##   ##     ##     ##       ##          //
//    ##        ## ##    ##       ##          //
//    ##        ##  ##   ##       ##          //
//    ##        ## ###   ##       ##          //
//    ##   ##   ##  ##   ##  ##   ##  ##      //
//     ## ##   ###  ##  ### ###  ### ###      //
//                                            //
//                                            //
////////////////////////////////////////////////


contract CALL is ERC721Creator {
    constructor() ERC721Creator("Calling Out", "CALL") {}
}