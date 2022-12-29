// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mikeleeart
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//    c''''''''''''''''''''''''''''''''''''''c    //
//    .                                      .    //
//    .                ......                .    //
//    .           ':oxkO0000Okdl;.           .    //
//    .        .ckKNNXXXXXXXXXXNN0d;.        .    //
//    '      .c0NXXXXKKKKKKKKKXXXXNXk,       '    //
//    '     .xXXXXKK0000OOOO000KKXXNNXl.     '    //
//    , ....xXXXKK00OOkkkkkkkOO00KXXNWXc.... ,    //
//    ;....lKXXKK00OkkxxxxxxxkkO0KKXNNW0;....;    //
//    :.'',xXXXK00OkkxxdddxxxkkO0KKXNNWXl'''':    //
//    l,;,;xXKK00OkkxxxxxxxxxkkO00KXXXNXo,;;,c    //
//    o::::c:;,'''..............'''',;;cc::::o    //
//    dllllc;'...                  ...,cllllld    //
//    xodddool:,'....          ....,;coododdox    //
//    Oxxxxxxxddlc;,''.......'',;:lodxxxxxxxxO    //
//    OkkkkkkkkkkkxxdoolllllloddxkkkkkkkkkkkkO    //
//    0OOOOOOOOOOOO00000000000000OOOOOOOOOOOO0    //
//    KO000000000000000000000000O00000000000OK    //
//    K00000000000000000000000000000000000000K    //
//    XKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKX    //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract MLA is ERC1155Creator {
    constructor() ERC1155Creator("Mikeleeart", "MLA") {}
}