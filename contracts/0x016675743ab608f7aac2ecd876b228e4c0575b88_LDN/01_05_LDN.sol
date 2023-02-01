// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LORD 1/1s
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//    LORD 1/1s - INSIDE YOUR MIND.                                                                                                         //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                  1997 - ETERNAL.                                                         //
//                                                                                                                                          //
//                                                                                                                                          //
//                                         I'M HERE.                                                                                        //
//                                          TO STAY...                                                                                      //
//                                                                                                                                          //
//                                                                                                                                          //
//                                          ......                                                                                          //
//                                     .';clddxxxxdoc;.                                                                                     //
//                                  .':lddddxxxxxxkkkOkdoc'                                                                                 //
//                                 ':loddxxxxkkkkkkkkxkkO0Od;.                                                                              //
//                               .,cllodxkxxkkkkkkkkkkkkxkk00d'                                                                             //
//                              .,cllodxkkkxkkkOOkkkkkkkkkxxOKk'                                                                            //
//                              'clodddxxxkkkkkkkkkkkkkxxxdxk0Kd.                                                                           //
//                             .,loooooodxkkkkkkkdlcccccccldxk0O;                                                                           //
//                             .,clcclc:coxOkkkxoc;,,,;::coxxxk0l.                                                                          //
//                             ..,,,::;;;lxkkdlc:::;;,,;cokkkxx0d.                                                                          //
//                             ..'..'''';looc;;;;;:::::clxO00OkOkc'                                                                         //
//                            ..'''''...';:,..',,;;::cldkOO0K00KXX0c                                                                        //
//                            .''.'''....';'....',,;cldkOOOOOOOKXXXx.                                                                       //
//                            .'''........''....',,,;cokkOOOkxxk0KKo.                                                                       //
//                             .'..........'....',;;:cdOOO00xdOO0Kx'                                                                        //
//                             ...........,;,...';:::o0OdooddOK0k:.                                                                         //
//                              ....... .'lol,..';::oOXklc;cxOo,.                                                                           //
//                              .........;looc'',;cx0XKdc:;lkk;                                                                             //
//                                ....,,';cllc;:c:lkOOdc:::o0k'                                                                             //
//                                 .,:c;,:looooollllcc:::::oKx.                                                                             //
//                                  .;:;;:loooddoollc:::::ckXk.                                                                             //
//                                   .,;:cloooodoolllllodxOKXO,                                                                             //
//                                    .,:clddxxkkkkkkO0KKKXXXKd.                                                                            //
//                                     'clodxkO000KKKKKKKXXXXXKOo,.                                                                         //
//                                   .':cllooxO0KKKKKKKKXXXXXXXXXKkl;,,''..                                                                 //
//                                 .';:cllllodk0KKKKKKKKKKXXXXXXXXXXXKOkdlc:,. ..........'....                                              //
//                                ':lccclllloodO0KKKKKKKKKKXXXXXXXXXXXXXKKOkxdoooodddddddoolll:.                                            //
//                        .,'...'cdxxdlclooooddxO0KKKKKKKKKKXXXXXXXXXKKKKKKK0Okkxkxxddoddddo:'..                                            //
//                       ';,'';ldxkOOkoloddodxxxkO0KKKKKKKKKKXXXXKK00O00OOOOOOOOOOOOOkxdooo:.                                               //
//              ...'''..,:;,:oxkkkOO0kdodxxxddxkkkO0000000KKKXK0OOkkkkkOO0000KK00KKKKKK0OkOko:'                                             //
//         .';:cloddoollllloxkkkkOOOOkxodxkkxddxOO0OO000000KXKOkkOO0KKKKXXXXXXKKKKXXXXXKKKKKKK0d'                                           //
//        'loc,;loooddxxxxxxxxxxxxxxxxxdddddxdddxkkkO0000OO0KKKKK00KXXXXXXXXXKKKKKXXXXXXXXKKXXXXO;                                          //
//        ';'   'codxkkkkOOOOOOOOOkkkkkkkkkkkkxkkkkkxxkkkkkkOKXXK00KXXXXXXXXXXXXKKXXXXXXXXXXXXXXXk'                                         //
//             .';:ldO0KKKXXXXXXKKKK00000KKKK0OkkkO0OkxxxxxxkO0KXKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXo.                                        //
//             .coxxO0KKKKKXXXXXXXKKK00KKKKKKKK00O000Oxxxxxxxxk0KXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXO,                                        //
//            'ok00KKKXXXXXXXXXXXXXKKKKKKKKKKKKKKKKKK0kxxxxxxxkOKKKXXXXXXXXXXXXXXXXXXXXKKXXXXXXXXXXo.                                       //
//           ,dkO0KKKXXXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKOxddxxxxxk0KKKKXXXXXXXXXXXXXXXXXXKKKKXXXXXXXXO;.';,.                                  //
//          .lxO00KKKXXXXXXXXXXXXXXXKKKKKKKKKKKKKKKKK0kxdddxxxxkO0KKKKXXXXXXXXXXXXXXXXK000KKKXXXXX0kdl:.                                    //
//          ,oxO00KKKXXXXXXXXXXXXXXXKKKKKKKKXXKKKKKKK0Okxddxxxxk0KKKKKKXXXXXXXXXXXXXKOOOO00KKXK0OOkOx,                                      //
//         .:oxO0KKKKXXXXXXXXXXXXXXXKKKKKKKXXXKKKKKKKKK0OxoddxxxO00KKKKKKXXXXXXXXXXKkodkOO0000Okk0KX0,                                      //
//         'coxO0KKKKXXXXXXXXXXXXXXXKKKKKKKKXXKKKKKKKKK0Oxoddddxxkk0KKKKKKXXXXXXXNNXd,ckOkkO00KKKXXXKc                                      //
//        .;loxO0KKKKKXXXXXXXXXXXXKKKKKKKKKKKXKKKXKKKKOkkxddddddxkO000KKKKXXXXXXXXNXk;ckkxk0KKKXXXXXXk'                                     //
//        .:loxO0KKKKXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKKKK0000kdddddxO0000KKKKXXXXXXXXXX0odkxxO00O0XXXXXXXx.                                    //
//        .cloxO0KKKKXXXXXXXXK00000KKKKKKKKKKKKKKKKKKKKKKKOxdddddkO000KKKKXXXXXXXXXX0xxxkO0Oxk0KKKKKXXKl.                                   //
//        'cloxk00KKKXXXXXXXOxxkOO00KKKKKKKKKKKKKKKKKKKKKK0xdddddxkO000KKKKXXXXXXXXKkxkO000kkOOkxxxkOOOxo:                                  //
//        'clodkO0KKKXXXXXXKxlodkOO00KKKKKKKKKKKKKKKKKKKKK0kddddddkO000KKKKKXXXXXX0xddkO0000kxxxdxkkkkOOo,                                  //
//        'loddxkO0KKKXXXXXXOocldkO000KKKKKKKKKKKKKKKKKKKKKOxdddddxkO000KKKKKXXXKOxdddxO0KKOoldxxkOOOOOOd:                                  //
//        ,dxxxxdxOKKKKKXXXXX0dcldkO00000KKKKKKKKKKKKKKKKK0kdddddddxkO00KKKKKKXKOdddddxk00K0kxxxxxxkkkkkxo                                  //
//        ,oxxxxxdxkO0KKKKXKKK0xooxkOOO0000KKKKKKKKKKKKKKK0xoodddddxkO000KKKKKKOddddddxxxOKKOdloxxxkkO0Kd.                                  //
//    ,',,:lloxkkkkkOO00KKKKKKKK0OkkkOOOO00000KKKKKKK00000OxoodddddddxkO0000K0OxdoodddddxOKKOddxkkOO0000d;                                  //
//    ...,collodddkkO0KKKKKKKKKKXXXKK0OkkOOO000000000000OOxdolodddddxxxxkOOOOOkxdoodddxxkkO0K0OxxxxkkOOkdl                                  //
//    '...;cllodddxxxkO00KKKXXXXXXXXXXKOkxkkkOOOOOOOOOkkxxxxocloooodkkOOkOOOOOkxdooodxxkkkkO0OxddkO0KKXO;                                   //
//    ..',;cclooooddkOOOOOO0KKXKXXXXXXKK0OOOOO00000OOkkxxkOkxdooodxkOO0000000OkkxdoodkkkkOO00KKKXXXXXXXk'                                   //
//    .  .,clllodddkO000KKKKKKKKKXXXXXKKKKKKKKKKKKKKK000000OOkkkOO0000KKKKK00OkkkxddxOOOOO00KKXXXXXXXXXx.                                   //
//    ;,,:cllloodddxxkOOOOOOO0KXXXXXXXXXXXXXXXXKKKKK0000OOOOOOO0000KKKKKKKKK00OOOOkkkOOO00KKKKXXXXXXXXKl                                    //
//     .',;:coooddxxkOOOOOO000KXXXXXXXXXXXXXXKKK00000OOOOOO00000KKKKKKKKKKKK000000000000KKXXXXXXXXXXXXO,                                    //
//    ... .':clodxddxkkkkOOOO0KKKKKXXKKXXXKKK000000000000000KKKKKKKKKKKKKKKK00000KKKKKKKKKXXXXXXXXXXXXo.                                    //
//     .',cooooddxxxxxkkkkkOOO0KKK0KKK000000000000000000KKKKKKKKKKKKKKKKK000000KKKKKKKKKXXXXXXK0O0KXXO,                                     //
//       .,::lodddxxkkkOOO000000000000OOO000000000000KKKKKKKKKKKKKKKKK0OOOO0KKKKKKKKKKKXXXXXK0kkkkOKXd.                                     //
//                                                                                                                                          //
//                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LDN is ERC721Creator {
    constructor() ERC721Creator("LORD 1/1s", "LDN") {}
}