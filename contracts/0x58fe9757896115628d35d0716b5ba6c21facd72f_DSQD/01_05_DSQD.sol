// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: defiantsquid
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                    .~~.                                                    //
//                                                .^7JYYYYJ7^.                                                //
//                                            .:!?JYY?~::~?YYJ?!:.                                            //
//                                         :~7JYJJJJ~      ~JJJJYJ7~:                                         //
//                                     .^7JJJJJJJY?:        :?YJJJJJJJ7^.                                     //
//                                 .:!?JYJJJJJJY?^            ^?YJJJJJJYJ?!:.                                 //
//                              :~?JYJJJJJJJJJ?:                :?JJJJJJJJJYJ?~:                              //
//                          .^7JJJJJJJJJJJJJJJ?                  ?JJJJJJJJJJJJJJJ7^.                          //
//                      .:!?JYJJJJJJJJJJJJJJJJJ!                !JJJJJJJJJJJJJJJJJYJ?!:.                      //
//                   .~?YYJJJJJJJJJJJJJJJJJJYP#&.               &#PYJJJJJJJJJJJJJJJJJJYY?~.                   //
//                  :!^^~7JJJJJJJJJJJJJJYPB&@@@J                [email protected]@@&BPYJJJJJJJJJJJJJJ7~^^!:                  //
//                  ^YJ?!^^^!?J?!7?JJ5G&@@@@@@@:                :@@@@@@@&G5JJ?7!?J?!^^^!?JY^                  //
//                  :YJJJJJ7~^.    [email protected]@@@@@@@@@@.                [email protected]@@@@@@@@@@7    .^~7JJJJJY:                  //
//                  :YJJJJJJY?     [email protected]@@@@@@@@@@:                :@@@@@@@@@@@!     ?YJJJJJJY:                  //
//                  :YJJJ77YJY?^^[email protected]@@@@@@@@@@@G                [email protected]@@@@@@@@@@@P7:^7JJY77JJJY:                  //
//                  :YJJY: .^^::~5B&@@@@@@@@@@@@G^            :[email protected]@@@@@@@@@@@@@@GYJ7~: :YJJY:                  //
//           55     :YJJJ?  .?GBG57.~PPPPPB&@@@@@@.           @@@@@@@[email protected]@@P:     7JJJY: :7:        55    //
//          [email protected]@.    ^YJJJ? ^@@J^~JY !&@@@@#[email protected]@@@~            [email protected]@@@GJ#@@@@&P!7J.    .7JJJJY: [email protected]       [email protected]@    //
//          [email protected]@.    .!!?J~ [email protected]  :7!Y&@@&#B##:B&#?         :#5  ?#&G.B&&&@@&#BPY^.:^~7?JJJ77:           [email protected]@    //
//      [email protected]@.   ^77!.  ^[email protected]#~!!7!!..:~!77!.  :: ^77!.  :[email protected]@~~. .~77~. .:^7?7^^^ .~^ ~7 :~. .~.   [email protected]@    //
//    :#@#[email protected]@. [email protected][email protected]&@&[email protected]@7 [email protected]@. [email protected]&#P5&@P 7#@@[email protected]@JJG~ ~&@G5G&@& :@@ .^ [email protected]? [email protected] :#@B55#@@    //
//    @@!    @@[email protected]@YJJY&@7 [email protected] .. #@7 .?5YJ&@! [email protected]   [email protected]@: ^@&   .#@BJ^ [email protected]@.   [email protected]& :@@ .~ [email protected]? [email protected] &@!   [email protected]@    //
//    &@J   ^@@[email protected]&~..:^:  [email protected] !^ #@[email protected]@: .#@! [email protected]?    &@^ [email protected]&     [email protected]&^@@~   [email protected]& [email protected]@: . &@? [email protected] #@?   ^@@    //
//    [email protected]&B##&@. !&&BGB&!  [email protected] ~: [email protected]~ [email protected]#@! [email protected]?    &@: .&@##P:#[email protected] [email protected]#BB&@&  [email protected]@BB##@7 [email protected] [email protected]&B##&@    //
//       :^:  .    .^~^..^..:.   .^~:~ ^~~: .  :.     ^^:?  ::. :::^::^55 ^[email protected]& ...^~^..:   .     :^:  .    //
//                  :[email protected]@@@@~#@@@P.    .:   [email protected]@#   .. .  [email protected]@@&[email protected]@& ^@& .Y?777?JJ:                  //
//                  :YJJJJJJJ^!YJYG#&G~:J??7.   ^P?P  [email protected]@?  5?P~   .!??J:^G&B [email protected]& .JJJJJJJY:                  //
//                  :YJJJJJJJJJJJJ?.  ..^. .~~  :[email protected]&  [email protected]@7  #@G:  ^~. .^..  . .?! ^JJJJJJJY:                  //
//                  :YJJJJJJJJJJJY: .?JYY5PB5   #@@7  #@@#  [email protected]@#   YBP5YYJ?. :7~~7JJJJJJJJY:                  //
//                   :~?JYJJJJJJJJ. ?JJJJ7^.  :[email protected]&^ :#@@@@#: ^&@#:  .^7JJJJ? .YJJJJJJJYJ?~:                   //
//                      .:!?JYJJJ?:7JJJ7. .:!?JYY. [email protected]@&GG&@@5 .JYJ?!:. .!JJJ7:7JJJYJ?!:.                      //
//                          .^7JYJJJJJJ ^?JYJJJJ^ ~5P~    ~P5~ ^JJJJYJ?^ JJJJJJYJ7^.                          //
//                              :~?JYJJ!JJJJJJJJ7 ~J?.    .?J! 7JJJJJJJJ!JJYJ?~:                              //
//                                 .:!?YYJJJJJJJJ7^?J?!..!?J?^7JJJJJJJJYY?!:.                                 //
//                                     .^7JJJJJJJJJJJJY^^YJJJJJJJJJJJJ7^.                                     //
//                                         .~7JYJJJJJJY::YJJJJJJYJ7~.                                         //
//                                            .:!?JYJJY::YJJYJ?!:.                                            //
//                                                .^7JY^^YJ7^.                                                //
//                                                    :..:                                                    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DSQD is ERC721Creator {
    constructor() ERC721Creator("defiantsquid", "DSQD") {}
}