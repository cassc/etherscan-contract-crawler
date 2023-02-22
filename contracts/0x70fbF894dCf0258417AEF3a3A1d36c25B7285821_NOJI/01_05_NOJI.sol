// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: nojiarts
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//                                                                    //
//                                                                    //
//            ::::::::::::::::::::::::::::::::::::::::::              //
//           ::     ::::                               :::            //
//          ::       ::::                      :::      :::           //
//         ::         :: :::                  :::        ::           //
//         ::         ::   :::                ::          ::          //
//        :::         ::     ::::             ::          :::         //
//        :::         ::         :::          ::          :::         //
//        :::         ::           :::        ::          :::         //
//         ::         ::             ::::     ::          ::          //
//         ::         ::                :::   ::          ::          //
//          ::       :::                  ::: ::         ::           //
//          :::     :::                      ::::       ::            //
//           ::::                             ::::     ::             //
//            ::::::::::::::::::::::::::::::::::nojiarts              //
//                                                                    //
//                                                                    //
//                                                                    //
//          nnnnn  nnnnn     oooooooo           jjjjj   iiiii         //
//         nnnnnnn nnnnn   oooooooooooo         jjjjj   iiiii         //
//         nnnnnnnnnnnnn   oooo   ooooo         jjjjj   iiiii         //
//         nnnn nnnnnnnn   oooo   ooooo  jjjjj  jjjjj   iiiii         //
//         nnnn  nnnnnnn   oooooooooooo  jjjjjjjjjjjj   iiiii         //
//         nnnn   nnnnN      oooooooO      jjjjjjjJ     iiiiI         //
//                                                                    //
//                                                                    //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract NOJI is ERC721Creator {
    constructor() ERC721Creator("nojiarts", "NOJI") {}
}