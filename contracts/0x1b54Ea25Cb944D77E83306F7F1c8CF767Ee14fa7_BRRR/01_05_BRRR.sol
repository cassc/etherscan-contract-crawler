// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BLLRRR GO BRRRR
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                              .oddddddddddddddddddddddddddddd:                                                                //
//                                                              ,k00000000000000000000000000000o.                                                               //
//                                                         .colldkOkkkkkkkkkkkkkkkkkkkkkkkkOkkOxllll:.                                                          //
//                                                         .x000Okkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk0000k'                                                          //
//                                                     ,c::lkOOOkxdddddddddddddddddddddddddddddxkOOOkoccc,                                                      //
//                                                    .o000OkkkkxoooooooooooooooooooooooooooooodxkkkkO000o.                                                     //
//                                                .;;;cxOOOkxxxxdooooooooollloooooolllloooooooodxxxxxOOOOxc;;;.                                                 //
//                                                :O000Okkkxoooooooooddddc,,,cddddl;,,:odddooooooooodxkkkO0000l                                                 //
//                                               .:OOOOkxkkxooooooooodddd:'''cddddl,'';odddooooooooodxkkkkO000l.                                                //
//                                           'dxdxxxxxxdoodoooooooooodddd:'''cddddl,'';odddoooooooooooddddkkkkkdddx;                                            //
//                                           ;O000kddddoooooooooolcclllll;''':llll:,'';cllloooooooooooooodxkkkkO000c                                            //
//                                           ;O000kddddoooooooooc,'''''''''''''''''''''''',cooooooooooooooxxxxkO000c                                            //
//                                           ;kOOOkddddoooooooool:;;;,'''',,,;;;;;;;;;;;;;;clllldddddoooodxxxxkOOOOc                                            //
//                                           ,xkkkkkkkxdoooooooodxxxd;''';ooodxxxxxxxxxxxxd:''':dkxkxoooodxkkkkkkkk:                                            //
//                                           ,xkkkkkkkxdoooooooodxkkd;''':oddxkkkkkkkkkkkkx:''';dkkkxoooodxkkkkkkkk:                                            //
//                                           ,xkkkxddddooooooooodxkkd;''':oddxkkkkkkkkxxddo:''';dkkkxoooooddddxkkkk:                                            //
//                                           ,xkkkxddddooooooooodxkkd;''':oddxkkkkkkkkxdodo:''';dkkkxooooooooodkkkk:                                            //
//                                           ,xkkkxddddoooooooooodxxo;''',;;;;:::::::::;;;;ccccloddddooooooooodkkkk:                                            //
//                                           ,xkkkxddddoooooooooodddo;'''''''''''''''''''''coooodddddooooooooodkkkk:                                            //
//                                           ,kOOOxddddoooooooooodddo;''',:cccccccc:::::c::c:::coddddoooooooodxkOOk:                                            //
//                                           ;O000kddddoooooooooodddo;''';odddddddddddddddo:''';oddddoooooddddkO000:                                            //
//                                           ;O000kxdddoooooooooodddo;''';odddddddddddddddd:''';oddddoooooddddkO000:                                            //
//                                           ;O000Okxxxdoooooooodxkkd;''';oddxxxxxxxxxxxxxx:''':dxxxxdooodxxxxk0000:                                            //
//                                           ;O000Okkkxdoooooooodxkkd;''':oddxkkkkkkkkkkkkxc''':dkkkxdooodxkkkO0000:                                            //
//                                           ;O000Okkkkdoooooooolccc:,''',::::cccccccccccccccccldddddoooodkkkkO0000:                                            //
//                                           ;O000Okkkxdooooooooc,'''''''''''''''''''''''',cooooooooooooodkkkkO0000:                                            //
//                                           .lllldkOOkxdddoooool:;;;::::,''';::::;''',::::loooooooooddddxkOkOxolll'                                            //
//                                                :O000kkkkxoooooooooxkxxc'''cxxxxl,'';oxxdooooooooodxkkkk0000l                                                 //
//                                                :O000Okkkxoooooooooxkkxc'''cxxxxo,'';oxddooooooooodxkkkkO000l                                                 //
//                                                'loloxkkkkdddddooooddddl:::lddddo:::codddoooooddddxkOOOxoooo;                                                 //
//                                                    .l0OOOkkkkxoooooooooooooooooooooooooooooodxkkkkO0O0l.                                                     //
//                                                     :xxxxkkkkkddddddddddddddddddddddddoddddodkkkkkkxxxc                                                      //
//                                                      .. 'x00O0OOOOkkkkkkkkkkkkkkkkkkkxxkkkkkkO0O0k,...                                                       //
//                                                         .dOOOO0000OkkkkkkkkkkkkkkkkkkkkkkkkkkkOkOx.                                                          //
//                                                          ....:k000OOOOOOOOOOOOOOOOOOOOOOOOO0d'....                                                           //
//                                                              'xOkOOOOOOOOOOOOOOOOOOOOOOOOOO0l.                                                               //
//                                                               ...............................                                                                //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BRRR is ERC721Creator {
    constructor() ERC721Creator("BLLRRR GO BRRRR", "BRRR") {}
}