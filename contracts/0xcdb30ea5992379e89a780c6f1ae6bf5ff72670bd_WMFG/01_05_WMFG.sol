// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WhereMyFeetGo
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//                                                  //
//                    __  __    _____    ____       //
//     __        __ U|' \/ '|u |" ___|U /"___|u     //
//     \"\      /"/ \| |\/| |/U| |_  u\| |  _ /     //
//     /\ \ /\ / /\  | |  | | \|  _|/  | |_| |      //
//    U  \ V  V /  U |_|  |_|  |_|      \____|      //
//    .-,_\ /\ /_,-.<<,-,,-.   )(\\,-   _)(|_       //
//     \_)-'  '-(_/  (./  \.) (__)(_/  (__)__)      //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract WMFG is ERC721Creator {
    constructor() ERC721Creator("WhereMyFeetGo", "WMFG") {}
}