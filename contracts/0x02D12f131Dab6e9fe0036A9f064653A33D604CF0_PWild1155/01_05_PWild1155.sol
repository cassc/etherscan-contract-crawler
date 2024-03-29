// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 1155 Portals by Wildalps
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                              //
//                                                                                                              //
//                                                                                                              //
//             █     █░ ██▓ ██▓    ▓█████▄  ▄▄▄       ██▓     ██▓███    ██████                                  //
//            ▓█░ █ ░█░▓██▒▓██▒    ▒██▀ ██▌▒████▄    ▓██▒    ▓██░  ██▒▒██    ▒                                  //
//            ▒█░ █ ░█ ▒██▒▒██░    ░██   █▌▒██  ▀█▄  ▒██░    ▓██░ ██▓▒░ ▓██▄                                    //
//            ░█░ █ ░█ ░██░▒██░    ░▓█▄   ▌░██▄▄▄▄██ ▒██░    ▒██▄█▓▒ ▒  ▒   ██▒                                 //
//           ░░██▒██▓ ░██░░██████▒░▒██████ ▓█   ▓██▒░██████▒▒██▒ ░  ░▒██████▒▒                                  //
//           ░ ▓░▒ ▒  ░▓  ░ ▒░▓  ░ ▒▒▓  ▒  ▒▒   ▓▒█░░ ▒░▓  ░▒▓▒░ ░  ░▒ ▒▓▒ ▒ ░                                  //
//             ▒ ░ ░   ▒ ░░ ░ ▒  ░ ░ ▒  ▒   ▒   ▒▒ ░░ ░ ▒  ░░▒ ░     ░ ░▒  ░ ░                                  //
//             ░   ░   ▒ ░  ░ ░    ░ ░  ░   ░   ▒     ░ ░   ░░       ░  ░  ░                                    //
//                                        ░▒░                                                                   //
//                                       ░░░▒░                                                                  //
//                                      ▒3.3▓▒░░                                                                //
//                                     ░█████▓▓░░                                                               //
//                                   ░░███████░▓▓█░                                                             //
//                                  ░▒█████▓█▓██▒███▓░                                                          //
//                                 ░▓███▓████▓▓▒▓████░                                                          //
//                                 ░███▓█▒░▓█▒░░█████▓░                                                         //
//                                ░███▓█░░▒█▒░░░░█████▓░                                                        //
//                                ░███▓░░░▒▒░▒▒░░▒██████░                                                       //
//                               ░████▒░▒░░░░░░░░░▒████▒░░                                                      //
//                              ░███░░UNTIL░░░░░░▒██████░░                                                      //
//                            ░░███░░░░░░░░░░░▒▒▒░▓██████▒░                                                     //
//                           ▒████░THE░░░░░░▒▒░░▒░███████▓░░                                                    //
//                          ░▓███░░░░░░░░░░░░░░▒░░░▒████████▒░                                                  //
//                         ░░▓▒░░░LAST░░░░░▒░░░░▒▒░░▓███▓▓██▓▓█▒█▒░                                             //
//                        ░░▒▒░░░░░░░░░░░░░░░░▒▒░░░▒█████████▓████▓░░                                           //
//                      ░░░░░▒▒░░BREATH░░░▒▒░░░░▒░░▓██████▓░░▒▓██████░░░                                        //
//                     ░▓▒▒░░░░░░░░░░░░░░░░▒▒▒░░░░▒MOUNTAINGOAT▒▓▓████▓▒░░                                      //
//                    ░▓▒░░▒░░▒░░▒▒░░░░░░░░░▒▒░░░▒█▓█████░▒█▓▒▓████████▓░░░░▒░░                                 //
//                   ░▒▒░░░░░▒██963██▒██▒░░░█████▒░▒████▓█▓▓█▓▓▒▓████▓█▓▒░░░░░░░                                //
//                  ░░░░░████▓▓░░▒░░░▒▒▒░▒BE░WILD░▓&█░FREE░ALWAYS▒▒░░▓▓▓▓░░░░░░░░▒                              //
//              ░░▒▓████▓█▓█▒░░░░░░░░▒░░▒▒░▒▓▓███▓█▓██▓▒░░░░░░░░░░░░░░░░░░░░░                                   //
//        ░░░░░▓▓██████▒░░░░░▒▓██▒░░▒░▒▒▒▒░░░░░░░░▓▓██▓▒░░░░                                                    //
//    ░░▓▓▒█NEW.69█▓██▓▓▒░░       ░░░░░░        ░░░░░░▓▓░▒▓░░░                                                  //
//     ░░░░░░░░░░░░░░░░░░        ░░░      ░▒▒▒▓██▓█░░░░░░░░                                                     //
//              ░░░░▒░░░                ░░▒▓▓▒▓▓▒▒░░░                                                           //
//                                    ░░░░░                                                                     //
//                                                                                                              //
//                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PWild1155 is ERC1155Creator {
    constructor() ERC1155Creator("1155 Portals by Wildalps", "PWild1155") {}
}