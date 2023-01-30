// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Eclectic Artistry Takeover
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////
//                                                                                //
//                                                                                //
//    ............'''''''''''''',,,,,,,,,,,,'''''''''.........................    //
//    ....'''''''',,,,,,,,;;;;;;;;;;;;;;;;;;;,,,,,,,'''''''...................    //
//    ''''''',,,,,;;;;;;:::::::::::::::::::::::;;;;;;,,,,,'''''...............    //
//    ''',,,,,;;;;:::::cccccccllllllllllcccccccc:::::;;;;;,,,,'''''...........    //
//    ,,,,;;;;:::ccccccllllooooooooooooooooollllccccc::::;;;;,,,'''''.........    //
//    ;;;;::::ccclllllooooddddddddddddddddddddooollllcccc:::;;;;,,,'''........    //
//    ;:::cccclllooodddddxxxxxkkkkkkkkkkkxxxxxxdddoooolllccc:::;;;,,,'''......    //
//    ::ccclllooodddxxxxkkkkOOOOOOOOOOOOOOOOOkkkxxxdddoolllccc:::;;,,,'''.....    //
//    ccclllloodddxxkkkkOOO000000KKKKKKKKK0000OOkkkxxxddoolllcc:::;;,,,''''...    //
//    ccllloooddxxxkkOOO000KKKKK0kxdollloxkO0KK00OOOkkxxddoolllcc::;;,,,,'''..    //
//    lllooodddxxkkkOO000KKKX0xc,'.........';cx0KK00Okkxxddooollcc::;;,,,''''.    //
//    lloooddxxxkkOOO00KKKXKx,.................;xKK00OOkkxddooollcc::;;,,,''''    //
//    looodddxxkkOOO00KKKXKo.....................l0K00OOkkxxdooollcc::;;,,,'''    //
//    loodddxxkkkOO000KKKXO' ................... .dKK00OOkxxddoollcc::;;,,,'''    //
//    oooddxxxkkkOO000KKXXx.     .................oKKK0OOkkxxddoolcc::;;;,,,''    //
//    oodddxxkkkOOO000KKXXk'      ............. ..,xKK00Okkxxddoollcc::;;,,,''    //
//    oodddxxkkkOOO000KKKXKl.          .    ..     .o000Okkxxddoollcc::;;,,,''    //
//    oodddxxkkkOOO000KKKXX0l.                      .l00OOkkxddoollcc::;;,,,,'    //
//    oooddxxxkkOOO0000KKKKXKk:.                   .lk0OOkkxxddoolccc::;;,,,''    //
//    oooddxxxkkkOOO000KKKKKXXKl.                  ;O0OOkkkxxddoolcc::;;;,,,''    //
//    loodddxxxkkkOOO000KKKKKKXx.                 .o0OOOkkxxddoollcc::;;,,,,''    //
//    loooddxxxkkkOOOO00000KKKKo.                 ,x0OOkkxxddooolccc::;;,,,'''    //
//    llooodddxxxkkkOOOO0000KK0:           .:ollccxOOkkkxxdddoollcc::;;,,,,'''    //
//    lllooddddxxxkkkkOOOO0000o.         ..:k0000OOOkkxxxddooollcc::;;;,,,''''    //
//    llllooodddxxxkkkkOOOO0Oo.         .,ox0OOOOkkkkxxdddooollcc:::;;,,,,''''    //
//    clllloooddxxxxkkkkkOOd;.          ,x0OOOOkkkkxxxdddooollcc:::;;,,,,''''.    //
//    ccllllooddddxxxkkkkOd'       .... 'd0OOOkkkxxxxdddooollccc::;;;,,,'''''.    //
//    cccllloooddddxxxkkkkc...........'..ckkOkkkxxxddddooolllcc::;;;,,,,''''..    //
//    cccclloooddddxxxxxkk:............'.':okkxxxxddddooolllcc:::;;,,,,'''''..    //
//    ;:::ccclllloooddddxd;................;dddoooolllcccc:::;;;,,,'''''......    //
//    ,,,;;;;:::ccccllllol,.................:lllcccc::::;;;,,,,''''...........    //
//    '''',,,,;;;;::::cccc'.................;c::::;;;;,,,,,'''''..............    //
//    ....''''',,,,,;;;;;:'..................;;;;,,,,,'''''...................    //
//    .........''''''',,,,...................','''''''........................    //
//    .................'''...................'''............................      //
//    ..................... .. .........................................          //
//                                                                                //
//                                                                                //
////////////////////////////////////////////////////////////////////////////////////


contract EAT is ERC1155Creator {
    constructor() ERC1155Creator("Eclectic Artistry Takeover", "EAT") {}
}