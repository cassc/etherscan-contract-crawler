// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: L'homme Grenouille
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                         .........................................                  ....    //
//                                    ......................................................             .    //
//                                .......................................................... .                //
//                             ...................',::cccclcc:;'............................... ...           //
//                          ....................,:clllllllllccc:;'..''''...........................           //
//                        ....................;clllllcccccccccc:::;:cllcc:;'........................          //
//                     .....................,cllloxxxdolccllllllcc:::clcccc:;'.......................         //
//                   ......................:lllccldxOK0OOOkxdoolccc:::cccccc::;,......................        //
//                 .......................:llccccccclkKKKKXX0OOkxdolc::clllllc:;,.......................      //
//                .......................;lllllllccccldO0KKk:,dKKKK0OOkkkxdolc:::;'.......................    //
//              ........................'cllllllllllllllodkkxxOKXXXKKKXXK0kdxOkxxo;..',,,',;:,............    //
//             .........................,clcc:cccllllllllccloodxxdooloxOKOlcxKXXKd;,;ccllccclc;...........    //
//            ..........................;clc:looddddoooollllc::::::cllllodxkkOkxc',ccllllllccc:'..........    //
//           ...........................,clclooddolllooooooooollllllllllcccc:;'...;ccccllllccc:'..........    //
//         .............................':cccllooolc::::cclloodddoooollllllll;.....,:cllccc:cc,...........    //
//        ...............................':cccccllooollccc:::ccclloooooddddddl,.....:llllc:;:,............    //
//        ..............................'',::cccccccclllllllcccccccccccclool:,......:olllcc::;'...........    //
//       ........................',;;::ccccc:::::cccccccccccccclllllccclloo;........':llllllcc,...........    //
//      ........................;lllllccllllcc:;;,,,;;;:::::ccc::::;;;;;;,'...........,cllcccc:'..........    //
//     ........................;llcclc:cclllllcc:;,,,''''''''''''''....................;clc::cc,..........    //
//     .....................,:cccccllc;:cccllcclc::;;,,,,,,,,,,,,,;:::;;,'.............,cllcccl:'.........    //
//    ....................,clcccllcccccc::cllcclllcc::;;;;;;;;;::::cccclcc:,'..........;cllllllc;.........    //
//    ...................:lllclll:clcclc:clolccclcclcccc::;::::ccccccccccccc:,.........;cllcccclc,........    //
//    ..................:llcclll::ll:cc::lolc::cccccc:clllcllc::ccccclcccclcc:;'......'cllccccccl:'.......    //
//    .................;llcccclc::llccccllc:::ccc:::c:clllllllc:cccccllllcccccc;'.....,clllcc::ccc:.......    //
//    .................;llccclc::cllllllc:ccccccc:::::ccccllllcccccclccccc:cccl:,''...;llclcc::::ll,......    //
//    .................,clc:cc::clllllc:::ccc::::::::::cccccccccc:ccclllc:;clclc::::;,:lllccc:::cll;......    //
//    ................';c:;;;;;;clclccccc:;;,;;:cc::::::ccc::;;;;;;;:cclc;;cccllccccc::lllccc:c::cl;......    //
//    ...............,cllc:::;;;::cllccclc;'',;;:::cccccllc;;;;;;;;;:cllc;,:ccclllllc::lllllc:cc::l;......    //
//    ..............,cccc:::cccccclcclcllc;'',,;;;;::cclcc:;;;;;;;;;:cllc;,;:ccc:cllc::lllclc:cc::c,......    //
//    .............,cc:::::::cccccccllllc:,',,;;;;;;;;:ccc:;;;;;,,;;:cll:,,,;;:ccccc:;clllclc:ccc:;.......    //
//     ............:ccccccc::::::::ccllcc,'',;;;;;;;;;;;::;;;;;,,,:ccccc;',,;;;;:clc;;:lllllc:cccc;.......    //
//     ............:llcccccccccccc:cclcc;'',,;;;;;;;;;;;;;;;;;;;,,clcc:,..',,;;;;:cc::ccllllc:::cl:'......    //
//     ............'cllcccccclllllcclcc;',,,,,;;;;;;,,,;;;;;;;;::;;::;'....',,;;;;:ccllccllcc:;;:c:'......    //
//      ...........,cllcclllllccccccc:;',::;,,,,,,,,,,,;;;;;;:::cc:'........'',,;;;cclllcllc:;;;;:;.......    //
//       ..........:ollllllllccccccc:,',,;::;,,;;;;,,,,,,,,,,,,,:cc,..........'',,;;:ccllcc:;;;;,,........    //
//        ........,lllllccllccccclc;,',;,,;::;;;;;;,;;;;;;,,,,,,;c:,.............''',;::::;;;,,,'.........    //
//        ........;lllclcccllcccc:,'',:c:;,;;;;;;;;,,,;;;;;,,,,,;cc,...................''''''''...........    //
//         ......;llcllc::cllllc;'''',;;;;,,,;;;,,,;,,,,,,;,,,,,:::,......................................    //
//          ....:ll:cllc::lllclc;',;cloodooollc;,,,,,,,,',,,,,,,;;,.......................................    //
//           ...,cc:cllc::llccllloxOOOOkkkkOOOOkdoc:::;;;,,,,,;:;'.......................................     //
//            ..'cc:ccc::cllclcldO0kdllllllodkOOkkxxddolllllcccc:'.....................................       //
//             .,lc::ccc:ccllclldxdl::c::;:clodxddoooooooodddoolc;'..................................         //
//             .'cc;::cc::clllllc;,',,''...'',;:ccllollllooooddddxo'...............................           //
//              .:c::ccc::llclc;'................'',,;;::clooodddxo'..............................            //
//              .,lccclc::cllcc:,;cc;'....................',:cllll:'...........................               //
//               .:lccccccccllcccclol;'.........................',:ol,......................                  //
//                .:llcccllllcccc::c;'............................,d0x,...................                    //
//                .,lllllllllllccc:;,'............................'lOOc................                       //
//               .,llllllllllcclllcc:;,'..........................'lkkc'..............                        //
//               'clccclcclccclllcc:cc:,..........................,okk:.'''...,;::::;,'...                    //
//              .:cc:ccclllccllllc;;clc,'.........................;oOk:......';cllllllllc:'.                  //
//            .,clcccllllllllollc:,,;:;,'.........................;oOk:.....',:cllllclcclllc;.                //
//            'clcllllclllcclollcc;,,'''.........................';dOOc'....,:clllllllcccclllc;'...           //
//           .:ccccllllcclc:cccccc;,'.............................;dOOo,...':cclllllcccc:cclllllcc:,..        //
//          .,:;,;:ldolloolodllccc,'..............................;x0Od;..';cccllllcccc:::ccllllllllc,.       //
//           ..  .;dxoxkkdodol:,,,'...............................,d0Ox:',:cccllllllllcccc:ccccllcllol,.      //
//               .lkxk0Oo:,,,''...................................,okkxl::clcclllllllllclllcc::cclllll:.      //
//              .;dddkOo,.........................................,lodxdlclcclllllllllllllllccccllcclc;.      //
//              .okxOOo,..........................................,lcoddolcllccclllllllllcllcccllllc::'.      //
//             .:xxkOo,...........................................:l:lddl:ccccccllllccccccccc:cllllc;'.       //
//             'oxxxo,..........................      ............:ocdxdc,,;::ccccccccc:;;:cc::cclc:'.        //
//            .;xkxo,......'''''..............              .....'clcodd:'.'',,,,,,:c::,''',;:cccc:,.         //
//            .,ldl;'',,,,,,,,,,,'''''......                     .odccoo;.........,cc:;''',;:cccc:,.          //
//             .,cc:::cccc:::c:::;;,,,'.....                     ,xd;:lo,       .;cc:;,,;::cccc:;,..          //
//             .,ccllllll:;:cccccc::;;,''..                      :kd:clo;      .;ll:;,;:ccccc::;,'.           //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LHG is ERC721Creator {
    constructor() ERC721Creator("L'homme Grenouille", "LHG") {}
}