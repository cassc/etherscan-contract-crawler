// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: INKFLOW
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                               //
//                                                                                               //
//    INKFLOW                                                                                    //
//    by Akashi30                                                                                //
//                                                                                               //
//    Size of collection                                                                         //
//                                                                                               //
//    35 NFTs x 69 editions                                                                      //
//    7 NFTs x Open Edition-Public Mint                                                          //
//    8 NFTs x 47 editions (Golden Drops) / available only for Golden Ring holders.              //
//    ---------------------------------------------------------------                            //
//                                                                                               //
//    System of Drops                                                                            //
//                                                                                               //
//    7 Drops                                                                                    //
//    1 Drop = 5 NFTs (LE) + 1 OE (always TBA)                                                   //
//    ----------------------------------------------------------------                           //
//                                                                                               //
//    Golden Ring                                                                                //
//                                                                                               //
//    Group of token holders with bonuses.                                                       //
//    - Golden Drops access (Free)                                                               //
//    - Early Access to OE with special mint price                                               //
//    ----------------------------------------------------------------                           //
//                                                                                               //
//    Open Editions.                                                                             //
//                                                                                               //
//    Will be always available for a strictly specific amount of time.                           //
//    Open Edition tokens might be or might be not burnable. Who knows..                         //
//    ----------------------------------------------------------------                           //
//                                                                                               //
//    Sales & Pricing                                                                            //
//                                                                                               //
//    Starting by 1st drop the price will start at 0.005 with 0.0015 stepped sale every drop.    //
//                                                                                               //
//                                                                                               //
//                                                                                               //
//                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////


contract IFLW is ERC1155Creator {
    constructor() ERC1155Creator("INKFLOW", "IFLW") {}
}