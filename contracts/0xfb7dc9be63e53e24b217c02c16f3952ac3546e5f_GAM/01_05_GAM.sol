// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Genart Memes
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                    ~YB&@@@#P?:                                             //
//                                                  [email protected]@@@@@@@@@&Y.                                           //
//                                                 [email protected]@@@@@@@@@@@@@#~                                          //
//                                                [email protected]@@@@@@@@@@@@@@@@7                                         //
//                                               ^@@@@@@@@@@@@@@@@@@@!                                        //
//                                               [email protected]@@@@@@@@@@@@@@@@@@&^                                       //
//                                              [email protected]@@@@@@@@@@@@@@@@@@@@G                                       //
//                                             .#@@@@@@@@@@@@@@@@@@@@@@J                                      //
//                                             [email protected]@@@@@@@@@@@@@@@@@@@@@@@^                                     //
//                                            .#@@@@@@@@@@@@@@@@@@@@@@@@G                                     //
//                                            [email protected]@@@@@@@@@@@[email protected]@@@@@@@@@@@7                                    //
//                                            [email protected]@@@@@@@@@@&.:&@@@@@@@@@@@#.                                   //
//                                           [email protected]@@@@@@@@@@@5  [email protected]@@@@@@@@@@@J                                   //
//                                           [email protected]@@@@@@@@@@@~  .#@@@@@@@@@@@&:                                  //
//                                          .#@@@@@@@@@@@B    [email protected]@@@@@@@@@@@Y                                  //
//                                          [email protected]@@@@@@@@@@@?     [email protected]@@@@@@@@@@&:                                 //
//                                          [email protected]@@@@@@@@@@&:     [email protected]@@@@@@@@@@@Y                                 //
//                                         :&@@@@@@@@@@@P       [email protected]@@@@@@@@@@&:                .~JPBBBGY~      //
//                                         [email protected]@@@@@@@@@@@7       [email protected]@@@@@@@@@@@5               ?#@@@@@@@@@G:    //
//                                         [email protected]@@@@@@@@@@&.        [email protected]@@@@@@@@@@&:            [email protected]@@@@@@@@@@@B    //
//                                        :&@@@@@@@@@@@P         [email protected]@@@@@@@@@@@Y           [email protected]@@@@@@@@@@@@@#    //
//                                        [email protected]@@@@@@@@@@@!          [email protected]@@@@@@@@@@&:        [email protected]@@@@@@@@@@@@@B~    //
//                                        [email protected]@@@@@@@@@@&.          [email protected]@@@@@@@@@@@Y       :[email protected]@@@@@@@@@@@@G7.     //
//                       :75GBBG57:      :&@@@@@@@@@@@P            [email protected]@@@@@@@@@@&:     ^#@@@@@@@@@@@@@?        //
//                     :5&@@@@@@@@&J     [email protected]@@@@@@@@@@@!            [email protected]@@@@@@@@@@@Y    ~&@@@@@@@@@@@@#~         //
//                    ~#@@@@@@@@@@@@P    [email protected]@@@@@@@@@@&.             [email protected]@@@@@@@@@@&:  [email protected]@@@@@@@@@@@@B:          //
//      :7YPP5J!.    [email protected]@@@@@@@@@@@@@@Y  :&@@@@@@@@@@@P              [email protected]@@@@@@@@@@@Y [email protected]@@@@@@@@@@@@P.           //
//    [email protected]@@@@@@@#7  [email protected]@@@@@@@@@@@@@@@@~ [email protected]@@@@@@@@@@@7               [email protected]@@@@@@@@@@&[email protected]@@@@@@@@@@@@5             //
//    [email protected]@@@@@@@@@@5~&@@@@@@@@@@@@@@@@@B [email protected]@@@@@@@@@@&:               [email protected]@@@@@@@@@@@@@@@@@@@@@@@@Y              //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Y#@@@@@@@@@@@P                 [email protected]@@@@@@@@@@@@@@@@@@@@@@J               //
//    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@7                 [email protected]@@@@@@@@@@@@@@@@@@@@@7                //
//     !#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&:                  [email protected]@@@@@@@@@@@@@@@@@@&!                 //
//      .Y&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G                   ^&@@@@@@@@@@@@@@@@@#^                  //
//        :Y&@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@?                    [email protected]@@@@@@@@@@@@@@@G:                   //
//          :[email protected]@@@@@@@@@@@G^[email protected]@@@@@@@@@@@@@@@@@@@&:                     [email protected]@@@@@@@@@@@@@J                     //
//             ~JG&@@@@@&G7  [email protected]@@@@@@@@@@@@@@@@@@@P                       J&@@@@@@@@@@G~                      //
//                .^~!!^.     [email protected]@@@@@@@@@@@@@@@@@@7                        :JG&@@@&BY~                        //
//                            [email protected]@@@@@@@@@@@@@@@@@&.                           .:^:.                           //
//                             [email protected]@@@@@@@@@@@@@@@@5                                                            //
//                             ^@@@@@@@@@@@@@@@@@^                                                            //
//                              [email protected]@@@@@@@@@@@@@@P                                                             //
//                              [email protected]@@@@@@@@@@@@@^                                                             //
//                               ^&@@@@@@@@@@@@J                                                              //
//                                ^[email protected]@@@@@@@@&?                                                               //
//                                  !P#@@@&GJ:                                                                //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GAM is ERC1155Creator {
    constructor() ERC1155Creator("Genart Memes", "GAM") {}
}