// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Roblivion
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    .......,,,,,,,,,,,,.............,,,,,,,,,,,,.............,,,,,,,,,...,,,,,,,,,,.....,,,,,,,,,,..,,,,,,,,......,,,,,,,,..    //
//    ......,S###########SS?+:.......:#############S%*:.......:########;...+########+....,%########;.:########;....;#######%..    //
//    ......;RRRRRRRRRRRRRRRRRS:.....?BBBBBBBBBBBBBBBBBS:.....*LLLLLLLL,...;VVVVVVVV+....?VVVVVVVV+..*NNNNNNNNS....%NNNNNNN*..    //
//    ......%RRRRRRRRRRRRRRRRRRR:....#BBBBBBBBBBBBBBBBBBB,....SLLLLLLL%....:VVVVVVVV+...;VVVVVVVV*...SNNNNNNNNN:..,#NNNNNNN:..    //
//    .....,#RRRRRRR?;+SRRRRRRRR*...:BBBBBBBB*;+%BBBBBBBB;...:LLLLLLLL;....,#VVVVVVV+..,#VVVVVVV?...:NNNNNNNNNN?..;NNNNNNNS...    //
//    .....;RRRRRRRR:..,RRRRRRRR+...?BBBBBBB#...+BBBBBBBB,...*LLLLLLL#,.....SVVVVVVV+..%VVVVVVV?....*NNNNNNNNNNN,.?NNNNNNN*...    //
//    .....%RRRRRRRS...*RRRRRRR#,...#BBBBBBBS;+%BBBBBBB#;....SLLLLLLL%......%VVVVVVV+.+VVVVVVV%,....SNNNNNNNNNNN*.SNNNNNNN:...    //
//    ....,#RRRRRRR%;+SRRRRRRR#;...:BBBBBBBBBBBBBBBB#S*,....:LLLLLLLL;......*VVVVVVV+,VVVVVVVS,....:@NNNNNN#NNNN#,#NNNNNNS....    //
//    ....;RRRRRRRRRRRRRRRRRR?:....?BBBBBBBBBBBBBBB#%+,.....*LLLLLLL#,......;VVVVVVV;%VVVVVVS,.....*NNNNNNN+#NNNN+#NNNNNN*....    //
//    ....%RRRRRRRRRRRRRRR%;,......#BBBBBBBBBBBBBBBBBB#;....SLLLLLLL%.......:VVVVVVV*VVVVVV#:......SNNNNNNN:*NNNNNNNNNNNN:....    //
//    ...,#RRRRRRR*#RRRRRRS.......:BBBBBBBB;..,#BBBBBBB%...:LLLLLLLL;.......,VVVVVVVVVVVVV#:......:NNNNNNN#,:NNNNNNNNNNNS.....    //
//    ...;RRRRRRRR:*RRRRRRR?......?BBBBBBB#...;BBBBBBBB?...*LLLLLLL#,........#VVVVVVVVVVVV;.......*NNNNNNN%..%NNNNNNNNNN*.....    //
//    ...%RRRRRRRS.,@RRRRRRR;.....#BBBBBBB#*?SBBBBBBBB#,[email protected]%...%VVVVVVVVVVV;........SNNNNNNN+..+NNNNNNNNNN:.....    //
//    ..,#RRRRRRR*..%RRRRRRR#,...:BBBBBBBBBBBBBBBBBBBB:...:LLLLLLLLLLLLLL?...?VVVVVVVVVV+........:NNNNNNNN,..,#NNNNNNNNS......    //
//    ..+RRRRRRRR:..;RRRRRRRR%...?BBBBBBBBBBBBBBBBB%;.....?LLLLLLLLLLLLLL;...+VVVVVVVVV*.........*NNNNNNN%....*NNNNNNNN*......    //
//    ..+%%%%%%%?....?%%%%%%%%:..?%%%%%%%%%%%%??+;,.......*%%%%%%%%%%%%%?,...:%%%%%%%%*..........*%%%%%%%;....:%%%%%%%%:......    //
//    ........................................................................................................................    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract RBLVN is ERC1155Creator {
    constructor() ERC1155Creator("Roblivion", "RBLVN") {}
}