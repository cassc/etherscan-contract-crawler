// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: andy8052
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJY5555555555555555555555555555YJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ#@@@@@@@@@@@@@@@@@@@@@@@@@@@@GJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJJ5555B############################G5555JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJJ&@@@[email protected]@@#JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJ5PPPB###PYYYYYYYYYYYYYYYYYYYYYYYYYYYYG###B5PP5JJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    [email protected]@@@[email protected]@@&JJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJYPPPP####P555555555555555555555555555555555555P&###PPPPJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    [email protected]@@@[email protected]@@@YJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    [email protected]@@@[email protected]@@&YJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    [email protected]@@@[email protected]@@@YJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJYBBBBBBBBJ???JJJJJ???JJJJJ????JJJJ????JJJJJ???YBBBBBBBGYJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    [email protected]@@@[email protected]@@&JJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJY&@@@[email protected]@@&JJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    [email protected]@@@[email protected]@@&JJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJ[email protected]@@&JJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    [email protected]@@&[email protected]@@[email protected]@@[email protected]@@&JJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    [email protected]@@&[email protected]@@&JJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    [email protected]@@&[email protected]@@&JJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    [email protected]@@@[email protected]@@&JJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    [email protected]@@@@@@@[email protected]@@&JJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    [email protected]@@@[email protected]@@&JJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJY&@@@[email protected]@@@@@@@[email protected]@@&JJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJY&@@@[email protected]@@&JJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJY&@@@[email protected]@@&JJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJY&@@@[email protected]@@&JJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJY&@@@[email protected]@@&JJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJY&@@@5JYYYYYYYYYYYYYJ5############[email protected]@@&JJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJY&@@@[email protected]@@@@@@@@@@@[email protected]@@&JJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJY&@@@[email protected]@@&JJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJY&@@@[email protected]@@&JJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJY&@@@?~!~!!!!?YYYYJJJJJJJJJJJJJJJJJJJJG&&&B555YJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJY&@@@[email protected]@@BJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJY&@@@?~!!!!!~!!!!J&&&&&&&&&&&&&&&&&&&&GYY5YJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJY&@@@[email protected]@@@@@@@@@@@@@@@@@@@GJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJY&@@@[email protected]@@&YYYYYYYYYYYYYYYYYJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJY&@@@[email protected]@@&JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJY&@@@[email protected]@@&JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJY&@@@[email protected]@@&JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ANDY is ERC1155Creator {
    constructor() ERC1155Creator("andy8052", "ANDY") {}
}