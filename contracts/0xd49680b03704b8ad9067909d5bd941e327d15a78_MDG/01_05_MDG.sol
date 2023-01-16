// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MARYLAND DRONE GUY
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                            //
//                                                                                                                                            //
//    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //
//    //                                                                                                                                //    //
//    //                                                                                                                                //    //
//    //                                                                                                                                //    //
//    //                                          !!                                       .J.                                          //    //
//    //                                        ^[email protected]                                      !&&?.                                        //    //
//    //                                     .J&@5.                                          ~#@B~                                      //    //
//    //                                   [email protected]#7                                               :5&&5.                                   //    //
//    //                                .Y&#?.                                                    ^P&#~.                                //    //
//    //                             ^[email protected]@#:                           .:.                            [email protected]@&J.                             //    //
//    //                         [email protected]&@@@:                      .7#@@@@@@@&5~                       [email protected]@&@&5Y?:                         //    //
//    //                      :[email protected]@@@@@[email protected]@@G                     [email protected]@@@@@@@@@&&P                     :@@@B&@@@@@#7                       //    //
//    //                    ^[email protected]@@@@@&&&@@@@@@@&BP?~:.          .G&[email protected]@@@@@@@@@[email protected]!.          .^7YG#&@@@@@@@&&&@@@@@@Y.                    //    //
//    //                  ~#@@@@&G7. #@@&BB#&@@@@@@@@@&B5?~: 7&@@P&@@&[email protected]@@P&@@#..^!JP#&@@@@@@@@@&#B#@@@7 ^Y#@@@@@5.                  //    //
//    //    :[email protected]         [email protected]@&G?:      ..     .^75#&@@@@@@@@@7&@@@[email protected]@@@@&@@@@@[email protected]@@[email protected]@@@@@@@@&GJ~.     .:.     .~5#@@@~        :&@J     //    //
//    //    :[email protected]@@P^      ^J~                       .^?P#&@@@[email protected]@@[email protected]@@@@@@@@@@&[email protected]@#7#@@@&BY!:                       .J?.     .?#@@@J     //    //
//    //      [email protected]@@&5:                                   .^J&@@@#[email protected]@@@@@@@@@@@[email protected]@@@G!:                                   [email protected]@@#!       //    //
//    //         [email protected]@@&J.                          .::^[email protected]@@@[email protected]@@@@@@@@@@@[email protected]@@@@!PY7~^:.                           [email protected]@@&5:         //    //
//    //           .~5&@@#!.                .:!JP#&@@@@@@@Y#@@@@[email protected]@@@@@@@@@@@[email protected]@@@@J&@@@@@@@&B5?~:                 :[email protected]@@B?:            //    //
//    //               ^&@@@G^       .^7YG#@@@@@@@@@@@@@@@[email protected]@@@@Y#@@@@@@@@@@@@J&@@@@[email protected]@@@@@@@@@@@@@&#PJ!:.      .?&@@@5.               //    //
//    //               [email protected]@@@@@@@@&PG&@@@@@@@@@@@@@@@@@@@G^:@@@@@Y#@@@@@@@@@@@@J&@@@@P.?#@@@@@@@@@@@@@@@@@@&BPB&@@@@@@@@&.               //    //
//    //               [email protected]@@&@@@@@@@@@&&@@@@@@@@&#G5?!^.   .GGB#&?#@@@@@@@@@@@@J#&#BG?   .:~7JPB#&@@@@@@@&&&@@@@@@@@@&@@@^               //    //
//    //               [email protected]@@#&@@@@@@@@@@&#Y~^..             ~&^.5GG###########BPB~.J#              .:^7B&@@@@@@@@@@@#&@@@                //    //
//    //              .&@@@@@@@&BB&@@@@@@&J.                ^!Y#&#GGPGGGGGGPGB#&G7~:                ^[email protected]@@@@@@&G&&@@@@@@@J               //    //
//    //               #@@@@@&B!   .~YB&@@@B                     [email protected]#&@@@@@@#@B.                    ^@@@@&P?^.  .Y&@@@@@@7               //    //
//    //                [email protected]@@P           :?^                      :@#@@@@@@@#@B                      .!!.          [email protected]@@&:                //    //
//    //                 [email protected]@@:                                   ^@[email protected]#                                    [email protected]@@.                 //    //
//    //                  #@@&                                    ?J&     !#?~                                   [email protected]@@!                  //    //
//    //                  [email protected]@@Y                                     !!~~~~7:                                    .&@@P                   //    //
//    //                   [email protected]@&.                                                                                [email protected]@&                    //    //
//    //                    ::                                                                                   .^.                    //    //
//    //                                                                                                                                //    //
//    //                                                                                                                                //    //
//    //                                                                                                                                //    //
//    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //
//                                                                                                                                            //
//                                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MDG is ERC721Creator {
    constructor() ERC721Creator("MARYLAND DRONE GUY", "MDG") {}
}