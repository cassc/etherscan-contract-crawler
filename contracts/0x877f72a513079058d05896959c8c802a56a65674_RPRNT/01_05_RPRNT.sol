// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: THE RED PHONE - PRINTER
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////
//                                                                                    //
//                                                                                    //
//        ________________                                                            //
//      _/_______________/|                                                           //
//     /___________/___//||                                                           //
//    |===        |----| ||                                                           //
//    |           |   �| ||                                                           //
//    |___________|   �| ||                                                           //
//    | ||/.�---.||    | ||                                                           //
//    |-||/_____\||-.  | |�                                                           //
//    |_||=L==H==||_|__|/   NO CALLER ID - 1/1 COLLECTORS OE                          //
//                                                                                    //
//    FIRST COLLECTOR OF 1/1 PIECES ARE ENTITLED TO 100% OF MINT FUNDS FROM OE        //
//    ON THIS CONTRACT. SECONDARY ROYALTIES OF 6.9% WILL GO TOWARDS MAINTAINING       //
//    THE PROJECT. IF YOU ARE READING THIS. YOU ARE PAYING ATTENTION AND ATTENTION    //
//    PAYS.                                                                           //
//                                                                                    //
//    - NO CALLER ID                                                                  //
//                                                                                    //
//                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////


contract RPRNT is ERC1155Creator {
    constructor() ERC1155Creator("THE RED PHONE - PRINTER", "RPRNT") {}
}