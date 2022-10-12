// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OM by 6529 - Day 1
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                             //
//                                                                                             //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJYYYYYYYYYYYJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ?#@@@@@@@@@@YJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJPGGGGGG&@@@@@@@@@&BGGGGGGYJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJ?&@@@@@@&[email protected]@@@@@@5JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJ5&&&#######BGGGGGGGGGG#######&&&BJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    [email protected]@@#[email protected]@@&YYYYJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJ&@@@GBBGGGGGGGGGGGGGGGGGGGGGGGGGGBG#@@@5JJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJ5GGG&@@&[email protected]@@BGGPJJJJJJJJJJJJJJJJJJJJJ    //
//    [email protected]@@#[email protected]@@&JJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJ#&&&###BGGGGGG&@@@@@@@@@@@@@@@@@@@@@@@@BGGGGGG####&&&PJJJJJJJJJJJJJJJJJ    //
//    [email protected]@@@GGGGGGGBBG&@@@@@@@@@@@@@@@@@@@@@@@@BGBGGGGGGG#@@@GJJJJJJJJJJJJJJJJJ    //
//    [email protected]@@@[email protected]@@Y^~~~~~~~~~~~~~~~~~~~~~~~&@@&GGGGGG#@@@GJJJJJJJJJJJJJJJJJ    //
//    [email protected]@@@GGG#######5JJJJJJJJJJJJY!^^^[email protected]@@@###BGG#@@@GJJJJJJJJJJJJJJJJJ    //
//    [email protected]@@@[email protected]@@&:::#@@@@@@@@@@@@@P::^@@@@@@@@@@@@@@#GG#@@@G?JJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJP&&&####[email protected]@@@###@@@@[email protected]@@&###@@@#[email protected]@@BGGB###&&&#JJJJJJJJJJJJJJ    //
//    [email protected]@@BGGGBBG&@@@@@@@@@&::::::^@@@@@@@@@@G.::::[email protected]@@#[email protected]@@@JJJJJJJJJJJJJJ    //
//    [email protected]@@BGG#@@@J~~~~~~#@@&::::::^@@@[email protected]@@G.::::[email protected]@@@@@@[email protected]@@@JJJJJJJJJJJJJJ    //
//    [email protected]@@BGG#@@@?:^^^^:#@@@[email protected]@@P:^[email protected]@@#[email protected]@@@@@@[email protected]@@@JJJJJJJJJJJJJJ    //
//    [email protected]@@BGG#@@@?::^^^:#@@@@@@@@@@@@@G:^[email protected]@@@@@@@@@@@@@@@@@[email protected]@@@JJJJJJJJJJJJJJ    //
//    JJJJJJY#&&&###&&&@@@@&##G^^^7YYYYYYYYYYYYY7^^^[email protected]@@@@@@&&@&###&&&PJJJJJJJJJJ    //
//    [email protected]@@&[email protected]@@@@@@@@@&^^^^:::::::::::::^~~~~~~^::::::[email protected]@@@@@@@@@#[email protected]@@BJJJJJJJJJJ    //
//    [email protected]@@&[email protected]@@@@@@@@@&??J~^^^^^^^^^^^^:[email protected]@@@@@G:^^^^:[email protected]@@@@@@@@@#[email protected]@@BJJJJJJJJJJ    //
//    [email protected]@@&[email protected]@@@@@@@@@&JJJ7~~~^^^^^^^^^^Y######5^^^[email protected]@@@@@@@@@#[email protected]@@BJJJJJJJJJJ    //
//    [email protected]@@&[email protected]@@@@@@@@@&JJJJJJ?^^^^^^^^^^^::::::^^^^[email protected]@@@@@@@@@#[email protected]@@BJJJJJJJJJJ    //
//    [email protected]@@&[email protected]@@@@@@@@@&[email protected]@@@@@@@@@#[email protected]@@BJJJJJJJJJJ    //
//    [email protected]@@&[email protected]@@@@@@@@@&[email protected]@@@@@@@@@#[email protected]@@BJJJJJJJJJJ    //
//    [email protected]@@&[email protected]@@@@@@@@@&JJJJJJJJJJJ??J&&&&&&&&&&[email protected]@@@@@@@@@#[email protected]@@BJJJJJJJJJJ    //
//    JJJJJJY#&&&###&&&@@@@@@@&777?JJJJJJ5GGG##########[email protected]@@@@@@&&@&###&&&PJJJJJJJJJJ    //
//    [email protected]@@BGG#@@@@@@&^^^7JJJJJ?&@@@[email protected]@@@@@@[email protected]@@@JJJJJJJJJJJJJJ    //
//    [email protected]@@BGG#@@@@@@&^^^~!~!JJJ5GGPJJJJJJJJJJJJJJ#&&@@@@&##&@@@BGGGJJJJJJJJJJJJJJ    //
//    [email protected]@@#GG#@@@@@@&^^^^^^^[email protected]@@@@@@#GG#@@@P?JJJJJJJJJJJJJJJJ    //
//    [email protected]@@&[email protected]@@&^^^^^^^^^^[email protected]@@@@@@@@@@@@@@@@@@@@[email protected]@@&YYYYJJJJJJJJJJJJJJJJJ    //
//    [email protected]@@@[email protected]@@&^^^^^^^^^:[email protected]@@@@@@@@@@@@@@@@&&@&###&&&#JJJJJJJJJJJJJJJJJJJJJ    //
//    [email protected]@@@[email protected]@@&^^^^^^^^^:[email protected]@@@@@@@@@GPGGGGGGGP#@@@PJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    [email protected]@@@[email protected]@@&^^^^^^^^^:[email protected]@@@@@&###&@&&&&&&&@&GGGYJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    [email protected]@@@[email protected]@@&^^^^^^^^^:[email protected]@@@@@&[email protected]@@@@@@@@@&?JJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//                                                                                             //
//                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////


contract O6529 is ERC1155Creator {
    constructor() ERC1155Creator() {}
}