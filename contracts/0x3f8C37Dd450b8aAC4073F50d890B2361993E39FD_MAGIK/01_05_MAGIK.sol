// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GoodMagik_deployer
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                           //
//                                                                                                                                                                           //
//                  .....                                                                                      .....                                                         //
//             :[email protected]@@@@@@@5!:::::.               :^!7777!~^.                  :^!7777!~^.              .:::::[email protected]@@@@5?~.                                                     //
//          ^JG&@@@@@@@@@@@@@@5::.            [email protected]@@@@@@@@@@&GY!.          [email protected]@@@@@@@@@@&GY~          .::[email protected]@@@@@@@@@@@@&P?:                                                 //
//        [email protected]@@@@@@BJ~:[email protected]@@5:.         :?G&@@#5J77?YP#@@@@@@#J:      [email protected]@@#5?77?YG&@@@@@@BJ:       .:[email protected]@@~...:!Y#@@@@@@&P~                                               //
//      [email protected]@@@@@@5~        [email protected]@@B!      ~P&@@@B!.       [email protected]@@@@@&Y.   [email protected]@Y^        [email protected]@@@@@&J.      [email protected]@7       [email protected]@@@@@@P^                                              //
//     [email protected]@@@@@@B~            [email protected]@@@    :[email protected]@@@@Y             [email protected]@@@@@#[email protected]@5.             !#@@@@@@B^     @@@5            7#@@@@@@&7                                            //
//    [email protected]@@@@@@5              [email protected]@@@   !&@@@@@J                [email protected]@@@@@@[email protected]@G.               [email protected]@@@@@&^    @@@Y             :[email protected]@@@@@@?                                           //
//    [email protected]@@@@@@5              :[email protected]@@   [email protected]@@@@@P                  [email protected]@@@@@@5?                  ^[email protected]@@@@@G   @@@5              [email protected]@@@@@@^                                          //
//    [email protected]@@@@@#.              :&@@@  :&@@@@@@^                  :&@@@@@@@?                   ^&@@@@@@^  @@@G               [email protected]@@@@@@?                                          //
//    [email protected]@@@@@5               [email protected]@@@  [email protected]@@@@@#.         .75G!     [email protected]@@@@@@?        .!YGBGG:    [email protected]@@@@@!  @@@@7               #@@@@@@Y                                          //
//    [email protected]@@@@@Y             ^[email protected]@@@@  [email protected]@@@@@B        ^J5 [email protected]&.    [email protected]@@@@@@J      .J&@  7Y5:    [email protected]@@@@@!  @@@@@Y:             [email protected]@@@@@5                                          //
//    [email protected]@@@@@J        [email protected]@@@@@@  [email protected]@@@@@G      ~YJ!  @#7     [email protected]@@@@@@J      [email protected]###5J^      [email protected]@@@@@7  @@@@@@@GY?~         [email protected]@@@@@5                                          //
//    [email protected]@@@@@J                      [email protected]@@@@@G      GBG##P7.      [email protected]@@@@@@Y                    [email protected]@@@@@7                      [email protected]@@@@@P                                          //
//    [email protected]@@@@@J                      [email protected]@@@@@P                    [email protected]@@@@@@5        ^7YGGG      [email protected]@@@@@?                      [email protected]@@@@@P                                          //
//    [email protected]@@@@@Y        [email protected]&@@@@@@@  [email protected]@@@@@P       .7YYJ#@5     [email protected]@@@@@@5      :5&   ?PY     [email protected]@@@@@?  @@@@@@@&[email protected]^        [email protected]@@@@@5                                          //
//    [email protected]@@@@@5         [email protected]@@@@  [email protected]@@@@@P     .JY?  &@P:     [email protected]@@@@@@P      [email protected]  J5?:      [email protected]@@@@@7  @@@@@P!~?Y~         [email protected]@@@@@5                                          //
//    [email protected]@@@@@G           [email protected]@@@  [email protected]@@@@@#.    ^BGB#GJ^       [email protected]@@@@@@B      [email protected]!.        [email protected]@@@@@~  @@@@J!Y?^          .#@@@@@@Y                                          //
//    [email protected]@@@@@&.            ^BJ&@@@  [email protected]@@@@@@J                  ^[email protected]@@@@@@@7                  [email protected]@@@@@&:  @@@BYG:            [email protected]@@@@@@?                                          //
//    [email protected]@@@@@@Y             [email protected]@@  [email protected]@@@@@@7                 [email protected]@[email protected]@@@@@&!                [email protected]@@@@@Y   @@@PG~            [email protected]@@@@@@~                                          //
//    [email protected]@@@@@@Y            [email protected]@@   [email protected]@@@@@@J               [email protected]@5 [email protected]@@@@@@@?             ^[email protected]@@@@@P.   @@@5G~           :[email protected]@@@@@@5                                           //
//     [email protected]@@@@@@B~          [email protected]@@     [email protected]@@@@@@B~           ^[email protected]@7.  [email protected]@@@@@@G~          :Y&@@@@@&J     @@@YP!          7#@@@@@@@Y                                            //
//       J&@@@@@@@P~       :[email protected]@@P!      ^[email protected]@@@@@@G7:     :[email protected]@@G.    [email protected]@@@@@@P!.     ~Y&@@@@@&5^      [email protected]@@P       [email protected]@@@@@@B!                                             //
//        :J#@@@@@@@BY!^:[email protected]@@!:.        ^[email protected]@@@@@&GYJ5B&@@@@P.       ~5#@@@@@@&PJJ5#@@@@@@BJ:        .:[email protected]@@G?^:^!5#@@@@@@@B7                                               //
//          .!5#@@@@@@@@@@@@@!:::.           ^?PB&@@@@@@@@@#P!           .~JP#&@@@@@@@@@#PJ^           .:::!B&@@@@@@@@@@@#Y~                                                 //
//             .~JP#&@@@@@GY!::::.               :^!7777!~^.                 .:~!7777!~^.              .::::[email protected]@@@@@@P?^                                                    //
//                  .....                                                                                       .....                                                        //
//                                                                                                                                                                           //
//                                                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MAGIK is ERC721Creator {
    constructor() ERC721Creator("GoodMagik_deployer", "MAGIK") {}
}