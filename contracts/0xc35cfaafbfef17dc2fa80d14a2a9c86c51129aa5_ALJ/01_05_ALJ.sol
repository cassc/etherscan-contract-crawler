// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Alebrijes
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                       //
//                                                                                                                       //
//                                                                                                                       //
//                                                                                                                       //
//                                            ..:^~!77??JJJYYYYJJJJ?77!~^:..                                             //
//                                     .:^!7JY55PPPPPPPPPPPPPPPPPPPPPPPPPP55YJ7!^:.                                      //
//                                .:~7J5PPPPPPPPPPPP55YJ??777777??JYY5PPPPPPPPPPPP5J?~^.                                 //
//                            :~7J5PPPPPPPPP5YJ?7!777!!!!!!!!!!!!!!!!!77!7?JY5PPPPPPPPP5J7~:                             //
//                        :~?Y5PPPPPPPP5J7~^.  :~!!!!!7?Y5PGGGGP5YJ7!!!!!~^. .:~7JYPPPPPPPPPY?~:                         //
//                    .^7Y5PPPPPPP5J7~:.     :!!!!!?5B&@@@@@@@@@@@@&BP?!!!!!^      :~7J5PPPPPPPPY7^.                     //
//                 .~?5PPPPPPP5Y7^.        [email protected]@@@@@@@@@@@@@@@@@@@BY!!!!~.        .^7J5PPPPPPP5?~.                  //
//              .~J5PPPPPPP5?~.           [email protected]@@@@@@@@@@@@@@@@@@@@@@@B7!!!!:           .~?YPPPPPPP5J!.               //
//           .~?5PPPPPPPY7^.             .!!!!7#@@@@@@@@@@@@@@@@@@@@@@@@@@&?!!!!.              ^7YPPPPPPP5J~.            //
//         :75PPPPPPP57^                 [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@#7!!!~                 :7YPPPPPPP5?^          //
//      .~JPPPPPPP5J~.                  [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Y!!!!.                   ^?5PPPPPPPY!.       //
//     :YPPPPPPPPY^                     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@P!!!!:                     :YPPPPPPPPY^      //
//      :!YPPPPPPP5?^                   [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@5!!!!.                   :7YPPPPPPP57:       //
//         ^?5PPPPPPPY!:                 ~!!!!#@@@@@@@@@@@@@@@@@@@@@@@@@@@@&7!!!~                 :!JPPPPPPP5J~.         //
//           .!JPPPPPPPPJ!:              .!!!!?&@@@@@@@@@@@@@@@@@@@@@@@@@@&J!!!!:              :!J5PPPPPPPY!:            //
//              :!YPPPPPPPPY7^.           :[email protected]@@@@@@@@@@@@@@@@@@@@@@@#?!!!!:           .^7YPPPPPPPPY7:               //
//                 :!J5PPPPPPP5J!:.        .!!!!!Y#@@@@@@@@@@@@@@@@@@@@#5!!!!!:         :~?5PPPPPPP5J!:                  //
//                    .~?YPPPPPPPP5J!^.      ^!!!!!JP#@@@@@@@@@@@@@@#GJ!!!!!^.     .^!?YPPPPPPPP5?~:                     //
//                       .:!J5PPPPPPPP5Y?!^:. .^~!!!!!?J5PGBBBBGG5Y?!!!!!!^. .:^!?Y5PPPPPPPP5J!^.                        //
//                           .:!?Y5PPPPPPPPP5J?7!!!7!!!!!!!!!!!!!!!!!!7!!!7?J55PPPPPPPPPY?!^.                            //
//                                :^!?Y5PPPPPPPPPPPP5YJ??77777777??JY5PPPPPPPPPPPP5YJ7~:                                 //
//                                     .^~7?Y55PPPPPPPPPPPPPPPPPPPPPPPPPPPP55Y?7~^.                                      //
//                                           ..:^~!7??JJYYY5555YYYYJJ?7!~^:..                                            //
//                                                          ..                                                           //
//                                                                                                                       //
//                                                      ALEBRIJES                                                        //
//                                                 by Alberto Herrera                                                    //
//                                                                                                                       //
//                                                                                                                       //
//                                                                                                                       //
//                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ALJ is ERC721Creator {
    constructor() ERC721Creator("Alebrijes", "ALJ") {}
}