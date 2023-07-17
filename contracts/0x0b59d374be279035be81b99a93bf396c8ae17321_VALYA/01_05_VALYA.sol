// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Valentina - Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                              //
//                                                                                                              //
//    //////////////////////////////////////////////////////////////////////////////////////////////////////    //
//    //                                                                                                  //    //
//    //                                                                                                  //    //
//    //    ######   ###  ##    ###    ##       ####     ###  ##   #####   ###  #                         //    //
//    //    ###  ##  ###  ##   #####   ##       ##       ###  ##  ###  ##  ### ##                         //    //
//    //    ###  ##  ###  ##   ## ##   ##       #####    #### ##  ###  ##  #####                          //    //
//    //    #######  ###  ##  ##   ##  ##       ##       #######  ###  ##  #####                          //    //
//    //    ######   ###  ##  ##   ##  ##       ##       #######  ###  ##  ######                         //    //
//    //    ### ###   #####   ## ####  #######  #######  ### ###  #######  ### ###                        //    //
//    //    ### ###   #####   ## ####  #######  #######  ###  ##  #######  ### ###                        //    //
//    //    ### ###    ###    ## ####  #######  #######  ###  ##   #####   ### ###                        //    //
//    //                                                                                                  //    //
//    //    Artist: Valentina Rabtsevich                                                                  //    //
//    //                                                                                                  //    //
//    //    License: This license is for personal use only.                                               //    //
//    //    The non-commercial use of the NFT is free to display on personal devices,                     //    //
//    //    including virtual galleries or social media platforms, with credit to the artist.             //    //
//    //    No rights are included for commercial use including merchandise, commercial distribution,     //    //
//    //    or derivative works. Full copyright remains with creator Valentina Rabtsevich.                //    //
//    //                                                                                                  //    //
//    //                                                                                                  //    //
//    //                                                                                                  //    //
//    //////////////////////////////////////////////////////////////////////////////////////////////////////    //
//                                                                                                              //
//                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract VALYA is ERC721Creator {
    constructor() ERC721Creator("Valentina - Editions", "VALYA") {}
}