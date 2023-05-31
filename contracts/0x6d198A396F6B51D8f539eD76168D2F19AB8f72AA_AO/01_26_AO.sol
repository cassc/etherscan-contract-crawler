// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AFTERORDER
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////
//                                                                                       //
//                                                                                       //
//    MMMMMMMMMMMMMMMMMMMMMMMMWXOxoc;'...          ...';coxOXWMMMMMMMMMMMMMMMMMMMMMMMM   //
//    MMMMMMMMMMMMMMMMMMMMN0xc,.                            .cKMMMMMMMMMMMMMMMMMMMMMMM   //
//    MMMMMMMMMMMMMMMMWXkl,.                                .oNMMMMMMMMMMMMMMMMMMMMMMM   //
//    MMMMMMMMMMMMMMNkc.                                   .oNMMMMMMMMMMMMMMMMMMMMMMMM   //
//    MMMMMMMMMWMMKd,                                      lNMMMMMMMMMMMMMMMMMMMMMMMMM   //
//    MMMMMMMMMWKl.                                       cXMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//    MMMMMMMMXd.                                        :XMMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//    MMMMMMWk,                                         :XMMMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//    MMMMMXl.                                         ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//    MMMMK;                                          ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//    MMM0,                                          ,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//    MMK,                                          ,0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//    MX:                                          'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//    Wo                      'clllllc.  'lllllllll0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//    O.                     :KMMMMMMWk. 'OMMMMMMMMMWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMM   //
//    l                     ;KMMMNNWMMWk. ,0MMMMMMMMKc''''''''',xWMMMMMMMMMMMMMMMMMMMM   //
//    '                    ,0MMMWd,kWMMWx. ,0MMMMMWNWx.         .xWMMMMMMMMMMMMMMMMMMM   //
//    .                   '0MMMWd. 'OWMMWd. ;KMMMNllXWd.....     .xWMMMMMMMMMMMMMMMMMM   //
//                       'OMMMWx.   ,0MMMWd..kMMNl  cXWK0K00O:    .kWMMMMMMMMMMMMMMMMM   //
//                      .OWMMWx.     ;KMMMNxdNMWo    lNMMMMMMK:    .OWMMMMMMMMMMMMMMMM   //
//                     .kWMMWk.       ;KMMMWWMMWd.    lNMMMMMMK;    'OMMMMMMMMMMMMMMMM   //
//                    .xWMMWO. .......'dNMMMNKKNNo.   .oNMMMMMMK,    ,0MMMMMMMMMMMMMMM   //
//    .              .xWMMWO' 'kXXNXXXXNWMMWd..lNNo    .dWMMMMMM0,    ,KMMMMMMMMMMMMMM   //
//    ;             .dWMMM0, .kWWMMMMMMMMMWx.  .oNNl    .:ooooooo;     ;KMMMMMMMMMMMMM   //
//    d.            ,xkkkx,  :xkkkkkkkOXMWx.    .dWXc                   :XMMMMMMMMMMMM   //
//    X;                              ;KWk.      .xWX:                   :XMMMMMMMMMMM   //
//    Mk.                            ,0WWkooooooookNMXxoooooooooooooooooodKMMMMMMMMMMM   //
//    MWd.                          '0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//    MMNo.                        'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//    MMMNo.                      .kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//    MMMMWx.                    .kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//    MMMMMW0;                  .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//    MMMMMMMNd.               .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//    MMMMMMMMMKl.            .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//    MMMMMMMMMMWKl.         .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//    MMMMMMMMMMMMMXd,       lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//    MMMMMMMMMMMMMMMNOo,.  lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//    MMMMMMMMMMMMMMMMMMW0dxXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//                                                                                       //
//                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////


contract AO is ERC721Creator {
    constructor() ERC721Creator("AFTERORDER", "AO") {}
}