// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DFZ UNDEAD ICONS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//    DDDDDDDDDDDDD      FFFFFFFFFFFFFFFFFFFFFFZZZZZZZZZZZZZZZZZZZ    //
//    D::::::::::::DDD   F::::::::::::::::::::FZ:::::::::::::::::Z    //
//    D:::::::::::::::DD F::::::::::::::::::::FZ:::::::::::::::::Z    //
//    DDD:::::DDDDD:::::DFF::::::FFFFFFFFF::::FZ:::ZZZZZZZZ:::::Z     //
//      D:::::D    D:::::D F:::::F       FFFFFFZZZZZ     Z:::::Z      //
//      D:::::D     D:::::DF:::::F                     Z:::::Z        //
//      D:::::D     D:::::DF::::::FFFFFFFFFF          Z:::::Z         //
//      D:::::D     D:::::DF:::::::::::::::F         Z:::::Z          //
//      D:::::D     D:::::DF:::::::::::::::F        Z:::::Z           //
//      D:::::D     D:::::DF::::::FFFFFFFFFF       Z:::::Z            //
//      D:::::D     D:::::DF:::::F                Z:::::Z             //
//      D:::::D    D:::::D F:::::F             ZZZ:::::Z     ZZZZZ    //
//    DDD:::::DDDDD:::::DFF:::::::FF           Z::::::ZZZZZZZZ:::Z    //
//    D:::::::::::::::DD F::::::::FF           Z:::::::::::::::::Z    //
//    D::::::::::::DDD   F::::::::FF           Z:::::::::::::::::Z    //
//    DDDDDDDDDDDDD      FFFFFFFFFFF           ZZZZZZZZZZZZZZZZZZZ    //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract DFZ is ERC1155Creator {
    constructor() ERC1155Creator("DFZ UNDEAD ICONS", "DFZ") {}
}