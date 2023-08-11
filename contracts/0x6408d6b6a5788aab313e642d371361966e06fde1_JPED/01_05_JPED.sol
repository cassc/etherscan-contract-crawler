// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Josh Pierce Editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMOkW0xXXxo0WkOMOxNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMOkW0xXXxo0WkOMOxNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMOkW0xXXxo0WkOMOxNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMOkW0xXXxo0WkOMOxNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMOkW0xXXxo0WkOMOxNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMOkW0xXXxo0WkOMOxNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMOkNx:c:'.;l:dNOxNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO:,.        .;:dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc              ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0kdccc'            lWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKl'.   .,c:.       .;cokO0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0,         ''      ;oc'.   .:kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWl                 ,l.         cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd..               ,'          .dWMWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNkl;'',:,             ,;..       'odl:,,,:oONMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMN0xdddkKWNl.     .c,          .c;..       :x:.        ,dNMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWKl'.     .,ok:.     ',        .,l;         'd;            :KMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMNx.           ,kl     .         .;c'         ':.        ..,''dWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWx.             :k,                .'.         ..      ,llc::;:dKWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMN:              'd,                                  .ld,       .oXMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMX;              ,;                                   ;o.          oWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWd.            ..                                    ,,           cNMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMNo.                                                 ..          .xWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWO:.                                                          'xWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWKxl:;,;,,,,,,,,,,,,,,'.,'.,,..';..;'.,;;,,;,,,,,,,,,,,;;:lkNMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWWWkkW0xXXxl0WkkMOxNMWWWWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMOkW0xXXxo0WkOMOxNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMOkW0xXXxo0WkOMOxNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    ,;:clodkKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMOkW0xXXxo0WkOMOxNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXK0Oxdolc    //
//            ..,:cloodxxkkOKXNWMMMMMMMMMMMMMMMMOkW0xXXxo0WkOMOxNMMMMMMMMMMMMMMMMMMMWNKOxolc::;,'...          //
//                          ..',;cldk0XWMMMMMMMMOkW0xXXxo0WkOMOxNMMMMWNXKKKKK0Oxdlc:;..                       //
//                                    .,:llodxk0ddXOxXXxo0WkONxcdoc:;'........                                //
//                                               ....;;'.;:,''.                                               //
//                                                                                                            //
//                                                                                                            //
//                  ..   .........     ..   ...........   .........           .....     ...........           //
//                 cK0; ,OKKKKKKK0kc. ,OKl .xKKKKKKKKK0; .oKKKKKKKKOd,    .cx0KXXXKOo, .oKKKKKKKKKKl          //
//                 oWN: :NMO:;;;:xXWO':NMd '0M0l;;;;;;;. .xMXo;;;:lOWNl .oXW0o:,';ckNX:.xMXo;;;;;;;.          //
//                 oWN: :NMd      dMWc:NMd '0Mk.         .xMK,     ,KMO,dWNd.       ',..xMK,                  //
//                 oMN: :NMx.....:0MK;:NMd '0MKdllllllc. .xMK:....,dNWdcXMk.           .xMNxlllllll'          //
//                 oMN: :NMNKKKKXNXk, :NMd '0MNOkkkkkkx' .xMWXKKKXNXOl.:NMd.           .xMW0kkkkkkk;          //
//                 oMN: :NMO:;;;;,.   :NMd '0Mk.         .xMXo;:xNWx.  '0MK;           .xMK,                  //
//           '.   ,0MK, :NMd          :NMd '0MO.         .xMK,  .lNWx.  ,0MKo'.   .:xk;.xMK;                  //
//          ;KXOkOXW0:  :NMd          :NMd '0MN0OOOOOOO; .xMK,    cXWO'  .lONN0kkOKNKd'.xMWKOOOOOOOc          //
//          .,coool:.   .cl,          .cl, .:lllllllllc' .;l:.    .,ll,.   .,cloool;.  .;llllllllll,          //
//          ckkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk:          //
//          .,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,.          //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract JPED is ERC1155Creator {
    constructor() ERC1155Creator() {}
}