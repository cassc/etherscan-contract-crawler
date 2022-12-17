// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: V3RSUS - R3MNANTS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                      !?                            .:^~7J5Y.   ..                            //
//                                   .~.                                               [email protected]&^      :         :7    ~7?Y5GB#&&&&P. .JG7                            //
//                                .!YB&!             .       :YG:   :        .~       ~#&@?    :7B~      .?GB..!5#&&&&&G5?!~:   J&#~                            //
//                             :[email protected]     ~5~   ^YG^     :[email protected]@! :Y#Y      .P#:      5&&&5    [email protected]@G      :G&#::?J7!:?&&~       !#@J                             //
//                          ^?PBGJ^7#P.   .?G&@~   [email protected]@B^    Y&#&J ~&@@J     :B&~     .P&&&G    [email protected]&@J     :P#&^      ?&&~      ^[email protected]                             //
//                       .7P#&7:  7&P.   [email protected]    Y&&&B:  7&BB&Y ~#&&&~    ^#&!     ^B&&&#.   ?&&&#:    :G#&^      Y&&:     .5&&!                              //
//                      :JJ7B&~  [email protected]   !GG~^##^    J#&&&P [email protected][email protected] ^#&&&G.   ~B&!     ~#&&&&~   ~#&&&J    ^B&#:      5&#:     7&&?                               //
//                         .G&7 [email protected]   :J!  5&7 :~J^?&&B&@J7&B:[email protected] ^#&&&&J   ~#&7     J&&B#&J   :G&&&#:   ~#&#:     .P&#.    ^[email protected]::^~~~!~^                       //
//                         .P&PY&?        7&#JG#&@?7&&JP&&#@J [email protected] :B&GB&&!  ~#&7     5&&YB&G   .P&&#&Y   ~#&#:     .G&B.   .5&&GGB#&&###5     ^                 //
//                          5&&@G        :[email protected]&&^!&@?:#@@#: [email protected] :[email protected]?&&B. ~#&?    :G&&!B&#:   Y&&#&&~  ~#&&:     :B&G    ?&&&#BP5JJB&#~   :YG.                //
//                    :~    [email protected]&&&7       .~~.  [email protected] ~B&J ~GB?  J#P .G&Y.G#&J ~#@Y    ~B&B.Y&&7   J#&5B&G  ^#&&^     .G&G    ^7~^:    7#&Y   ^5&J                 //
//                  .!5G.   ?&&&&#:           :[email protected] ~#@Y       ?#P  Y#5 !#&#^~&@5    7#&5 !#&P   7#&7?&&7 :B&&~     :[email protected]            ^G&#^   J&P.   :7.           //
//                  .?P#!   !&&##&P           ^#@7 ^B&5       7#P  Y#5  J#&5:B&P    J#&? ~#&#:  !#&J G&B..G&&~     :[email protected]            ?#&Y   !B#^   !GY            //
//               ..  ~5#5   ^#@B5&@?          !##: :[email protected]       7#G  J#5  :G&&7P&G   .P&&PG##&&7  ^#&5 7&@? 5&&~     :[email protected]           :P&B:  :P&?   ~BP.            //
//              ^J?  .YGB:  [email protected]^G&#^         ?&G  :[email protected]       7#G  J#P   !#&BP&G   ^B&&P?^7&@5  :G&P  [email protected]#.?#&!     :[email protected]           7#&Y   7BG.  ^G5.             //
//              :?Y^  75B7   [email protected]#:!&&P        .5&Y  :[email protected]       7#G  J&G    5&&B&B.  !&@G   :B&B.  P&G  !#&?!&&7     [email protected]          .5#B^  ~BB~  .?7               //
//               !5?  ~5PP   [email protected]&^ J&&7       :B&!  [email protected]       7#B. ?#G    ^B#&&#:  J&@Y    P&&~  5&B.  Y#G?#&J     .G&?          !B#Y   ^!:    .                //
//               .JP: .YG#^  ~&&! .P#B:      !##:  [email protected]      7#G. ?&B     ?&&&&^  P&@!    ?&@J  ?&#:  ^B#PG&5     .G&?          ?BB~                           //
//                ^J^  ~YJ:  ^#@J  :G&5      J&B.   [email protected]      ?&G  J&B.    .P&&@7 :B&&:    ^#&G  7&&^   ?##G#P     .G&?         ^P#5                            //
//                           :B&Y   ~B&7     [email protected]    [email protected]      ?&B  J&B.     ^B&@J ~#@G      P&&^ !&&~   .P###G.    :B&?         7##^                            //
//                           .P&P    ?#B^   :G&?    Y&B.      ?&B  J&B       7&@5 7&@Y      ?&@? ~#@!    ~B#&B.    :G&7        :P&J                             //
//                            5&B.    5#5   ^B&~    J&B       [email protected]  J&G       [email protected] 7&@7      :B&P :[email protected]     Y&&#:    :G&7        !BG.                             //
//                            Y&#:    ^##!  !##:    Y&G       ?&G  7&P        [email protected]#.7&#:       5&#: [email protected]     [email protected]#:    :[email protected]       .YB!                              //
//                            !#&^     !BB: [email protected]     Y&Y       J&B  :BY        .5P.7G7        !&@! 5&7      :G&:    :#@~       !G?                               //
//                            ~B&~      !Y: [email protected]?     ?&!       ?&B.  ^:                        J5: ?&~       ~G:     ??       .Y5.                               //
//                            .GG:          :~      ^J.       7&5                                 :7.        .               :J^                                //
//                             ..                              :                                                             ..                                 //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                            .:^^^::                                                                           //
//                                                                           ^!!77777~.                                                                         //
//                                                                          ^?JJJ??JJY?:                                                                        //
//                                                                         :?P5JJJJJJ5P7                                                                        //
//                                                                        .7PPP5JJJJYPG5^                                                                       //
//                                                                        ~5PYPGP555GGPG5^                                                                      //
//                                                                       ~5P5JJPBGGBG5Y5P5~                                                                     //
//                                                                      ~5PYYJJYG##G5JJYYP5!                                                                    //
//                                                                     ^5PYYJJJYPGGP5YJJJYPP!                                                                   //
//                                                                    ^5PYJJJJ5PY~^JP5YJJJYPP7                                                                  //
//                                                                   :5GYJJJY5PJ:  .7PPYJJJY5P7                                                                 //
//                                                                  .YPYJJJYP5!.     ~5PYJJJY5P!                                                                //
//                                                                 .JGYYYY5PY^        ^YPYJJJY5P!                                                               //
//                                                                 ?PYJYY5P?.          :JP5YJJYPP!                                                              //
//                                                                7P5YJYP5~             .?P5YYYY5P7                                                             //
//                                                               ~P5YY5PJ:                !PPYYJJ5P?.                                                           //
//                                                              ^P5YY5P7.                  ^YP5JJJYPY:                                                          //
//                                                             ^55YJ55~                     .?P5YJJYP5^                                                         //
//                                                            :55JYPY^                        ~5PYJJY55~                                                        //
//                                                           :Y5JYPJ.                          :?P5YJJ5P~                                                       //
//                                                          .Y5JYP7                              ~5PYJJ5P~                                                      //
//                                                         .J5JY5~                                .?P5JJ5P~                                                     //
//                                                         ?5JYY^                                   ~55YJ5P~                                                    //
//                                                        ?5J5J.                                     :YPJJYP~                                                   //
//                                                       ?5J5?                                        .?5YJY5!                                                  //
//                                                      7YJ57                                           ~55JJ5!                                                 //
//                                                     7YJY~                                             :J5JJ5!                                                //
//                                                    !YJY^                                                75YJ5!                                               //
//                                                   ^YJY^                                                  ^YYJ5!                                              //
//                                                  :JJJ:                                                    .?YJY!                                             //
//                                                 .?JJ:                                                       ~JJY?.                                           //
//                                                 7JJ:                                                         .7JJ?:                                          //
//                                                ^J?:                                                            ^?JJ:                                         //
//                                               .??:                                                               ~??:                                        //
//                                               77.                                                .......::.....:..^?J^                                       //
//                                              ~?:.::::::::^^^^~~~~~~~~~~^^^^^^^~~~~~!!!!77????JJJJYYYYYYYYYYYYYYYYYY555!                                      //
//                                              ^^^~~!!!!77777???77??????JJJJJYJJYYYYYYYYYYYY5555555YY5555Y555YYYYYYY5YJ?!                                      //
//                                                                        ....:::::::::::::::^^^~~~~~~~~~^^^::::::::::::.                                       //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract P5KVR is ERC1155Creator {
    constructor() ERC1155Creator("V3RSUS - R3MNANTS", "P5KVR") {}
}