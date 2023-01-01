// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CLSS Studio
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                 .';;'''.....'''''....                                                          //
//    .        ..   .            ...               .cddlc;;;;;,,'''''...                                                          //
//    ..  ',. .::. .','................            .:loddolccc:;,''''..                                                           //
//    '..'c:'.'cc'..;::;,,,,''',,,,''...            ';:clodolc;,'......                                                           //
//    ;,.';,'',;;,,:oxdlc::c::::::;,''...           .;c:::cdoc:,'......                                                           //
//    cc:;;::;:c:::ldxkkxoooolc:;;;,'....            .;::;;cddoc:;;;;;,,,,;;,'..                                                  //
//    lol;;::::cclllccodkkxoolc:;,,'...               ';;;;:oOOxdddxxkkkkO00Okdc;'....                                            //
//    dl;,;:;;;;:::cllllloxxol:;,''.....              .cddddxKNXKXXXNNWWWWNNXKKOkdooooolc:;'.                       .:xxl.        //
//    o:'.''',:::;;ccclllcokkdlc:::;,,,,;,,'..         ;k00O0XMWWWWWMMMMMWWNNX0kdllloddxOOOko,.                    .c0NMWd.       //
//    :'.';;,;:ccccccccccccdOOxxddxxxxkkOOkxdc;'....   .lO000NMMMMMMMMMMMWWNNXXK0OOOO000KK00Od:.                   .:ckNM0'       //
//    ,.'cdxxxddxxxkxxdddddxKNXKKXXNNNNWNNXKKOkdoooollccoOK00NWWWWWWWMMMMMMWWMMWWXKKKXNNNNXKko;.                  .....lK0,       //
//    ::lkKNWNXXXXNWNXK00000XWWWWWMMMMMMMWNNX0OxdxxkkO0KKNWXKXK00KKXNWWMMMMMMMMMMWNWNKxc;:::,.                   ,x0x,  cOc       //
//    OO0XNWMMMMMWMMMMWNXKKKXMMMMMMMMMMMWWNNXKOkkkO000KXNWMXOoc::lodkOKNWWMMMMMMWNKOd:.                          ;0NN0:..l;       //
//    NNNXNNWWMMMMMMMMMWNX00XWMMMMMMMMMMMMWMWWWNXXXNWWWWMMNx;..  ..'.':oOKXWMWWXK0kdl:'.                         c0dcdx,.:.       //
//    MWNKKKKXNWMMMMMMMMWWXKNNNXNNWWMMMMMMMMMMMWNNNNXkdk0NNl.          .';:dOKK00Okdl:'.                       .:kk:'c:.''.       //
//    WWWNXXXXNWMMMMMMMMWWWX0kddxk0KNWWMMMMMMMMMWX0d:...cKXc               .':cloolc;'.                        .ldllc::,..        //
//    NWWMMWWWWMMMMMMMMMWN0o:'..';::lx0XNWMMWWXKOkdl:'..cK0,                 .',:c:;,'..           ....        .lOxl'..           //
//    0WWWMMMMMMMMMMMMMMWO:.       ...,coxKNNXXK0Oko:'..oKd.                  ..';;;,''...   ......','.       .;do,;,             //
//    xXKKXNNNNNXK00XWMMNd.             ..:oxxkxxdlc,..'xKl.                   ....',''''......''',;;;'.      .cdc...''.          //
//    :dOKNNNNNX0xodOXNWXc                ..;cloolc:,''c00;             ........''',;;;::;;,,;clllloll:'.     'okxc:oo;           //
//    ,lx0XNNXX0xl:cdk0Xx'                 ..,:cllcc:;:kXx.          ...,clc::;;:::;:clodooddodxkOOOkxo:.     ,kKKkl:.            //
//    :ldO0KK0Okdc:coxOOc.                ....';;:c:clxXKl.           ..;lkOkxdolloooddddxkkOOOOO00Okkdc'.     .'..               //
//    ldkO0KK0OOxolodk0x,             .....'',,,;cllld0WXxlcc;....'',,..l00OOOkkxooooodxkkkO00000000Okdc,.                        //
//    lO0KKXKKOkxddxk00l.         ....,lolccccllllodx0WMWNKKK0O0KXNNWWNXXNOccoxxxxdoodxkOOO00KKKK000Okdc;..                       //
//    :0XXXXXKOkOO00KXk;          ..',cdO0OkxdddxxxkOKWMMMMMMMMMWXXXNWMWNO:. .,coddoodxdxO000KKKKK00kxdc;'.                       //
//    'OXNNNNXXKKXXNWKxl::;,..  .....;kXXXKK00kxxkkO0KNWMMMMMMMMW0xdlc:;'.     .';cllodxxkOKKXXKK000kxdl:'.                       //
//     lXNNWWWNNNNWWWXXXKK0OxdxkO0K00KWMXkxO0OOOkkkk0KNWMMWNXNNWW0xl.            .';:codxkO0000000OOkkdlc,.                       //
//     .kNNNWWWWWWMMWWWMWWWWWWMWWWMMMMMNx;';lxkOkkkO00XNWWKdllokX0xc.           ..',;;:ldxkkOO000OOOkkxoc;'.                      //
//      ,ONXXWWWWWWWXOKWMMMMMMMWKOOkxol;.....,codxxkO0XWMN0xolcxK0kl...       ..',,;::cloxkkOOO00Okkkxddlc,.                      //
//       ,kKKXWWWWWNKkdk0XNWWWMMXd;..       ...;coddk0XWMWNX0Okkxxxxxxxdol:,,,coddddoddddxkkOOOOOOkkxxddl:;.                      //
//        'xKXNWMWNX0Oxolododk0N0l.         ..',:cloxOXWMMMWWWNXXXXXXXXXXXXXXXXXNNXXK0OOOkkOOOOOOOOkxxddoc;.                      //
//         .xKXNWWNXKOkdc;,:c:d0O:.       ..',;:clloxOXWMMMMMMMMMMMMMMMMMWNXK0xddOKXXXXKKKKK000OOOOkkxdolc,                       //
//          .oKXNWNNXK0xlodkkxxkkkdolc:;'.';ldddxxxkOKNWMMMMMMMMMWWWNKOxdc,''. .'lk0XXXXXXXKK000Okxdollcc:'                       //
//           .l0XNWWWNXKXWWNNXKKKXXXXXXXKK00KXNNXXXKKXWMMMWNKOkxkkxxdlc::c:ccccodxO0KKK00OOOkkxxollccccccc,                       //
//            .cOXNWMMMWWMMMMMMMMMMMMMMWWWWNKOOKNNNNNWMMMMMWNXK0000KKKK0KKXKK00Okxxxxxxxxxxxxdoollcccclll:'                       //
//             .cOXWMMMMMWMMMMMMMMWNK0Odlc:,..,o0XNWWMMMMMMMMMMMMMMMWWMMMMWNKOkxdoollodxxxxxddoolllllodoc;.                       //
//              .cOXWMWNK0OOkkkOOOkdlc::::c:coxk0XNNNNWWMMMMMMMMMMWWWWWNKOkxdlc:;;::clodddxdddddddxkkkdl:,.                       //
//               .cOXWWNXXXXK0OO0KKKK00KKKKKK000OOOOO0KNWMMMMMMNX0kkkxo;.....  ....,:lodxxxxxxkO0KXXKkoc:,..                      //
//                .ckKNWWWWMMMMMMMMMWWWWMWXKOOkxxxxxO0XWMMMMMMWX0Oxxddc..     ....,:loxxkOO0KXNWWWNKkdool:'..                     //
//                 .:xKNWMMMMMMMMMMMMWNKK0kxdollllodk0XWMMMMMMMWNXXKK0dc:::;;;:clodxkO00KXNWMMMMWNX0Okxdc'.                       //
//                   ,dKNWWMMMWNX00Oko;,''....',;:ldO0XWMMMMMMMMMMWWWN0kxxxkkkkO00KXNNWWMMMMMMMWNK0Oxoc;..                        //
//                    .oKWWNNNXK0Okxo,...   ...';ldk0XWMMMMMMMMMMMMMMWNXXXXXXXNNWWWMMMMMMMMMWNXKOkxol:,..                         //
//                     .c0NNNNNNNNXKkoccc:;:clodxk0XNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNX0OOxdlc;'...                         //
//                       ,kNWWMMMMMWKkkxkkkkkO0KXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXK00Oxdlc;,''''..                       //
//                        .:OWMMMMMMWXXXXXNNNNWWMMMMMMMMMMMMMMWWWWWWNNNWWMMMMMMMMMMWWWNNXXK0Okkxdoc:,'......                      //
//        ....              .;xKWMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWNNXKK0OO0XWMMMMMMWWNNXXKXKK0OOkxdl:;,'............'..              //
//    :loxkOkdl;,'....         ,kNNNWWWMMMMMMMMMMMMMMMMMMMWWNNXXKKK00OkkOKWMMMMMWNNXXKKK0OOOkxoc:;,'............,:;..             //
//    KNWWMMWKOdlc:;,'.        .dKKKKXXNWWMMMMMMMMMMWWWWWWWNXXXXKK00Okxxxx0NMMMMMWWNXXK00Okxxoc:;;,;:,''....,'''';;'..            //
//    NNNWWWNXKOxol:;,'.........dKKKKKKXXNWWMMMMMMWWNNNNNNXXXXKKOkkkxxddoodONMMMMWWNXXK0Okxxxoc:;;;lxdlc::;,'.....,'...           //
//    KXXNNWWWNKOxdlc:;'........oKK0KKKKKXNWMMMMMMWWWNNNNXXKKK0OxxxxdooollooOWMMMWWNXXK0OOkkxdlccloxxdoolccc;.    ....            //
//    xO0KNWMMMWX0OOkdl:,....  .c0000KKKKXXNWMMMMMMWWWNNXXK000Okxdddox0OxdddxKMWNNXKK0KK0OkkkkxkkOOOkkxdolcc;.      .             //
//    odxO0XNWWWNXXXX0Oxlc;,'...l0K0000KKKXNNWMMMMMMWWNXXKK000OxxdddxOKXK0OOk0NWWXXK0OOO00Okxk0KK00Okxddoolc:'.                   //
//    ddxxkO0KKKKKKKKK0kdol:;'..dXWNK00KXXXNNWMMMWWWNNNXXXK00K0OOO00KXXXK00OkkOXWNXK0OkkOK0kdx0XK00Okxxdoolc:;. .                 //
//    xxxxxxxxxxkkOOkkxdoc:,.. .xWMWNXXKKXXNWWWWWWNXXKKKXXKKKKKXNNWNNXXXK00OkxxkXNXK00OOOOOkxxOKK0OOkxdoccc::,...                 //
//    looooollccllollc:,..     ;OWMMWNNXKNNWNNWWWWNXXK000KXXKO0XWWWNNXXK00OOOkxoxKNNNX0OOOkxddk0K0Okxdol:;;;;,'.                  //
//    ,;;;:;;,,',,,'..        .cKMMMWWWXKNWWNNWWWWWNXKK000KX0OOKNWNNNXXKK0Okkxdocc0WMWNK0OOkxdxkOOOkxolc;,,,,'..                  //
//    .'',,,''...             .lKWMMMWX00XWWNNWMWWWWNXXK00000Ok0XNNNXXK00Oxdddolc;:dKWWNK0OOkkkkxxkxdolc;'...                     //
//    ,,'....                 .lONWWWWKOO0XXXXWMMMMMMMWNX000OOkOKXXXXKK0Okdolllcc:;',dKX000KXX0kdolcc:'..                         //
//    ..                      .;lkXNWXOkkOO0KXNMMMMMMMMMWXK00OkkO000000Okxdlc::,'''',:oxO00KKkxocc:;...          ..               //
//                            ..;lxKX0xxkkkO0KNWMMMMMMMMWXKK000KK0kkO00Oxxoc,'...';cldxkKXKKKkolccc:'..        ...                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CLSS is ERC721Creator {
    constructor() ERC721Creator("CLSS Studio", "CLSS") {}
}