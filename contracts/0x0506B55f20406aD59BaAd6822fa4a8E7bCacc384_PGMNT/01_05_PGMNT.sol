// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pigment Companions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                        //
//                                                                                                                                                                                                        //
//                                                                                                                                                                                                        //
//                                                                                                                                                                                                        //
//                                                                                                                                                                                                        //
//                                                                                                                                                                                                        //
//                                                                                                                                                                                                        //
//                                                                          .......                                                                                                                       //
//                                       .';:cllooollc::;,'...         .;ldxdddddddxdo:.                                                                                                                  //
//              ...                 ':oxxxxdolc::::::cloddxddddddddddddxdl;..     ..,cdxxd;.                                                                                                              //
//            .xXX0o.           .;okkdc,.                    ..'','''..        .        .cxOl.                                                                                                            //
//            lWMMMMk.        'okxl'              .:oxkkkkxdoc;,...   ..';ldkO000ko;.      ,xOo.                                                                                                          //
//       .;oddOWMMMWx.      'd0d'              .lkXMMMMMMMMMMMMWNK00O00KNWMMMMMMMMMWKo.      ,kO;                                                                                                         //
//       oWMMMMMMMXd.     .l0x'               cKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0olo0WMO.      .o0o.                                                                                                       //
//       ;0NMMWXNWo      .x0:                cNMMMMMNkl::cdXMMMMMMMMMMMMMMMMMWd.   .xMMd.       :0d.                                                                                                      //
//        .';;'.dW0,    .k0;.               .OMMMMMWo      :XMMMXOxkO00kddONMWo     dWM0'        :Kd.                                                                                                     //
//              '0MXxc:l0MXOO0Oxl'          'OMMMMMWl      ;XMMX:    ..   .dWMNxc:ckNMM0'         lKc                                                                                                     //
//               ,0WMMMMMMMMMMMMMXc          oWMMMMMNkc;;:oKMMMXc         .xWMMMMMMMMMWo          .kO.                                                                                                    //
//                .lONMMMMMMMMMMMMd          .xWMMMMMMMMMMMMMMMMXx:'.'';co0WMMMMMMMMMNd.           lX:                                                                                                    //
//                  .dNK0NWMMMMMWO,           .oNMMMMMMMMMMMMMMMMMWNNNWMMMMMMMMMMMMNk;             ;Xo                                                                                                    //
//                   dK;.';clllc,.              ,xXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXx;               '0d.                                                                                                   //
//                   dK,                          'lkKWMMMMMMMMMMMMMMMMMMMWNK0ko:.                 '0x.                                                                                                   //
//                   cXc                             .,:clodxkkkkxdollc::;'...                     '0d                                                                                                    //
//                   .Ok.                                                                          ;Xo                                                                                                    //
//                    lXc                                                                          lX:                                                                                                    //
//                    .k0'                                                                        ,0x.                                                                                                    //
//                     ,0k.                                                                      .xK,                                                                                                     //
//                      ,0k.                                                                    .dK:                                                                                                      //
//                       'kO;                                                                  'k0;                                                                                                       //
//                        .l0x.                                                              .o0x.                                                                                                        //
//                          'xOl.                                                          'oOx,                                                                                                          //
//                            ,xOo'                                                     .:xOd,                                                                                                            //
//                              'okxc'.                                             .;oxkd:.                                                                                                              //
//                                .;oxkdc,.                                  ..,:odxxdc,.                                                                                                                 //
//                                    .:oxxxdlc;,'...            ...',;:lodxddxdoc,.                                                                                                                      //
//                                        ..;:lddxdddddxddddddddddddxdolc:,'..                                                                                                                            //
//                                                 ....''',,''....                                                                                                                                        //
//                                                                                                                                                                                                        //
//                                                                                                                                                                                                        //
//                                                                                                                                                                                                        //
//                                                                                                                                                                                                        //
//                                                                                                                                                                                                        //
//                                                                                                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PGMNT is ERC1155Creator {
    constructor() ERC1155Creator("Pigment Companions", "PGMNT") {}
}