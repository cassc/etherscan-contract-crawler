// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Joe Pease
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//                             .,;;:::::::ccccccllllllloooolc:,.                          //
//                             ,dxdddddddddddddddddddddxkOOOOOk:.                         //
//                             ,do,.....................ckOOOOOkdl:'                      //
//                             ;dl.                    .:kkOOOOOOO0o.                     //
//                             ;dl.                    .ckkkOOOOO00l.                     //
//                             ;dc.                    .ckkkOOOOOOOc                      //
//                             ;o:.                    .lkkkOOOOOOOc                      //
//                            .:o:.                    .lkkkOOOOOOO:                      //
//                            .:d:.                    .okkkOOOOOOO:                      //
//                            .:d:.                    'okkOOOOOOOO:                      //
//                            .cd:....                 'dkkOOOOOOOO:                      //
//                            .coolcccc:::;;;;;;;;,,,,,cxkkOOOOOOkx;                      //
//                     .';:cllodollcclllloooddddxxxxxxxxkkkOOkxdoddol'                    //
//                    .cxxxxxxxxxdllccccccccccccccccccccloooloodxkkkk;                    //
//                     :ddxxxxxxxxxxxxxxdllllllllollllllcllloxxkkkkkx,                    //
//                     ;ddddxxxxxxxxxxxxdoolllllodolllloooxkkkkkkkkkx'                    //
//                     ;dddddddddddxxxxxxxxxxxxxxxxxxxxxddxkkkkkkkkkd,                    //
//                     .cloodxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkkkxkkxd:.                    //
//                         ....',;:cloodxxxxxxxxxxxxxxxxxxxxkkxxdc'.      ..              //
//                  .''.....          ...'',;::cloddxxxxxxxxxxo;.                         //
//               .,cdxxxdddoolcc:;;,''....       ....',,;:c:;,',,,,,.                     //
//            ..;loddddddddxxxxxxxxxxxxdddollcc::;,,'......  .okkxkx:                     //
//         .,:looooooooooooodddddddddxxxxxxxxxxxxxxxxxxddoc. .;ccll;.                     //
//        .,:cllooodddddoooooooooooodddddddddddddxxxxxxxxd:.                              //
//            ....',;:cloodddddddddodddddddooooooooddxxd:.                                //
//                      ...',;:ccloodddddddddddoodddxxl'                                  //
//                                ...'',;:cloddddxxxd;.                                   //
//                                           ....',,.                                     //
//                                                                                        //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract PEASE is ERC721Creator {
    constructor() ERC721Creator("Joe Pease", "PEASE") {}
}