// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Noortje Stortelder
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                   .,;;,,:cl:;;;;;;,'..                                                     //
//                                .:dOKKKKKKKKKK000000Oxdoc:;'.                                               //
//                               'd0KKKKKKKKKKKKKK00000OOkkxxdl;'..                                           //
//                              .l0KKKKKKKKKKKKKK000000OOkxxdolc;,,'...                                       //
//                             .cOKKKKKKKKKKKKKKK000OOOOkxddolcc:;,;cc:,..                                    //
//                            .c0XXXKKKKKKKKKKKK00OOO00Okxdoollllc:clllll:;..                                 //
//                            c0XXXKKKKKKKKKKKKK0000000Okkxdddddddoollodollc;..                               //
//                           :OXXXKKKKKKKKKKXXKK000000OOkkxxxxxxxxddooddooool:;..                             //
//                          ;OXXKKXXXXXXKKKKXXXK00OOOOOOkkxxxxxxxxxxxxdoollllolc,.                            //
//                         ,kXXKKKXXXXXXXXXXXXKKK000000OOkkxxxxddddxkxdolcccloddo:'.                          //
//                        .xXXKKKXXXNXXXXXXXXKK0000OO00OOOOkkxxddddxxxdolccccodxxdo:'                         //
//                       .oKXXXXXXXXXXXXXXXXXK00000000000OOkxddxxddxxdolccc::lodxkkkdc'                       //
//                      .lKXXXXXXNNXXXXXXXXXXK00000000KK00Oxooxxxdddoolc:::;::ldkOOOOkdc'                     //
//                     .lKXXXXXXXNXXXXXXXNNXK00000000KKKK0kdodxkxdddoolc:;;;;;cdk00OOkkdl'                    //
//                    'xXXNNXXXXXXXXXXXXXNNXK000KKKKKKK00Okxdxkkxdddolllc:;;;;:ok00OOkxdl;.                   //
//                   .xXXNNXXXXXXXXXXXXXNXXKK000KKKKKK0OOOOkxxkkxdddooolc::;;;:lxO0OOkxdl:.                   //
//                   cKXXXXXXXXKKKKKXXNNNXXK0000000KKK00000Oxxkkxdddooolc:;;;;:ldk00Okkxdl,.                  //
//                  'kK000KKKK00000KXNNNXXK0000OO00KKKKKKKKOkkkkxddoolllc:;;;;:ldk000kkxxdc'                  //
//                 .o0Oxxk000kxxxxOKXNNXXXK000OkkO0KKXXXXKK0OOOOkdollclc:;;::;:clxO00Oxxxxo:.                 //
//                 :OOxdodO0OdllodkKXXXXXK00Okxdxk0KXNNXXXKK0OOOxocccc:;;;;,'..,cdk00Okxxxdl;.                //
//                 cOOdollk0klcccldOKKKKK0OkxdoodkKXNNNXXK000Okxoc:::::;,..     'lxO00Okkxxdc'                //
//                 .,::cccd0klcllloxO0K0Okxolcclok0XNNXKK00Okkdoc:;;::;.         'lkO00Okkkxo:'               //
//                     ...lOxllllccok00Okdlcc:ccldOKKK0OOOkxddlc:::;;;.           .lkO0OOkkkxdc.              //
//                       .cOkolllcclx00OkoccccccloxO00Okkxdoolc:::;;;,.            .okOO0OOkkko;.             //
//                       .o0kdlcccclx0K0kdlllllllldkO00Okkdolc::;;;;,.              ;k0000OkkOd:'             //
//                        ':;'......:OK0OxoooolllllxO000Okdolc:::;;;,.              .ckOO00Okkdc,.            //
//            ,do;.                 ,kK0OkddoolllccdOKKK0Okxdlcc::;;'.               .lkO000Okxl:.            //
//           ,OKKOdc;..             c0K0Okxdoolllc:lOKKKK0OOxollc:;;.                 'okO00Okdol;.           //
//          'kKKOkdlc:;. .',,'.    .oKK0Okxdooool:',xXXKKK0Okdolc:;,.                  'lxkOOkkxoc,.          //
//         .dKK0kdlc:;.  :OK0Oxl;..'xKK0Okxdooool, .oKKKKK0Okxolc:;'.                   .cxkOOOkxol;.         //
//        .l0K0kxocc:.  .dKKK00xl;':OKK0Okxdolool,  oKKKKK0Okxol:;;'                     .,lxkkOkdooc.        //
//        :0K0Okdlc:.   'kKKK0Oo:,'c0K0Okxdoolool'  lXXKKK0kxdoc:;;.                       .,ldxxddxd:.       //
//        cOOOkxoll;.   :0KK00ko:,'l000Okxdollooc.  lXXK00Okxxol:;,.                         .';::clc,.       //
//        .:xkxxoll:.  .oKKK0kdl:,,o00OOkxdolloo:. .oKK00OOkxxoc:;,.                             ....         //
//          ;xkxdool;  ,OKK0Oxol:,,d000Okxdollol,  .oKK0OOkkxdoc:;,.                                          //
//          .lkkxdol,  c0KK0Oxol:,'oOO00Oxdolllc'  .oKK0OOOkkxoc:;,.                                          //
//           'xOOkxo:. ,x000Oxoc:,.;xkOOxdlllllc,  .dXK0OOOOkdl:;,'.                                          //
//            :kOOkkdl'.'okOkxdlc;'.,loolc::cccc;. .oKK0OOkxdl:;,,.                                           //
//             'lxxkxdl;..cxkxxdlc;'..;::;;;::c:;.  cOkdddolc;;,,,.                                           //
//               'ldxddl;..cxkkxxoc;'..;::;;::::;'. ,xkollc:;;;,,'.                                           //
//                .;oool:. .lkkkkxoc;'..;::;;;::;,. .dOxdolc::;,,'.                                           //
//                  .:c:,.  .lxkkkxoc;' .';;,,;;;,'..oOkxxol:;;;,.                                            //
//                    ..     .ckOOOkdl:'. .',,,,;,,..lkkxdoc:;;;,.                                            //
//                            .:xOOOkxo:,.  ...',,'..:xxdoolc:;;,.                                            //
//                              ,dOOOkxo:,.    .......ldoool:;;;,.                                            //
//                               .cxOOkxol:'          'lll:;,,,,'.                                            //
//                                 'lkOkxdl;.          ,ccc;,,,'.                                             //
//                                  .;dkxdl;.           ..,,''..                                              //
//                                    'ldo:,.                                                                 //
//                                     ..'..                                                                  //
//                                                                                                            //
//                                                                                                            //
//    ░▒▓█ Noortje Stortelder █▓▒░                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Lifecasts is ERC721Creator {
    constructor() ERC721Creator("Noortje Stortelder", "Lifecasts") {}
}