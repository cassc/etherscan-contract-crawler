// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Surgery on the state of art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                        !7~YYY.                                             //
//                                                  .:^:7PJ!~YJ5GY                                            //
//                                                :GPB&&G5!75&&5YG                                            //
//                                             .~YG&BG&GJ~?J7&@G!J.                                           //
//                                      ..:7~P##GY7BPG57!JB&[email protected]@&GJ~^                                         //
//                                  :.^PYB&@B#GBG#BBG7?JG&&&BB&5G#GGBPP5~..                                   //
//                              :!?B#PB#&P&&&&&&PGJ?~Y&&B#G5B###&GB&##&&B5YY5?.                               //
//                           7?5BB~#P&#BGB&GG#B5PG5#&B&P#BJGB&@GBP&BGPYGGGYJPGG5J^.                           //
//                       .~?J#J#5B?#?BP5#?J:Y?J7PG&5&&&&@&#@&B&PJ~YJJYP#7YY?J7YGPJY?~                         //
//                    .!YG&5&?GYYJ.##J5YGPP775.7PBB#@@@@@@@@@#P. . .~7YY5&BB?PJY#PYP!5?^                      //
//                  [email protected]#?##G?J~7^..:^~B^JYBBG#@@@@@@@@P?        .:~J5?J5PYPY5?BYP?~                    //
//                7!?J##P#?5G?JP5^?:~        .~5~YBY5#&@@@&@@#P             .~JY:5JP55YY?BJ:                  //
//              ^G?JY?GJ?#7BJ:^~7.              ..:[email protected][email protected]@@P                .~!P7JBPJP?YG5.                //
//             5JG!J?YJJ^B?:7^^                      7!??J7BPPP:                  .!?7?G?P5J#P^               //
//           ~GP?P75!B^5J:J^~.                         !BY75YY5Y~~^.                 JP7BPPPG55?              //
//          Y5P:?5^#7^G:7P?                              . ..:.  .:!J:                ^GY5PPPG?5J.            //
//        .5G^77^Y5!#B??J.                                         .~5.                 G5^BJ!P?PP.           //
//       .5^^?:?775#J^J?.                                           ^?!                  P?^P5PG7BB.          //
//       J?7^P^.P?B?.~?                                            ~Y7:                   G?^PYJYJBP.         //
//      !J^?! ^J:G7 ??                                            5?~G^                    B~^G~GJ?PG.        //
//      B!:^!JY7JB.^!.                                            7. .:                    7#:PP?P!J&Y        //
//     .BJ~!!~J:PJ:5:                                                                      .B7:#?P55GB:       //
//     7P~GJ!Y77#:7G                                                                        Y#:JB!55?BJ       //
//     Y?77!P5~PG~B7                                                                        ^#~~&~PPYGP       //
//     5G^!^?B7B7:P:                                                                         G5:JPJGGYG       //
//     PJ^~:?G!&^.!:                                                                         GG7~#?P5GG.      //
//     5P5!:5J!&~?G7                                                                         B5^7&~?5YG!      //
//     YPGJ~!5:#!:5Y                                                                         #5:?B~57JG!      //
//     BJ!!~YG:Y5 :J^                                                                       .#PJ&5JY5~B.      //
//     ?Y5P!?P7^#::^J                                                                       J57?&?JP?YG.      //
//     .BJ?YYP5:5&.^P:                                                                     YP!7&??G?JJJ       //
//      7Y7~5?!G.BG:J?.                                                                   ^P:!#5G7?P~B.       //
//      .Y~J?J575~P5.^G:                                                                 7?.^B7B757!B^        //
//       ^J!^5~!J~!&~..B~                                                              .5?.7G?P~B!B~P         //
//        ^5J7PGYP:.&7.7!^                                                            ~B7:7GJJG!5B!B          //
//         .G~5Y57?P^YP ^^5^                                                        .5JJ^J&5JGPJ~&J.          //
//          .GY~7.~!!?P5:.~Y5.                                                    .JYJ^P#Y?GYP5PJP.           //
//           .YY775~7Y^5&5..:5^^                                                 ^PJ7JYJ?JJ7!G5&?             //
//             ^JJ~!J^75:Y&Y^. 77?:                                           .7J~^:YBB!Y!J?J#J.              //
//               !P5G?7! !J5&P?..^Y.:.                                     .^YJ~^!7#B~JJ#^YPY~                //
//                :7G?~G~GP.Y5G57 :!!^J7..                              :7??Y!?BY&!7?J?PBGBP                  //
//                  ^5YG?5P^75~PG5B~.~7:!5~J^!^:::           . .:^:~!..7.:.!GYP5?JPJ~P^BP^                    //
//                    :7P?YP~Y!^55G?#JYPJ77!.!.:PPYPY5Y?JJPY:J~:5!J7YY^J?BB?G?GJ5:B?#?::.                     //
//                       ^7BPYJ?5YY^J~!?Y&P7P7!77..~.:^^~~ .^~?7YJP&BJBG75PY5Y&?Y~G7:                         //
//                          .~!P5J555P5#??P7G5##75&5PP5PP5G?#?B#B#5557PJP?J?5JG?J:                            //
//                              .:7PJ5P?7J!?~^Y?75JJGJJY7YJ7JJJ7PP?775?Y5BGG?~..                              //
//                                   .~J??5JYYYP7P?GYJ5!YY?75?P5J?BYGY~7~^.                                   //
//                                         ..:!!..~?YJ77J7!?~^~:::.                                           //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SOTSOA is ERC721Creator {
    constructor() ERC721Creator("Surgery on the state of art", "SOTSOA") {}
}