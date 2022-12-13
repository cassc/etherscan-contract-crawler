// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OUCH!
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                              .                                                                                           //
//                                            .P&P.                                                                                         //
//                                            [email protected]@@B.                                                                                        //
//                                   :~.     .&#[email protected]                                                                                       //
//                               !55P&&:     [email protected]? :#@G                                                                                       //
//                        :      [email protected]@@@B    :[email protected]@^  ^@@G^                                                                                     //
//                       !&^     #@@@@#.   [email protected]@&:  .#@@@^                                                                                    //
//                     [email protected]@B.    [email protected]@@@@!   [email protected]@&:  ~&@@B.                                                                                    //
//                      [email protected]@B~   [email protected]@@@B.  [email protected]@@^ ^&@@#^                                                                                     //
//                       [email protected]@@5^  [email protected]@@@P  [email protected]@@:~&@@B:                 :^^:.                                                                //
//                 :5~     [email protected]@@P!  ?&@@@G..#@@5&@@@GYY5P5Y7.        J#&@@@&G?:                                              ..:^^!~        //
//                 [email protected]@BY~.   ~5&@@#J::Y&@@#[email protected]@@@@@@@@@@@@@@5      [email protected]@@B!^[email protected]@&?                                          ~PB#&&@@G^        //
//                  #@@@@#P?^. .!5#@@[email protected]@@#@@@@@@@@@@@@@@@&JJJ?~:[email protected]@@&:  [email protected]@@@~                      :~7?J5PP.         [email protected]@@@@@@J          //
//             !??JJ&@@@@@@@@&[email protected]@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@J  :#@@@@P                     .#@@@@@@5        [email protected]@@@@@&!           //
//            :&@G?JYYYYYYJJYYPB&@@@@@@@@@@@@@@@@@@@@@@@@P7?YG#@@@@@@@@! [email protected]@@@@B                     [email protected]@@@@@@~       [email protected]@@@@@P:            //
//             ^P&P7:            [email protected]@@@@@@@@@@@@@@@@@@@@@@G!.   ^[email protected]@@@@[email protected]@@@@@5                     [email protected]@@@@@#.      [email protected]@@@@@J              //
//               ^[email protected]@#PJ!^..   :7#@@@@@@@@@@@@@@@@@@@@@@@@@&GY7^[email protected]@@@@@@@@@@@&^                     [email protected]@@@@@5       [email protected]@@@@&!               //
//                ?#@@@@@@&#BB#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#&@@@@@@@@@@@G^                      [email protected]@@@@@!      [email protected]@@@@&~                //
//                  ^?5B#@@@@@@@@&#B#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#Y^               ..      .#@@@@@&.     [email protected]@@@@&~                 //
//              PP7^.    :^~!!777J5B&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#GJ~.             ^JP###BGY~  .&@@@@@P     [email protected]@@@@!                  //
//             :&@@@#BP5J??JY5PB&@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@#BPJ!^.               ^[email protected]@@&BB#@@P. :&@@@@@?     [email protected]@@@@Y                   //
//             ^&@@@@@@@@@@@@@@@@@@@&[email protected]@@@@@@@@@@@@@@@@@@&GY7^.           .^!JJ.   ~&@@#!.   ^^   :&@@@@@!     [email protected]@@@&.                   //
//             .?5G#&@@@@@@@@@&#G5?!~7P&@@@@@@@@@@@@@@@@&BY!:           .^^  [email protected]@@@5  .#@@&^          .&@@@@@[email protected]@@@@J                    //
//                  .:^^~~~^^:..:~JG&@@@[email protected]@@@@@@@@@@B5!:             ^P#@&^ [email protected]@@@7 [email protected]@@P            #@@@@@@@@@@@@@@@@^                    //
//               :!~^^^^^~!7?5G#@@@@@#[email protected]@@@@@@@@B7:        :?PBBP?. [email protected]@@@P  [email protected]@@@B [email protected]@@P            [email protected]@@@@&@@@@@@@@@B                     //
//                [email protected]@@@@@@@@@@@@@&GJ~:?#@@@@@@@@@&:         J&@[email protected]@B:.#@@@&. .&@@@@:[email protected]@@&:           [email protected]@@@@?:~7J&@@@@P                     //
//                ^@@@@@@@@&#G5?~. ^Y#@@@GJ&@@@@@B         [email protected]@&.  [email protected]@? [email protected]@@@5 [email protected]@@@@: [email protected]@@5           [email protected]@@@@J    [email protected]@@@5                     //
//                .????77~^.   [email protected]@@@B!7&@@@@@@#!!~:     [email protected]@@J:!&@@~  [email protected]@@@#@@@@@B  [email protected]@@@5.         [email protected]@@@@G    [email protected]@@@5                     //
//                       .:~?5B&@@@@&P~:[email protected]@@&@@@@@@@@&~?~  !&@@@@@@#7    [email protected]@@@@@@#~   [email protected]@@@&Y!^~JJ   [email protected]@@@@&:   [email protected]@@@G                     //
//                    :[email protected]@@@@@@@#P7..?&@@&[email protected]@@@@@@@@[email protected]  .~!77!^.       ^7JYJ?!.     ~P&@@@@@@@@J  [email protected]@@@@@!   [email protected]@@@&.                    //
//                      ^G#BGPY7^. ~5&@@#Y:[email protected]@@@@@@@@@&&@5                                :?P#&@@&BJ  ^@@@@@@J   [email protected]@@@@7                    //
//                               [email protected]@#5! [email protected]@@@@@@@@@@@@@57~^.                               .:^^.    .&@@@@@Y   [email protected]@@@@B                    //
//                                .^^  ~5&@@@@@@@@@@@@@@@@@@@&BP5?^                                    Y#&@@@?   .#@@@@@?                   //
//                                    .7PB&@@@@@@@@@@@@@@@@@@@@@@@@P.                                    .^~7:    [email protected]@@@@@~                  //
//                                        .^~7J5G&@@@@@@@@@@@@@@@@&Y                                              .:^!7J5J                  //
//                                               .~75G#&@@&#BGPYJ!:                                                                         //
//                                                    .::^:.                                                                                //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract OUCH is ERC1155Creator {
    constructor() ERC1155Creator("OUCH!", "OUCH") {}
}