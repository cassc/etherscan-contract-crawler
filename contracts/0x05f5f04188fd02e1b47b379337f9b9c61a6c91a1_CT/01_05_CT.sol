// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CompliedTrader
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                       .,.               ..                                                                     //
//                                                                                                                                //
//                                                                                                                                //
//                                   ..                                                                                           //
//                                 .:c,                                                                                           //
//                           ..  .'clc.                                                                                           //
//                           .  .,cll,                                                                                            //
//                            ..,:c:;.                                                                                            //
//                           .';cccc;.                                                                                            //
//                         ..,,:lolc'                                                                                 ..          //
//                        .',,:lool;.                                                                                .;:.         //
//                        .'',:lllc.                                                                                  ':;.        //
//                       .',,,:llll;.              .':ll,                                                             .;c;.       //
//                       .,,,,;cllll;...          'oxdONO,      .....                                                  ,lc'       //
//                        .,,,,;cllc;:cc::;;,'...,dx,.cXXl    .,clllc:;'...                                           .;lc,.      //
//                        .',,,,;:::cllllllllllc:coc;ckNNo....':cc:clooollc;'.                                        .:c:;.      //
//                         .',,'',,;:llllllllllc:cllxKNWKdccclllllc::loooooool;'.      .......                       .;cc:;.      //
//                           .',,,,,',;:::::cccc:lx0XWWXxcllllloolc:,cooooooooolc,'''';clooooc,.....               .'cllc:;.      //
//                            .',,,,,',,,,,,;;:cd0XNNNKx;,;;;::cc::;,colllccccccccloooooooooooc:ccc::;,,;:;;;'.',,;:cccc::;.      //
//                             ..',;::clooddxk0KXXXK0xl;'',,;::::::;:cllllllccccllllooooooolllc:::::clccloooolccllllolc;;;'.      //
//                         .';clllodddxkOO0000Okxoc;'....',;clllccccccclllllccccclllllllllllllcc::;::::::lllllccllllcc:;,'.       //
//                     .,loolc:,....................',;:cllllllooollcc:cloxxkxo:,;;;::c:cccllllcc::ccc:::c:;;::;;:;;;,,,,'        //
//                    .;l:..                 ..,;:cllllc::;:::clllccc:,;:d0KKKOo;,;;:::cclcllll::coddolc:;'.',,'',,,,,,,'.        //
//                                         .,clolc::;;:cclddccclcc::;,,,,o0000Oo;;;:ccclllllllc;;;ckOOko:,.   ...'',,,,..         //
//                                       .;loolllllodxkkO0Kkclollllc:,,;cdkOOko;,;:ccclccccllloolldkkxl:,..         ..            //
//                                    .':loolldkO000OOO0KKklcloollllc::;;:lolc;,,;:cccclooddxkO0000Oxo:;,'.                       //
//                                  .,clooolox0K00000K0Oxoclloooolccccc::cllc:::cllloddddxkOOOOOkkO0OOkxdoc,.                     //
//                               .':looooooloxOOOOkxxxolllooooolcccloollllllllooooodkOkdoccdOKKK0OkxxxkO0KK0x;                    //
//                             .,clooooooooolllllllllllooooollcclloooolooooooooooox0K00k:   ,d0KKK00OOO0K0x:'.                    //
//                            .:looooooooooooooooooolllooolllcloooooooooooooooolld0K0K0d;    .,cdO0KKK0Ox:.   .                   //
//                          .,:loooooooooooooloooooolllooolllooooooooooooooooooloOKKKK0kl,.    .;xO00OOo'   .:l,                  //
//                        ..;clooooooooooooolcloooooolcloooooooooooooooooooooolcd0KKKKK0kdc,'';lxO00000kocclookd.                 //
//                       .,:clooooooooooooool:coooooolc:looooooooooooooooooooollxKKKKK000OxdddxkkO00KKKK00000000l.                //
//                      .,:lloooooooooooooool:coooooool:;clloooooooollc::::::cc:d000KK00O00000OOkkkkkkkOOOOOOO0Kk'                //
//    .               .';cloooooooooooooooool;;loooooool:;;;:::::;;;;,,;;:ccccc;ck00000kdoldkkkkkOO0000000OOxc;:c'                //
//    ooc'.          .,;clooooooooooooooooool:;coooooooollc:::;:::::cclllooooool::dOOx:,,;lkOOkkxdolccclodxkko'                   //
//    0Okxl'       ..,:coooooooooooooooooooool;;loooooooooolllllooooooooooooooool::clc:clllc,....          ....                   //
//    x0KOkd;.    .,;:cloooooooooooooooodxO000koooooooooooooooooooooooooooooooooollc::::::;.                                      //
//    .,o0KK0l. .',;:lloooooooooooooooooodkOO0KKKK0kdoooooooooooooooooooooooooooooooooool:.                                       //
//      .;xXWKc.,;;:loooooooooooooooooooooooooodxOKXX0Oxoooooooooooooooooooooooooooooool;.                                        //
//        .cOx:;;:clooooooooooooooooooooooooooooooodk0KX0kdooooooooooooooooooooooooool:.                                          //
//         .';;:lloooooooooooooooooooooooooooooooooooooxOKK0xooooooooooooooooooooool:'.                                           //
//    '    .':loooooooooooooooooooooooooooooooooooooooc::lkKXKkdoooooooooooooooolc,.  ..  ....                                    //
//    k;.  ':loooooooooooooooooooooooooooooooooooooooollc:cokKNX0xddooooooollc::;,,,:ccldxxxxdoc,.                                //
//    NKo,';loooooooooooooooooooooooooooooooooooooooooolllccldOXWNXKkoc::;;;;;;:lodxkkkxdooookKK0o.                               //
//    WWN0xooooooooooooooooooooooooooooooooooooooooooooooolllooxKNWWNKkolccllol;..          'dXWNx.                               //
//    WWWWNKOxoooooooooooooooooollooooooooooooooooooooooooollooodO0KNWWNX0Okxddoc'.   ...';lONWXd'                                //
//    NWWWWWNX0xdoooooooooooooolc::cloooooooooooooooooooooooooooooodOXNNNNNNNXXKK0kxdxkO0XNWWNKl.               ..                //
//    KXNWWWWWWNKOxdoooooooooooool:;;clooooooooooooooooooooooooooooooxOKXNXXXNNWWWWWWWWWWWNKkl'                 ..                //
//    NXKKXNWWWWWWNK0kxdoooooooooool:,:looooooooooooooooooooooooooooooodkOKXXXXXNNNNWWNX0xc'.                                     //
//    OXNNXKKKXXNWWWWNNXK0OOkkkkxxddo:;clooooooooooooooooooooooooooooooooodxkO00OO000Okl.                     .;cldxo,.           //
//    cdOKXNNXXKXXXXNNNWWWWWNNNNNXXKK0OOOOkkkxxddddooooooooooooooooooooooooooooo:;cooool,                   .:dO00XNW0;           //
//    ;codxk0KXNNNNNNNNNWWWWWWWWWWWWWWWWWWNNNNNXXXKK00Okkxddooooooooooooooooooool;,:loool'                 'd00kc:xNWNd.          //
//    ;coooooooxkOO00KKKKKKKKKKK000000kxkkO00000KKKXXNNNNNXK0OOkxdooooooooooooooo:,,:loooc.              .;kXOc.  cKWW0;  .       //
//    :looooolcllllooooooooooooooooooo:,;clooooooodddxkkO0KXXNNNXK00Oxdooooooooool;,;:lool,             .lKKd'   .oXWWK;          //
//    cloooooocccllooooooooooooooooool;,;:loooooooooooooooodxkO0KXNNNNKOxoooooooolc,,;:looc.           ,xKk;.   .lKWWNk'          //
//    looooooolclooooooooooooooooooooc;,;:looooooooooooooooooooodxxk0KNNXOdoooooool:,,;clol,         .lkx:.    'dXWWWXl.          //
//    oooooooooooooooooooooooooooooooc,,;:loooooooooooooooooooooooooodxOKKOdoooooool:,,:coo:.      .,cc,.    .cONWWWWk'           //
//    ooooooooooooooooooooooooooooooo:,;;:looooooooooooooooooooooooooooodxxdooooooool:,;:loc.    .;;'.     .:kXWWWWWK:            //
//    ooooooooooooooooooooooooooooool;,;;clooooooooooooooooooooooooooooooooooooooooool;,;col,...''.     .'lONWWWNNN0:.            //
//    oooooooooooooooooooooooooooooo:,,;:looooooooooooooooooooooooooooooooooooooooooooc;,:loc'...   ..;lkKNWNXKKXXk;              //
//    oooooooooooooooooooooooooooool;,;;cloooooooooooooooooooooooooooooooooooooooooooooc;cldxoc:clodkKXNNXK000KKk:.               //
//    oooooooooooooooooooooooooooool;,;;coooooooooooooooooooooooooooooooooooddxxkkOO00000KXXNNNNNWWWNNXXK000Oxl,.                 //
//    oooooooooooooooooooooooooooool;,;;cooooooooooooooooooolllooooooodxkO0KKXXXXKKKK0000OOOO0KK0Okkkkxxdl:,.                     //
//    oooooooooooooooooooooooooooool;,;;coooooooooooooooooollcloodxkOKKXXK0OOkxdddooooool:,;;cool'...                             //
//    oooooooooooooooooooooooooooool;,;;coooooooooooooooooolccldkKXXX0Oxdooooooooooooooooc,,;;lol;.                               //
//    oooooooooooooooooooooooooooool;,;;cooooooooooooooooolcllok00Okdooooooooooooooooooool;,;;cool,                               //
//    oooooooooooooooooooooooooooool;,;;cooooooooooooooooolloooddooooooooooooooooooooooool;,;;coooc.                              //
//    oooooooooooooooooooooooooooooc,,;:looooooooooooooooooooooooooooooooooooooooooooooool:,,;clooo;.                             //
//    ooooooooooooooooooooooooooooo:,,;:looooooooooooooooooooooooooooooooooooooooooooooooo:,,;cloool'                             //
//    ooooooooooooooooooooooooooooo:,;;cooooooooooooooooooooooooooooooooooooooooooooooooooc;;:cooooo:.        .                   //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CT is ERC721Creator {
    constructor() ERC721Creator("CompliedTrader", "CT") {}
}