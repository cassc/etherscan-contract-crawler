// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: axies.io Lifetime Membership Pass
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//                                                                    //
//                                                                    //
//                   .,;.                      ';,.                   //
//                  .okOx;                    :xOkl.                  //
//                  .:xkOd'                  ,xOkx;                   //
//                    .cxkl.      ....      .okxc.                    //
//                      .;,..';cloddddolc;'..,;.                      //
//                       .,lxkkOOkOkkkkOOOkxl,.                       //
//            .;;'     .;dkOOkOOOkOOkkOkkkkkkkd;.     ';;.            //
//            ,xkkc.  .lkkkkOOkOOOkkkkkOkkkOkkOkl.  .ckOx,            //
//             .;:;. 'dkkkkOkkkOOOkkOOOOkkkkkkOkkd' .;:;.             //
//           .,'.   .okkkkOxc'cxOkkkkOOOx:'ckkkOOko.  .,;:,.          //
//          :xkkxl. ;kOOkkOd' 'dkkkOOOkko. ,xOOkkkk: .okkOk:          //
//          'colc,..cOOkkkOx;.,xo,,;;,,od,.;xOOkkkkc. .;cc;.          //
//            ..'...ckOkkOkkxdxkd,    ,dkxdxkOOkkOkc.....             //
//           .:xkx, ,xOkkkOOkkOkkxlcclxkkkkkOOkkkOx, ,dkxc.           //
//           .:oc'   ;dkOkkkOOOkOOOOOkkkkOkOkkOkkx;   'co:.           //
//                    .cdkkOkkOOkkkOOOOkkOOOOOkd:.                    //
//                      .':codxkkkkkkkkkkxdoc;'.                      //
//                           ....''''''....                           //
//                                                                    //
//                                                                    //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract AXIESIO is ERC721Creator {
    constructor() ERC721Creator("axies.io Lifetime Membership Pass", "AXIESIO") {}
}