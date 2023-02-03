// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Raphael Erba - Open Edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                         .:~J5GB##&&&&&&&&##BGPJ!:.                                          //
//                                    .~YB&&#G5?~^:..      ...^~7YG#&&B5~.                                     //
//                                 ~5&&#5!.                          .~YB&&P!.                                 //
//                              [email protected]&5^                                    :Y#@#7                               //
//                           :[email protected]&Y.                                          .?&@G^                            //
//                         ^#@B^                   7BBG5J!:                     :[email protected]&!                          //
//                       :#@G.             .:^~!777?&@@@@@@@&5^                   [email protected]&~                        //
//                      [email protected]         .?G#&@@@@@@@@@@@@@@@@@@@@@@5.                  [email protected]                      //
//                    ^@@!            ^JG#&@@@@@@@@@@@@@@@@@@@@@@@5                   ^&@!                     //
//                   [email protected]#.                [email protected]@@@@@@@@@@@@@@@@@@@@@@@&.                   [email protected]                    //
//                  [email protected]            .!YG&@@@@@@@@@@@@@@@@@@@@@@@@@@@@&^77:                [email protected]                   //
//                 [email protected]              ^JG&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&57.                [email protected]                  //
//                [email protected]#                   .?#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&                  [email protected]                 //
//                @@.                 ~5#&#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@B                    &@:                //
//               [email protected]                          [email protected]@@@@@@@@@@@@@@@@@@@@@@@Y7^                  [email protected]                //
//               @@.                           @@@@@@@@@@@@@@@@@@@@@@@@@P:                   &@.               //
//              ^@B                          :#@@@@@@@@@@@@@@@@@@@@@@&^                      [email protected]               //
//              [email protected]                         [email protected]@@@@@@@@@@@@@@@@@@@@J ..                       [email protected]               //
//              [email protected]?                         :[email protected]@@@@@@@@@@@@@@@@&G~                           [email protected]               //
//              [email protected]                          [email protected]@@@@@@@@@@@@@@@@:                             [email protected]               //
//              [email protected]                          ^@@@@@@@@@@@@@@@@@B                             [email protected]               //
//              [email protected]@                           [email protected]@@@@@@@@@@@@@@@@~                            #@:               //
//               [email protected]!                           &@@@@&G7.:[email protected]@@@@@@&B                         :@&                //
//               [email protected]&                           ^Y~:    .^[email protected]@@@@@@@@!                        [email protected]~                //
//                [email protected]                              .7G&@@@@@@@@@@@@@.                      [email protected]                 //
//                 [email protected]?                             :[email protected]@@@@@@@@@@@@@@&.                    [email protected]&                  //
//                  #@7                               [email protected]@@@@@@@@@@@@@&.                  ^@&.                  //
//                   [email protected]                            :~?&@@@@@@@@@@@@@@#                 [email protected]&.                   //
//                    [email protected]#.                       ^&@@@@@@@@@@@@@@@@@@@@?               [email protected]                     //
//                     :&@J                       [email protected]@@@@@@@@@@@@@@@@@@@&             [email protected]@~                      //
//                       [email protected]&!                     [email protected]@@@@@@@@@@@@@@@@@@@@!          ^&@5                        //
//                         [email protected]&?                  [email protected]@@@@@@@@@@@@@@@@@@@@@#        !&@P.                         //
//                           ?&@G^              [email protected]@@@@@@@@@@@@@@@@@@@@@@@.    :[email protected]&Y.                           //
//                             :P&&P~          :@@@@@@@@@@@@@@@@@@@@@@@@@! ^5&@G~                              //
//                                ^5&&#Y~.     #@@@@@@@@@@@@@@@@@@@@@@@@@@&&P~                                 //
//                                   .~5#&&[email protected]@@@@@@@@@@@@@@@@@@@@@@@#5!.                                    //
//                                        .~?PB#&@@@@@@@@@@@@@@&#B5?~.                                         //
//                                                ...::::::...                                                 //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract REOE is ERC1155Creator {
    constructor() ERC1155Creator("Raphael Erba - Open Edition", "REOE") {}
}