// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Day Before Tomorrow
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//        _.-._         ..-..         _.-._           //
//       (_-.-_)       /|'.'|\       (_'.'_)          //
//        .\-/.        \)\-/(/        ,-.-.           //
//     __/ /-. \__   __/ ' ' \__   __/'-'-'\__        //
//    ( (___/___) ) ( (_/-._\_) ) ( (_/   \_) )       //
//     '.Oo___oO.'   '.Oo___oO.'   '.Oo___oO.'        //
//                                                    //
//        pablo         renee        claude           //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract TDBT is ERC1155Creator {
    constructor() ERC1155Creator("The Day Before Tomorrow", "TDBT") {}
}