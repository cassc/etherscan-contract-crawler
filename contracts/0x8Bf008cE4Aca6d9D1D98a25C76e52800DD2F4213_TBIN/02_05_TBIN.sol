// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Bottom Is Near
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllc;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:cllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllll,                                   .:llllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllll'                                   .:llllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllll;.............................................'clllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllll'    .,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'.....    .:lllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllll:;;;;.    .,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'.....    .,;;;:cllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllll'    .',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'.....    .:llllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllll'    .,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'.....    .:llllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllll;.....     ...............................',,,,,,,,,''''.    .:llllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllll'                                         ',,,,,,,,,,,,,.    .:llllllllllllllllllllllllllll    //
//    llllllllllllllllllllllll:;;;;.                                        .....',,,,,,,,,.    .:llllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllc'    ..........................................    .',,,,,,,,.    .:llllllllllllllllllllllllllll    //
//    llllllllllllllllllllllll'     .........................................     ',,,,,,,,.    .:llllllllllllllllllllllllllll    //
//    llllllllllllllllllllllll'                                                   .........     .:llllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllc.                                                                 .:llllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllc,.........      .............................................     .:llllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllcccccccccc.    .lollollllloooooooooooooooooooooolooolooollllo:.   .:llllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllll'    'odoodoodoodddoooooooooooddooddoooooodoooooood:.   .:llllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllll'    .cccccccccloddooooddddddddoccccccccclodooooood:.   .:llllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllll'    .;;;;;;;;;cooodooddddoooodl:;;;;;;;;:ododdodod:.   .:llllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllll'    .;:::;,,,':oooddddddddddddl::::;,',,;ododdooodc.....;::::clllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllll'    .clll,    'ldddooddoddddddollll;.   .ldoddooddoollo:.   .:lllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllll'    .llll,    .odoooooddddddddollll;    .ldodooodoodoodc.   .:lllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllll'    .loooc;,,,:ododdoddddoooodoooooc;,,,:ododddddooododc.   .:lllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllll'    'odooddddddooddooddddddoooodddoodddddodoodddoooooodc.   .:lclllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllll'    'oddoddddooddddodddddddddddododdoooooddodddoodolccl:.....;::::cllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllll'    'ododdooodooddooddodddoodddddooddoddooodddododc.   'dOOOd.   .:llllllllllllllllll    //
//    llllllllllllllllllllllllllllllllll'    'ododdoooddddddddddddddoodddddddddddddoodddood:.   .kKKKx.   .;llllllllllllllllll    //
//    llllllllllllllllllllllllllllllllll'    'ododdooddc,'''''''';lodooddddodddooddoodolccl;    .,:::;,''',cllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllll'    'ododdoood;         .cldooddddooddoooooodl::;:'         .:lllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllll'    .looooddod:..  ... .'clddoddddddddddoooool::::,         .:lllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllll'    .::::codddollllllllloooddododdddddddoc::::::::,    .;c::cclllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllll'    .;:::coddddddoooooodddddddddddddddddl:::::::::,    .:llllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllll'    .;::::clllllllccllclllllllllllllllllc:::::::::,    .:llllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllll'    .;::::::::::::;;::::::::::::::::::::::::::::::,    .:llllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllll'    .;::::::::;;;;;;;;;;;;;;;;;:::::::::::::::::::,    .:llllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllll'    .;::::::::,................;::::::::::::::::::,    .:llllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllll'    .;::::::::'. .            .;::::::::::::::::::'    .:llllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllll'    .;::::::::,'.''''''''''''.,;::::::::::::::clcl;    .:llllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllll'    .;:::::::::::::::::::::::::::::::::::::::codod:.   .:llllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllll,    .,;;;;:::::::::::::::::::::::::::::::::::codod:.   .:llllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllc::::'    .;:::::::::::::::::::::::::::::clooooodod:.   .:llllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllll'    .;::::::::::::::::::::::::::::;codddooood:.   .:llllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllll;'.'...........................,clcclodddooood:.   .:llllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllll'                         .ldodddoddodood:.   .:llllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllll,                         .ldooodoododood:.   .:llllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllc::::::::::::::::::::'    .ldodododdodood:.   .:llllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll,    .ldoodddddooood:.   .:llllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll,    .ldoodddddooood:.   .:llllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll,    .ldoodddddooood:.   .:llllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll,    .ldoodddddooood:.   .:llllllllllllllllllllllllllll    //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TBIN is ERC1155Creator {
    constructor() ERC1155Creator() {}
}