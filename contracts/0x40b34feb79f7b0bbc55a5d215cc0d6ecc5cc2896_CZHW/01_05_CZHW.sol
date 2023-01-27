// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: cze a hardware wallet
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    ................................................................................    //
//    ................................................................................    //
//    ................................................................................    //
//    ................................................................................    //
//    [email protected]@@@@@@[email protected]@[email protected]@[email protected]@@[email protected]@[email protected]@[email protected]@@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@*@@[email protected]@[email protected]@@@[email protected]@[email protected]@[email protected]@.....    //
//    [email protected]@@@@[email protected]@@@[email protected]@@@[email protected]@[email protected]@[email protected]@@@@[email protected]@@@[email protected]@@@@[email protected]@[email protected]@[email protected]@@@@[email protected]@[email protected]@@@[email protected]@@@[email protected]@@....    //
//    [email protected]@@@@@@[email protected]@[email protected]@##[email protected]@@@@[email protected]@[email protected]@@@@@@@@@[email protected]@[email protected]@[email protected]@[email protected]@@[email protected]@@[email protected]@@@@[email protected]@[email protected]@[email protected]@##...    //
//    [email protected]@[email protected]@[email protected]#@....................................    //
//    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@..........................    //
//    [email protected]&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.........................    //
//    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@........................    //
//    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.......................    //
//    [email protected]@@@@@@@@@@@@@@@@@@@@@@@%%%%%%@@@@@@@@@@@@@@@@@....................    //
//    [email protected]@@@@@@@@@@@@%%%%%%%%%%%%%%%%%%%%%%@@@@@@@@@@@@@@...................    //
//    [email protected]@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@@@@@@@@@@....................    //
//    [email protected]@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@@@@@@@@@@....................    //
//    [email protected]@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@@@@@@@@@@....................    //
//    [email protected]@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&@@@@@@@@@@...................    //
//    [email protected]@@@@@@@@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%@@@@@@@@@....................    //
//    [email protected]@@@@@@%%%%%%@@@@%%%@@@@%%%%%%%%%%%%%@@@@@@@@%%.....................    //
//    [email protected]@@@@@@@  /@@@@@@%%%%%@   @@  %%%%%%%%%%@@%%%%%%%...................    //
//    [email protected]@@%%%%@@@%%%%%@%%%%%%%%%%%%%%%%%%%%%%%@%%%%%%%%...................    //
//    [email protected]@@%%%%%%%%%%@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%....................    //
//    [email protected]@@%%%%%%%@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%.....................    //
//    [email protected]@@@%%%%%@@@@%%@@@%%%%%%%%%%%%%%%%%%%%%%%.......................    //
//    [email protected]@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%..........................    //
//    [email protected]@@%@###########@@@%###@@%%%%%%%%%%%%..........................    //
//    [email protected]@@@&###################@%%%%%%%%%%%..........................    //
//    [email protected]@@@%%%%@@%%%%%%%%%%%%%%%%%%%%%%%%%..........................    //
//    [email protected]@@%%%%%%%%%%%%%%%%%%%%%%%%%%@@@@@@@.......................    //
//    [email protected]@@%%%%%%%%%%%%%%@@%%%%%@@@@@@@@@@@......................    //
//    [email protected]@@@@@@@@@@@%%%%%%%@@@@@@@@@@@@@@@@....................    //
//    [email protected]@@@%%%%%%%%%%%%@@@@@@@@@@@@@@@@@@@@@..................    //
//    [email protected]@@@@@%%%%%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@..............    //
//    [email protected]@@@@@@@%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&..........    //
//    ..................#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@......    //
//    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.    //
//    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    [email protected]@@@@[email protected]@[email protected]@[email protected]@[email protected]@@[email protected]@[email protected]@@@@@@@@@@@@@@@    //
//    [email protected]@@@@@@[email protected]@[email protected]@@[email protected]@@[email protected]@[email protected]@@@[email protected]@@@@@@@@@@@@@@@@@    //
//    [email protected]@@@@@@@[email protected]@[email protected]@[email protected]@@[email protected]@[email protected]@[email protected]@@@@@@@@@@@@@@@@@    //
//    [email protected]@@@@@@@@.....%[email protected]@[email protected]@@@[email protected]@[email protected]@@@[email protected]@@@@@@@@@@@@@@@@@    //
//    [email protected]@@@@@@@@@@[email protected]*[email protected]@[email protected]@[email protected]@[email protected]@@@@@@@@@@@@@@@@@    //
//    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//                                                                                        //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract CZHW is ERC1155Creator {
    constructor() ERC1155Creator("cze a hardware wallet", "CZHW") {}
}