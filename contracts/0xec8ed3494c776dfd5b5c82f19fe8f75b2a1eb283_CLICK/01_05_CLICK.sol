// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sano click collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                          //
//                                                                                                          //
//                                                                                                          //
//                                               ..                                                .cl      //
//                                             ..click                                          .clic       //
//                                           .clickcl                                     ..clickcli        //
//                                         .clickcl      cli                            .clickclic          //
//                                       .clickcl    clickclic                        .clickcli             //
//                               .     .clickcl     .clickclic                      .clickcli               //
//                             .cl   .clickcli    clickclickcli            .       .clickcl                 //
//                         ..cli  .clickclic       .clickclic             .cli   .clickcl                   //
//                   ..clickcli  .clickclick       clickclic            .cli    .click        ..clic        //
//               .clickclickc   .clickclick        ..,           ...clickcl    .clickc     ..clickcli       //
//            .clickclick      .clickclick       .clic        .clickclick     .click     .clic`.clic        //
//          .clickc           clickclick       .click      .clickcli         .clic    .clic ..cli           //
//        .click            .clickcli        .clickcl     .clickc           ,clic   .click""c               //
//       click             .clickcl        .clickcl     .clickc            .clic  .click                    //
//      clic              .clickcl        .clickcli    .click             .cli  .clickclick           ..    //
//     .cli             .clickcli       .clickcli    .,click            .click .cli`.clickc          .c     //
//     cli            .clickcli        .clickcl     .clickc          .clickcl .cli  ,click        .cl       //
//     cli         ..cli.clickc      ..click     .cli cli        .clic  clickcli    ,clickcl     .cli       //
//     cli       .clic  click      .clickcl .,.cli    .cli     .clic   .clickcl      clickcl   .cli         //
//      ,clickclick     clic    .cli  ,cli .clickc     cl . .clic       click        .click ..cli           //
//         cl            clickcli      cl .cl .cl      clickcl          ,"`            clickc               //
//                                                                                                          //
//                                                                                                          //
//                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CLICK is ERC721Creator {
    constructor() ERC721Creator("Sano click collection", "CLICK") {}
}