// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Take Off
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                           //
//                                                                                           //
//                                                                                           //
//                    ▄▓▓▄▄▄▄                                                                //
//                   (█     █▌                                                               //
//                   (█ ▄█▓ ╘                                                                //
//                    █n▀██                                ██▓▄                              //
//         ,▄▄.         (██                              ▄Ö   ╙█▌                            //
//         █▌¬¬.        (██  .#████▓                       ▄  .▀                             //
//         █▌ #███▓▄▄▄æææ█▌  ██▄..▄█¬  .▄ ▄▄▄,           ▄█"    ██∩                          //
//         ▀▌▐██▐█▀╓█   (█▌   ╙▀▀▀╙    ▀███▀███         ██.     ██⌐                          //
//           ██▌██▄▀    (█▌             ▀████▀¬       .██.      ▐█▌                          //
//          (██╙ █▌     (█▌  ╒██     ▄██  ██▓▄        ██.    .   ██     .▄▄       ▄#█æ«      //
//          ▐█▌ █       (█∩  ██∩   .█████  ▀██       ██─▄███████████▓▀▓█▀███▄▄   ██▀         //
//          ██¬"        (█¬ ███   ▄██████▌ .███▄    ████▀-▄███▌   ~█ ██▄███████ ███          //
//          ██           █▄████.▄██▀██▀▀██▄█▀└▀▀█▄ ▄████▄██╙ ██  ,   ╙▀▀.    ▀███▀           //
//          ██▄..▄▄▄▄▄▄▄æ██▀ ▀█▀▀.   ██████╙     ▀██▀  ¬.     └╙¬        ╒██▄,       ..▄ñ    //
//           ▀▀▀▀▀▀╙-▄▄███.         └██▄▐██                               ▀▀▀███████▀▀╙      //
//                #██▀▀  █¬          └█████                                                  //
//                       ▐                                                                   //
//                                                                                           //
//                                                                                           //
//                                                                                           //
//                                                                                           //
//                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////


contract TOFF is ERC1155Creator {
    constructor() ERC1155Creator("Take Off", "TOFF") {}
}