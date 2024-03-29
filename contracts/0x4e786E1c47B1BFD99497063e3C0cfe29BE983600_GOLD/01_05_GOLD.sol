// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Michael Gold
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                   ▓▓░    ░▓                                                   ░▓░                          //
//                  ░██    ▓█             ▓▓                     ░▓           ░▓████▓         ░▓       ░▓▓    //
//                  ██▓   ▓█▓             █▓                    ░█░          ▓██▓░░█▓         █▓       ▓█     //
//                 ▓██░  ▓██  ▓▓         ▓█░                    ▓▓          ▓█▓░  ▓█░        ░█░      ░█▓     //
//                ░██▓  ▓██▓ ░██░        ▓▓                    ░█░         ▓█▓   ░█▓         ▓▓       ▓█░     //
//               ░█▓█▓ ░██▓  ░█▓        ░█░                    ▓█         ▓█▓   ░█▓         ░█░       █▓      //
//               ▓█▓█ ░█▓█▓             ▓▓                     █▓        ▓█▓   ░█▓          ▓▓       ░█░      //
//              ▓█░▓▓░▓▓▓█          ░   █▓               ░    ░█        ░█▓   ░█▓     ░     █▓      ░▓▓       //
//             ▓█▓ █▓▓▓░█▓   ▓▓   ▓██▓ ░█░▓█▓   ░▓██▓  ░███░  ▓▓        █▓     ░    ▓██▓   ░█    ░▓███        //
//            ░█▓ ▓██▓ ▓█░  ░█░  ▓▓ ▓▓ ▓█▓██▓  ▓█▓░░  ▓█░ █░ ░█░       ░█░      ░▓░▓▓░██▓░░▓▓   ▓▓░░▓▓        //
//           ░█▓  ▓██░ ▓▓   ▓▓  ▓▓  ▓░░██░░█░ ▓█░ ▓░ ░█░ ▓▓  ▓▓        ▓▓      ██▓░█  ▓█▓▓▓█░  ▓▓  ░█▓        //
//           ▓▓  ░██░ ░█▓   █░ ░█     ▓█▓ ▓▓  █░ ░█  ▓▓ ▓▓   █▓        █░     ▓█▓ ▓▓   █░ ▓▓  ░█   ▓█░        //
//          ▓█░  ▓█▓  ░█▓  ░▓  ▓▓     █▓  █░ ▓█  ▓▓  ▓█▓░   ░█░        █░    ▓██  ▓▓  ▓▓  █▓  ░▓  ▓▓█░        //
//      ▓████░  ░█▓    ▓███▓▓▓▓▓███████░ ░███████████▓████████▓▓       ▓▓░░▓▓██▓   ▓▓█▓   ██▓▓▓█▓█▓ ▓███▓     //
//    ░▓▓▓▓▓▓   ░░      ░░░ ░░░  ░░░░░░   ░░░░░░░ ░   ░░░░░░░░░░       ░███▓▓▓█     ░░    ░░░░░░░░   ░░░      //
//                                                                       ░░  ▓▓                               //
//                                                                          ▓█                                //
//                                                                         ░█▓                                //
//                                                                         ▓▓                                 //
//                                                                        ▓▓                                  //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GOLD is ERC721Creator {
    constructor() ERC721Creator("Michael Gold", "GOLD") {}
}