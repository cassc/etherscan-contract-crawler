// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Susano Correia
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                             .:::^Y#@@&##BY~.                               //
//                                                        .!5B#@@@@@@@@@@@@@@@@@G.                            //
//                                                    .!Y#@@@@@@@@@@@@@@@@@@@@@@@@~                           //
//                                                .~5#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@^                          //
//                                            .7B&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@~                         //
//                                          :[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G.                       //
//                                        ^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@^                      //
//                                      [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.                     //
//                                     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:                    //
//                                   .#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&                    //
//                                 [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@?                   //
//                               [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&                   //
//                             :[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:                  //
//                            [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@J                  //
//                          :&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&                  //
//                        [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@^                 //
//                      !#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&J^.  .^?G&@@@@@@@@@7^&@@@@@@@@@@@@?                 //
//                    !&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&~   ~?7^    :7P#&&#Y.  [email protected]@@@@@@@@@@@G                 //
//                 ^P&@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@5  [email protected]@@@@@#P!:        !#@@@@@@@@@@@@@&                 //
//               ?&@@@@@@@@@@@@@@#J:      .?&@@@@@@@@@@@&&@@@@@@@@@@@@&BGGB&@@@@@@@@@@@@@@@@@.                //
//             ^&@@@@@@@@@@@@@&J:            [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@~                //
//            [email protected]@@@@@@@@@@@@G^                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@?                //
//          ~&@@@@@@@@@G:GJ.                  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G                //
//        :[email protected]@@@@@@@@@#                       &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&                //
//      [email protected]@@@@@@@@@@P                        #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@?               //
//    7&@@@@@@@@@@&Y.                         [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&[email protected]@@@@@@@.              //
//    [email protected]@@@@@@@#Y^                            [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&!     [email protected]@@@@@@&              //
//     .^7J?!:.                               [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Y        &@@@@@@@G             //
//                                            [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@^        ^@@@@@@@@?            //
//                                            [email protected]@@@@@@@@@&^~&@@@@@@@@@[email protected]@@@@@@~         [email protected]@@@@@@@7           //
//                                            [email protected]@@@@@@@@@.  :@@@@@@@@7 [email protected]@@@@@@!          &@@@@@@@@~          //
//                                            &@@@@@@@@@B   [email protected]@@@@@@@^ #@@@@@@@Y          ^@@@@@@@@@.         //
//                                           ^@@@@@@@@@@!   [email protected]@@@@@@@J #@@@@@@@B           [email protected]@@@@@@@G         //
//                                           [email protected]@@@@@@@@@    ^@@@@@@@@B &@@@@@@@#            [email protected]@@@@@@@7        //
//                                          [email protected]@@@@@@@@@P    [email protected]@@@@@@@&:@@@@@@@@#             [email protected]@@@@@@@.       //
//                                          [email protected]@@@@@@@@&~    [email protected]@@@@@@@@[email protected]@@@@@@@#              [email protected]@@@@@@&:      //
//                                          &@@@@@@@@@.     #@@@@@@@@@[email protected]@@@@@@@@.              #@@@@@@@&      //
//                                         [email protected]@@@@@@@@&     [email protected]@@@@@@@@@[email protected]@@@@@@@@^              [email protected]@@@@@@@5     //
//                                         [email protected]@@@@@@@@&     [email protected]@@@@@@@@@&@@@@@@@@@.               [email protected]@@@@@@@~    //
//                                         [email protected]@@@@@@@@B     :@@@@@@@@@@#@@@@@@@@#                 [email protected]@@@@@@P    //
//                                         [email protected]@@@@@@@@5     [email protected]@@@@@@@@@5&@@@@@@@G                  [email protected]@@@@@&    //
//                                         ^@@@@@@@@@~      &@@@@@@@@@:@@@@@@@@P                   !&@@@@@    //
//                                         [email protected]@@@@@@@&       [email protected]@@@@@@@[email protected]@@@@@@@?                     :~Y?:    //
//                                         [email protected]@@@@@@@J       [email protected]@@@@@@@5:@@@@@@@@!                              //
//                                         [email protected]@@@@@@@J       [email protected]@@@@@@@#[email protected]@@@@@@@~                              //
//                                         [email protected]@@@@@@@!       [email protected]@@@@@@@@[email protected]@@@@@@@^                              //
//                                         [email protected]@@@@@@@:       [email protected]@@@@@@@&[email protected]@@@@@@@.                              //
//                                         [email protected]@@@@@@@        [email protected]@@@@@@@@[email protected]@@@@@@&                               //
//                                         [email protected]@@@@@@G        [email protected]@@@@@@@@[email protected]@@@@@@P                               //
//                                          :[email protected]@@@@.        ^@@@@@@@@@[email protected]@@@@B.                               //
//                                            J#&&~         [email protected]@@@@@@@&  .!7!.                                 //
//                                                           #@@@@@@@&                                        //
//                                                           [email protected]@@@@@J                                        //
//                                                             ~&@@@Y                                         //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SCSM is ERC721Creator {
    constructor() ERC721Creator("Susano Correia", "SCSM") {}
}