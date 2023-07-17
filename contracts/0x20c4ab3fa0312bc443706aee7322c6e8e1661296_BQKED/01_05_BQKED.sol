// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BQK EDITION
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                     :^^~^:.                                                                                //
//                  ^7JYYYYYYY?~..^~~!777777!~:                                                               //
//                :?YYYYYYYYYYYYY5YYYYYYYYYYYYY7                                 ...                          //
//                JYYYYYYYYYYYYYYY5YYYYYYYYYYYY5!:.           .:^~~~^^^::.  .^!?JJJJ?7~:                      //
//               ^5YYYY555YY5YYYYY5P5YYYYYYYY5555YY7.       .7JYYYYYYYYYYJJJJYYYYYYYYYYY?^                    //
//             :!JYYY5YJ?????JY555J??Y5555555YYYJJ?J?.    .:J5YYYYYYYYYYY55YYYYYYYYYYYYYYY^                   //
//           .7YYYYYYYY?^. .JGYB&&B. ~7777!~^:~J5P?:.!. ~?Y55555YYYYYYY5PP5YYYYYYY5555YYYY?                   //
//           75YYYYYYY555J7!#@[email protected]:!.      7&##@@7.!:~J????JJY55Y555577775GGG5PJ777Y5YYYY?!.                //
//          .YYYYYYYYYY555555555PPP55Y?!^:^^~#&#&&#5J^^:     :YGBGP!^^!.  :##@[email protected]#^~?Y5YYYYYYY!               //
//          ^5YYYYYYYYYP55555555555YYYY555555555555P! :7~:.  7#5&#@B^.!J!~7B5#GPGP5555YYYYYYYY5^              //
//          ~5JYYYYYYYYY5555555555555555555555PYY?!~.  ^55YJJJPGGGGPYYYY555Y5Y55555555YYYYYYYYY7              //
//          .JYYYYYYYYYYYYYYY555555555555YYYYY!..       !?J55P55555555555555555555555YYYYYYYYYYJ              //
//           :5YYYYYYYYYYYYYYYYYYYYYYYYYYJYY7:             .:~Y55Y555555555555555YYYYYYYYYYYYYY5^             //
//           ~GGP5YJYYY5YYY55YYYYYYYYYYYY5PG:                 .~JYYYYYYYYYYYYYYYYYYYYYYYYYYYY5GGP~            //
//          :PGGGGGP5YYYJJJJYYJYYYYYY55PGGGGY                   .^7YYYYYYYYYYYYYYYYYYYYYYY5PPGGGGG~           //
//          ?GGGGGGGGGPPPP555PPPPPGGGGGGGGGGG~                     .JGPP555YYYYYYYYYYY55PGGGGGGGGGP:          //
//         ^GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGY                     :PGGGGGGGGGGPPPPPGGGGGGGGGGGGGGGJ          //
//         JGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG~                    JGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG~         //
//        ^GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG5.                  ~GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGY         //
//        ?GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG~                 .YGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG~        //
//       .5GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGY                 ~GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGJ        //
//       .PGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG^                YGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGP:       //
//       .5GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGJ               ^GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG!       //
//        ^YGPGGGGGGGGGGGGGGGGGGGGGGGGGGGGPPPPPPJ               ~GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGB?       //
//         .JYGGGGGGG5YYYYYYYYYYYYYYJYYYYYJJJJJJ.    ....       .Y55PPPPPPPPGGGGGGGGGGGGGGGGGPPPPPP55?:       //
//          7J5PGGGPGY??????????JJJ?J5YYYYYYYYYY7~^^?5YJJ7~~!!!!!YYYYYYYY555JJYYYJJJJPGGGGGGGYJJJJ???.        //
//          ~J?JYYJJJJ??????????JJJJGYJYYYYYYYYYYYYY55Y555YYYYYYYYYYYYYYYYY5P?JJJ????PGGGGGGPY?????J7         //
//          .JJ???????????????????JYGYYYYYYYYYYYYYYYYYYYY5YYYYYYYYYYYYYYYYYYPYJJJ???JJY55PG5J??????J~         //
//           ^JJ???????????????????JYJJJJJJJJJJ!55555555YY55?7777?YYYYYYYYYYPJJJ?????????JJJ?????JJ?.         //
//            :J???????????????????JJ????????J? ~7J5555P55J!.     ?JJJJJJJ??JJ???????????????????J7.          //
//             :J?????????????????JY?????????J~    :~~~^^:        !J?????????Y??????????????????J?.           //
//              ~J????????????????JJ?????????J:                   ^J?J?????J?YJ????????????????J?.            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BQKED is ERC1155Creator {
    constructor() ERC1155Creator("BQK EDITION", "BQKED") {}
}