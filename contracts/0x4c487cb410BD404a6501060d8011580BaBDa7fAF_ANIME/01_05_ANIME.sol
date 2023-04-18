// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Animania
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                  ^~^:                            .~^^                                                      //
//                  .~?5Y?!.                        .:7J5J?:                        .....                     //
//                  !BGPGBG~                        :PBGPGB?                       .::^!~.                    //
//               ...!GGPPGG!                        ^GGP5GBJ.                     :~^^:~!^                    //
//            .:::~~:YP?JGJ:!:.                     :YGJ?5G7.                     ^!!^:^7!                    //
//            ::::7J!755PY?!Y!::                  .~!7YG5P7~^.                   :^^!JJ!~^:                   //
//            :..^!Y5YGGGGY5Y7!!:                :YGGYPGGGPYP?                 .7Y?~!!77?JJ!                  //
//            :^!Y5GY5BBBBPP5YYY~^.            .!5P55JB#B#GYP?:               ^JYY?7777?JYY7:                 //
//            !Y5?Y5PPGBBBBGY5PP5Y?           .?5?7~?PGBBBBG7?!:            .!?7!^7YJJ77JJ7?!.                //
//           !PGPJYY55YYYYPYY555YY?.         :JPP7: :Y5Y5Y57.~J?:          ^JP5!. :JJ7??J~ !Y7:               //
//         .!PBG5YYYJYJ??75PJY5577!^.       ^YG57:  ^JY??7J5~.7J!^        ~5GY7.  ~JY??7YY^.??!^              //
//        ~YG5YYJJJ7^!?J?5GG5J5P?~!J7.    :JP?^.   :^~?JJYPG5: :!7:     ^JP7^.   :^!?J?YPGY..:!!.             //
//       !BPJJJJJJYJJ55YY5YGBYYPY^~!7~   :PB!     :JJY55Y55PBJ: .!!:   ^GG~     ^JJY55Y5YPB?. .!!.            //
//      .JP7?JJJJJJ~^7?!7JPBBPJP5^^^~~:  !PJ.     .!^!??~JYBBP^  ~?!   7P?.     :~^!?7~J5BBP:  !?~            //
//       ...???????^.:~^?PBBP~^Y5?^^^^^   .        ^..:!^PGBB7.  :~^   ..        ^..^!~PGBG!.  ^!^            //
//         .??7!~^:^..^^JGGP!  ?PY:::..            ::..~~GGGJ.                   ::.:~!GGG?.                  //
//         .^..    :^:~~YP55^  ~J7:.               .^:^!7G557                    .^:^!?P55!                   //
//                 .7~??G#BP.                       !!7?Y&BB~                    .!~7?5&BG^                   //
//                 .~!??BBGJ.                       ^!7?5#GP:                     ~!7?P#G5:                   //
//                 :!!??B#G5:                      .~!7?5#GG!                    .~!??P#GP~                   //
//                  ^!?!P#GJ                        :~???#GP:                     :!?7Y#G5.                   //
//                  ^!??G#G!                        :!7?5#BY                      :!??P#BJ                    //
//                  :~7?B#G:                        .^!?P#B!                      .^7?G#B~                    //
//                   ^7?BB7                          :!?5#5.                       :!?PBJ                     //
//                   :7JBP:                          .!?PB!                        .!JGB~                     //
//                   :7J#P:                           !?G#!                        .!?BB^                     //
//                   :!?BB^                          .~7P&?                        .~7G&7                     //
//                   ^!7G#?                          :~!5#P.                       :!!P#Y                     //
//                   .:.:~.                           :..~^                        .:..~:                     //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ANIME is ERC721Creator {
    constructor() ERC721Creator("Animania", "ANIME") {}
}