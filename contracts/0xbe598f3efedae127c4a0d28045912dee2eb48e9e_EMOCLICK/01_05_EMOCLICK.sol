// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Emochain Click (on the button)
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                    //
//    By clicking on the button (represented by the act of purchase)                                                                                                                                                                                                  //
//    Arseneca undertakes to perform an action by substitution, in order to add moral, social or physical well-being crypto to the blockchain.                                                                                                                        //
//    Each action creates an emotion, part of the radiation of which is captured,                                                                                                                                                                                     //
//    on the surface of a radio-frequency electronic chip.                                                                                                                                                                                                            //
//    This chip is connected to an emochain, a poetic representation of the crypto added in the blockchain.                                                                                                                                                           //
//    After clicking, an emochain (which you can also buy) is created.                                                                                                                                                                                                //
//    Clicking is like a bitcoin miner, you just create crypto and upgrade the system.                                                                                                                                                                                //
//    You have proof of your contribution.                                                                                                                                                                                                                            //
//    Arseneca is an artist not deceased since 1974.                                                                                                                                                                                                                  //
//    He is the creator of emochain, a new way of creating dynamic NFTs                                                                                                                                                                                               //
//    in the art world.                                                                                                                                                                                                                                               //
//    For each NFT created, there is a physical action performed, whose generated emotion is captured                                                                                                                                                                 //
//    on the surface of an electronic chip and connected to the blockchain.                                                                                                                                                                                           //
//    Arseneca exhibits regularly in galleries in Paris. He is the pioneer in 'dynamic art of NFTs'                                                                                                                                                                   //
//                        ,-.----.    .--.--.       ,---,.       ,--.'|    ,---,.  ,----..     ,---,                                                                                                                                                                  //
//                        '  .' \      \    /  \  /  /    '.   ,'  .' |   ,--,:  : |  ,'  .' | /   /   \   '  .' \                                                                                                                                                    //
//                       /  ;    '.    ;   :    \|  :  /`. / ,---.'   |,`--.'`|  ' :,---.'   ||   :     : /  ;    '.                                                                                                                                                  //
//                      :  :       \   |   | .\ :;  |  |--`  |   |   .'|   :  :  | ||   |   .'.   |  ;. /:  :       \                                                                                                                                                 //
//                      :  |   /\   \  .   : |: ||  :  ;_    :   :  |-,:   |   \ | ::   :  |-,.   ; /--` :  |   /\   \                                                                                                                                                //
//                      |  :  ' ;.   : |   |  \ : \  \    `. :   |  ;/||   : '  '; |:   |  ;/|;   | ;    |  :  ' ;.   :                                                                                                                                               //
//                      |  |  ;/  \   \|   : .  /  `----.   \|   :   .''   ' ;.    ;|   :   .'|   : |    |  |  ;/  \   \                                                                                                                                              //
//                      '  :  | \  \ ,';   | |  \  __ \  \  ||   |  |-,|   | | \   ||   |  |-,.   | '___ '  :  | \  \ ,'                                                                                                                                              //
//                      |  |  '  '--'  |   | ;\  \/  /`--'  /'   :  ;/|'   : |  ; .''   :  ;/|'   ; : .'||  |  '  '--'                                                                                                                                                //
//                      |  :  :        :   ' | \.'--'.     / |   |    \|   | '`--'  |   |    \'   | '/  :|  :  :                                                                                                                                                      //
//                      |  | ,'        :   : :-'   `--'---'  |   :   .''   : |      |   :   .'|   :    / |  | ,'                                                                                                                                                      //
//                      `--''          |   |.'               |   | ,'  ;   |.'      |   | ,'   \   \ .'  `--''                                                                                                                                                        //
//                                     `---'                 `----'    '---'        `----'      `---`                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract EMOCLICK is ERC721Creator {
    constructor() ERC721Creator("Emochain Click (on the button)", "EMOCLICK") {}
}