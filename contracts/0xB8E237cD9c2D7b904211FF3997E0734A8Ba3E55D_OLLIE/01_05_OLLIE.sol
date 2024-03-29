// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OLLIESBLOG EDITIONS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////
//                                                             //
//                                                             //
//          ▄▄▌  ▄▄▌  ▪  ▄▄▄ ..▄▄ · ▄▄▄▄· ▄▄▌         ▄▄ •     //
//    ▪     ██•  ██•  ██ ▀▄.▀·▐█ ▀. ▐█ ▀█▪██•  ▪     ▐█ ▀ ▪    //
//     ▄█▀▄ ██▪  ██▪  ▐█·▐▀▀▪▄▄▀▀▀█▄▐█▀▀█▄██▪   ▄█▀▄ ▄█ ▀█▄    //
//    ▐█▌.▐▌▐█▌▐▌▐█▌▐▌▐█▌▐█▄▄▌▐█▄▪▐███▄▪▐█▐█▌▐▌▐█▌.▐▌▐█▄▪▐█    //
//     ▀█▄▀▪.▀▀▀ .▀▀▀ ▀▀▀ ▀▀▀  ▀▀▀▀ ·▀▀▀▀ .▀▀▀  ▀█▄▀▪·▀▀▀▀     //
//           ▄▄▄ .·▄▄▄▄  ▪  ▄▄▄▄▄▪         ▐ ▄ .▄▄ ·           //
//           ▀▄.▀·██▪ ██ ██ •██  ██ ▪     •█▌▐█▐█ ▀.           //
//           ▐▀▀▪▄▐█· ▐█▌▐█· ▐█.▪▐█· ▄█▀▄ ▐█▐▐▌▄▀▀▀█▄          //
//           ▐█▄▄▌██. ██ ▐█▌ ▐█▌·▐█▌▐█▌.▐▌██▐█▌▐█▄▪▐█          //
//           ▀▀▀ ▀▀▀▀▀• ▀▀▀ ▀▀▀ ▀▀▀ ▀█▄▀▪▀▀ █▪ ▀▀▀▀            //
//    +---------------------------------------------------+    //
//                    Artist:   OLLIESBLOG                     //
//                   Twitter:  @OLLIESBLOG                     //
//                  Website: OLLIESBLOG.ART                    //
//               Contract: OLLIESBLOG EDITIONS                 //
//                                                             //
//                                                             //
/////////////////////////////////////////////////////////////////


contract OLLIE is ERC1155Creator {
    constructor() ERC1155Creator("OLLIESBLOG EDITIONS", "OLLIE") {}
}