// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Feels GeoMetric Man
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//     ____               ___               ____                                    __                                                                          //
//    /\  _`\            /\_ \             /\  _`\                  /'\_/`\        /\ \__         __              /'\_/`\                                       //
//    \ \ \L\_\ __     __\//\ \     ____   \ \ \L\_\     __    ___ /\      \     __\ \ ,_\  _ __ /\_\    ___     /\      \     __      ___                      //
//     \ \  _\/'__`\ /'__`\\ \ \   /',__\   \ \ \L_L   /'__`\ / __`\ \ \__\ \  /'__`\ \ \/ /\`'__\/\ \  /'___\   \ \ \__\ \  /'__`\  /' _ `\                    //
//      \ \ \/\  __//\  __/ \_\ \_/\__, `\   \ \ \/, \/\  __//\ \L\ \ \ \_/\ \/\  __/\ \ \_\ \ \/ \ \ \/\ \__/    \ \ \_/\ \/\ \L\.\_/\ \/\ \                   //
//       \ \_\ \____\ \____\/\____\/\____/    \ \____/\ \____\ \____/\ \_\\ \_\ \____\\ \__\\ \_\  \ \_\ \____\    \ \_\\ \_\ \__/.\_\ \_\ \_\                  //
//        \/_/\/____/\/____/\/____/\/___/      \/___/  \/____/\/___/  \/_/ \/_/\/____/ \/__/ \/_/   \/_/\/____/     \/_/ \/_/\/__/\/_/\/_/\/_/                  //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                   .......'''......                             .......'''......                                         .    //
//                                             ..',;:ccclllllllllllcc:;,'..                 ..',;::cllllllllllllcc:;,'..                                   .    //
//                                         ..,:clllllllllllllllllllllcllllc:,..         ..,;clllllllllllllllllllcclllllc:,..                               .    //
//                                      .';clllllccllllccccccccccccclllllcclll:,..   ..;clllcllccccllllccccccccccccccclllll:,.                             .    //
//                                    .,cllllllllllllllccccccccccccllllcclccllllcc;',:lllcllcclllllllllcccccccccccccccllclcllc;.                           .    //
//                                  .;cllcccllllcclllllcccccccccclllllllllllllllclloolllccccclllllllccllccllccclccccclllllllcclc;.                         .    //
//                                 'clllcccclllllllllllllclllccccllllllllcccclccllllooolcllcllclllllllccccclllllllllcccllccclllll:.                        .    //
//                               .;lllllcllllllllllllcclllllllllllllllllllllllccllclcldolclccllllllllllllllllllllllllllllcclllclllc'                       .    //
//                              .;llclllcccllllllllllllclllooooooooooooooooooooooooollodolclllllllllllllooooooooooooooooooooooooollc.                      .    //
//                             .;lllllllccccllccclcccccccccccccccccccccccclllllllloooooddlcccclllccccclcccccccccccccccccllllllloooooc.                     .    //
//                             'cllccllllllllcldxkkxxkkkkkkkkkxkkkkkxxkkkkkkkkxxxxxxxxkOOkxkkxxkxxxxxoldxxkxxkkkkkkkkkkkkkkkkkxxxxkkko:::::::::::::::::::::c    //
//                            .:lllllllllllllco0NNXKKKXXXXXXXXKKXXXKKXXXXXXXXXXXXXXXXXKKXXXXXXKXXXXNNOd0WNXKXXKXXXXXXXXXXXXXXXXXXKXKXKKKKKKKKKKKKKKKKKKKKXNW    //
//                          .,lolllllclllllllco0WKdoooooooooooooooooooooooooooooooooooooooooooooooxKNOd0W0dooooooooooooooooooooooooooooooooooooooooooooooxXW    //
//                       .':looollllcclllllllco0W0ollclllllllllcccccllllllllllllllllllllllllcllcccdKNOd0W0ocllcllllllllllllllllccllcclllllllllllllllllclldXW    //
//                     .;loolloolcllcclllllllco0W0ocllllllllllllllllllccccccccccccccccllllllllllccdKNOd0W0occcclllllllllllllllllllllllllllllllllllllllclcdXW    //
//                   .;ldolllclolclccllllllllco0W0ocllllllllllllllllllllllllllllllllllllllllllllccdKNOd0W0occcclllllllllllllllllllllllllllllllllllllllllcdXW    //
//                 .;odolllllcllcllccllllllllco0W0ocllllllllllllllllllllllllllllllllllllllllllllccdKNOd0W0occcllllllccllllllllllllllllllllllllllllllllllcdXW    //
//               .,ldolllllllllllllllclllllllco0W0ocllllllllllllllllllllllllllllllllllllllllllllccdKNOd0W0occccllcclccclllllllllllllllllllllllllllllllllcdXW    //
//              .cddollllllllllllllclllllllllco0W0oclllllllllllllllllllllllllllllllllllllllllllllcdKNOd0W0occcccclccllllllllllllllllllllllllllllllllllllldXW    //
//            .;odollccccccccccccccccllllllllco0W0oclllllllllllllllllllllllllllllllllclllllllllllcdKNOd0W0ocllllllllllllllllllllllllllllllllllllllllllllcdXW    //
//           .cddolllccccccccccccccccllllllllco0W0occcclllllllllllllllllllllllllllllllllccccclccccdKNOd0W0oclllllllllllllllllllllllllllllllllllllllllccccdXW    //
//          'lddolllllcccccccccccccccllllllllco0WKdlooooooooooooooooooooooooooooooooooooooooooooooxKNOd0W0dloooooooooooooooooooooolooooooooooooooooooooloxXW    //
//         'lddollllllcccccccccccccccllllllllco0WNXKKKKKKKKKKKKKKKKKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXNNOd0WNXKKKKKKKKKKKKKKKKKKKKKKXXXXXXXXXXXXXXXXXXXXXXKXXNW    //
//        'oddollcllllcccccccccccccccllllllllco0WOc;;;;;;;;;;;;;;;;;;;;:dXWWWWWWWWWWWWWWWWWWWWWWWWWWNOd0WOc;;;;;;;;;;;;;;;;;;;;:xNWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//       'lddoolcllccccccccccccccccccllllllllco0Wd.                     :XWWWWWWWWWWWWWWWWWWWWWWWWWWNOd0Wd.                     :XWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//      .ldddolclllclcccccccccccccccclllllllllo0Wx.                     :XWWWWWWWWWWWWWWWWWWWWWWWWWWNOd0Nd.                     :XWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//     .:dddolllllllllcccccccccccccccllllllllco0Wx.                     :XWWWWWWWWWWWWWWWWWWWWWWWWWWNOd0Wd.                     :XWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//     ,odddolllllclllcccccccccccccccllllllllco0Wx.                     :XWWWWWWWWWWWWWWWWWWWWWWWWWWNOd0Wd.                     cXWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    .cdddollllclllllcccccccccccccccllllllllco0Wx.                     :XWWWWWWWWWWWWWWWWWWWWWWWWWWNOd0Wd.                     cXWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    ,odddollllcllllllccccccccccccccllllllllco0Wx.                     :XWWWWWWWWWWWWWWWWWWWWWWWWWWNOd0Wd.                     cXWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    cdddollllllllllllccccccccccccccllllllllco0Wx.                     :XWWWWWWWWWWWWWWWWWWWWWWWWWWNOd0Wd.                     cXWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    odddolllcllllllllccccccccccccccllllllllco0Wx.                     :XWWWWWWWWWWWWWWWWWWWWWWWWWWNOd0Nd.                     cXWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    ddddolllllllllllccccccccccccccclllllllllo0Wx.                     :XWWWWWWWWWWWWWWWWWWWWWWWWWWNOd0Nd.                     cXWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    xdddolllllllllllcccccccccccccclllccllllco0W0occcccccccccccccccccclkNWWWWWWWWWWWWWWWWWWWWWWWWWWNOd0W0occccccccccccllllcllclkNWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    ddddolclllllllllcccccccccccccclllccllllclk0KKKKKKKK000KKKKKKKKKKK000000000000000000000000000000xok0K0KK0KKKKKKKKKKKKKKKKKKK000000000000000K0kxxxxxxxxx    //
//    ddddolllllllccccccccccccccccccclllcccllcllllllllllllllllllllllllllllllllllllllllllllllllllllllllcllllllllllllllllllllllllllllllllllllllllllc.        .    //
//    ddddollcclllclllccccccccccccccllcllllclllllllllccccllccccclcccccccccccccccccccccllllllllllllcllcccclllllllllcccccllllllllllccllccclccllllllc.        .    //
//    dddddolcclllclllcccccccccccccclllclllooddddddddooolllcccllllllllclllcccclcccllcccllllccccllllllccllcllclllllllccclllllllllcccllllcclllcccllc.        .    //
//    dddddollllllclcccccccccccccccccccllodddddddddddddddddoooollllllllllllllllcllllllccllcccccllllllllllllllllllllllllllcclcllccclllccllllccllcl:.        .    //
//    ddddddolccllcccccccccccccccccclllloxdddddddddddddddddddddddddooooolllllccclllllcccclllcclllccclllllllccccclllcllllllllllccclllllllllcllloodc.        .    //
//    cdddddollcllccclcccccccccccccclcloxxdddddddddddddddddddddddddddddddddddooooooolllllllccllllllllllllllccccllllllcllccclllllllllllooooddddddxdoc'      .    //
//    ,odddddollllccllllllllllccccclllldxdddddddkOOkxxdddddddddddddddddddddddddddxxdddddddddddoooooooooooooooooooooooooooooooddddddddddxddddddddddddl.     .    //
//    .:ddddddollllcllllllllllccccclllldxxddddddxOKXXKK0OOkkxxddddddddddddddddddddddddddddddddddddddxxddddddddddddxxxxxxddddddddddddddddddddddddddddc.     .    //
//     .cddddddollccllccclllccccccccllloxxddddddddxOKXNNNNXXXK000Okkxxxdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddxxo;.      .    //
//      .lddddddoolllcllllllllllcccllllloxxxddddddddxk0XXNNNNNNNNNNXXKKK00OOkkkxxxxddddddddddddddddddddddddddddddddddddddddddddddddddddxxxxxxxxxxx:.       .    //
//       .cdddddddollllclllcllllllcllllllodxxxdddddddddxO0XXNNNNNNNNNNNNNNNXXXXXKKKK0000OOOOkkkkkxxxxxxxxxxxxxxxxxxxxxxxxxxkkkkOOOO000KKXX0xddddddl.       .    //
//        .cdddddddoolllllccllllllcllllllloodxxxddddddddddxO0KXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXXXXXXXXKKKKKKKKKKKKKKKKKKKXXXXXXXXNNNNNNNNNNNKxddddddo'       .    //
//         .;odddddddollcllcllllllclllllcllloodxxxxddddddddddxkO0KXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXNNNNNNNNNNNNNKkddddddo,       .    //
//           .codddddddollllccllccclllllccllllloddxxxddddddddddddxkO0KXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXNNXXKKXNNNNNXNNX0xddddddo'       .    //
//            .'lddddddddoollllllllcllllclllllllloodxxxxxddddddddddddxxkO0KKXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXNXKKKK0OOO0KXNNX0kdddddddc.       .    //
//              .,cddddddddoolllllllllllllllclllclllooddxxxxdddddddddddddddxkkO00KKKXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXKKXNWWWNXKOkk00kxdddddddo'        .    //
//                .'coddddddddoollllllllllcclllllccllllooddxxxxxdddddddddddddddddddxkkOO000KKKXXXXXNNNNNNNNNNNNNNNNNNNXKKKNWWWWWWNKkdoodddddddddl'         .    //
//                   .;ldddddddddoolllllclllcclllccclllllloooddxxxxxxdddddddddddddddddddddddxxxkkkkOOOOOO00000000000O00000KKXNNN0kdollloddddddo:.          .    //
//                     .';loddddddddooolllccllllllllllllllllllloodddxxxxxxxdddddddddddddddddddddddddddddddddddddddddddkkkOOOO000xollclllddddl:.            .    //
//                        ..;codddddddddooolllllllllcccccclllcclllloooodddxxxxxxxxxdddddddddddddddddddddddddddddddddddxkkkkkkkOOdlccllcloddo'              .    //
//                            .';coddddddddddooolllllcccclllllllllcllllloooooddddxxxxxxxxxxxxxxddddddddddddddddddddddxkOkkkkkkkOxlcllcloddoo,              .    //
//                             .'cdOkkkxxdddddddddoooollllllcllccllllllllllllllooooooodddddddxxxxxxxxxxxxxxxxxxxxxxxkOOOOkkkkkkkkolllooollod:.             .    //
//                         .';lxkOOOOOOOOkkkxxxdddddddddooooollllllllllllcccclllllllllllllooooooooooodddddddddxxkkkOOOkxdxxkkkkkkdlooollooood,             .    //
//                      .'cdkOOOOOOOOOOOOOOOOOOkkkkkxxxdddddddddoooooooolllllllllllllllllllllllllllloooddxxxkkOOOOOOOOkxdooooddxkOkdooooollkXd.            .    //
//                   .':oxkkkkkkOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkxxxxxxxxddddddddddooooooooddddddxxxxxkkkOOOOOkkkkkOOOOO0OOOkxxddodkOkkxookd'cX0,            .    //
//                ..:odddddddxxxxxkkkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkOOOOOOOOOOOkkkkxxxxxddxkOOOOOKN0odOOOOxlokOOxcdN0;,kk;            .    //
//              .,lddddddddddddddddddxxxxxxxkkkkkkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkOkkkkkkkkkxxxxxxdddddddddddxkOOOOKNK;'kNOloolxkOx''ONxodxl.           .    //
//            .;odddddddddddddddddddddddddddddddddxxxxxxxxxxxxxxkkkkkkkkkkkxxxxxxxxxxxxxxxddddddddddddddddddddddxkOOOOO00o,dN0,.clokkk:,dkxxxxd,           .    //
//          .:oddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddxkOOOOkxxdxOOl;colxkkkddxxxdxxc.          .    //
//        .;oddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddxkOOOOOkxxxxxxdxdldkkOkxxdxxxxo,          .    //
//      .,ldddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddxkOOOOOOkxxxxxxxookOOOxxxxxddxdc.        .    //
//     .cdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddxkOOOO0XXXK0OkkkxdOKKKOxddddddxxo,.      .    //
//    ,oxddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddxkOOOOKXXXXXXXX0xkKXX0xddddddxxxdc.     .    //
//    dxdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddxkOOOO0XXXXXXXNKxx0XXKkddddddxxxdxc.    .    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FGMAN is ERC1155Creator {
    constructor() ERC1155Creator("Feels GeoMetric Man", "FGMAN") {}
}