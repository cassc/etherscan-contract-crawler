// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bitcoin Dollars
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                  //
//                                                                                                                                                                  //
//    BTC price is $22,584 at the time of creating this contract (9.2.23 4:30pm)                                                                                    //
//                                                                                                                                                                  //
//    The person who will ever collect 22.6k pieces of these tokens                                                                                                 //
//    will receive 1 BTC airdropped personally to his wallet)                                                                                                       //
//                                                                                                                                                                  //
//    Phase 1:                                                                                                                                                      //
//    Bitcoin Dollars is 24h Open Edition at $1 per One Non Fungible Dollar                                                                                         //
//                                                                                                                                                                  //
//    Phase 2 (Begins immediately after mint stops):                                                                                                                //
//                                                                                                                                                                  //
//    In 24h rarity level (and image) of each One Dollar sold in profit                                                                                             //
//    and listed above the price it was bought will be multiplied.                                                                                                  //
//    Each One Dollar sold in loss or listed below the price it was bought                                                                                          //
//    will become burning dollar. Metadata will be updated respectively.                                                                                            //
//                                                                                                                                                                  //
//    Phase 3 (48h from launch):                                                                                                                                    //
//    During next 24h after 1st metadata update, all Two Dollars that                                                                                               //
//    will be sold in profit and listed above the price it was bought                                                                                               //
//    will be multiplied again once phase ends.                                                                                                                     //
//    All Burning Dollars that were sold in profit will become Normal Dollars.                                                                                      //
//                                                                                                                                                                  //
//    Phase 4 (72h from launch):                                                                                                                                    //
//    During 48h All Dollars resold in profit will be multiplied by 2 with each flip.                                                                               //
//    All Dollars listed below the amount of dollars on the image.                                                                                                  //
//    (Example: if one has 4th level NFT [$16], listing price must be above 0.01eth)                                                                                //
//    and Burning Dollars will be removed from the list of participants.                                                                                            //
//                                                                                                                                                                  //
//    Phase 5 (5 days from launch)                                                                                                                                  //
//    Metadata will be frozen and wallets with "One Hundred Dollar Bill" will receive special airdrop                                                               //
//                                                                                                                                                                  //
//    Phase 6 (23.2.23)                                                                                                                                             //
//                                                                                                                                                                  //
//    Burn function will open everyone will be able to burn equivalent of [$100] (can be 100x$1, 50x$2, 25x$4 and so on) in NFT to receive the bridgeable token.    //
//                                                                                                                                                                  //
//    0 level - Burning Dollar                                                                                                                                      //
//    1 level - One Dollar                                                                                                                                          //
//    2 level - Two Dollars                                                                                                                                         //
//    3 level - Four Dollars                                                                                                                                        //
//    4 level - Eight Dollars                                                                                                                                       //
//    5 level - Sixteen Dollars                                                                                                                                     //
//    6 level - Thirty Two Dollars                                                                                                                                  //
//    7 level - Sixty Four Dollars                                                                                                                                  //
//    8 level (max) - One Hundred Dollar Bill                                                                                                                       //
//                                                                                                                                                                  //
//                                                                                                                                                                  //
//    25% from all collected money during mint will be send to charity                                                                                              //
//                                                                                                                                                                  //
//    "It may be or may not be notable"                                                                                                                             //
//                                                                                                                                                                  //
//                                                                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BD is ERC721Creator {
    constructor() ERC721Creator("Bitcoin Dollars", "BD") {}
}