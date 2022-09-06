// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dancheong
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                   YJ:                                                  :JY                                                   //
//                                                 .JBPPY?~:...                                    ...:~?YPPBJ.                                                 //
//                                               .7PP5555PPPP55555YYJ7~:                  :~7JYY55555PPPP5555PP7.                                               //
//                                             ^?PP555555555555555555PPP5?^     ..     ^?5PPP555555555555555555PP?^                                             //
//                                           !5GP555555555555555555555555PG5!~7??JJ7~~5GP55YY55555555555555555555PG5!                                           //
//                                         ^PG5555555555555555555555555555PPJ777?????YPP55PPGBBBGGP55555555555555555GP^                                         //
//                                        !B5555555555555PPPGGGGBBGGGP5PG57~7?JJJJJJJ?7?5##########BBBGPPP555555555555B!                                        //
//                                       ^#5555555555PGB##############&G!~7JJJJJJJJJJJJ?!7G&#############BBGPP555555555#^                                       //
//                                       YGY555555PBB################&J~7JJJJJJ?JJJJJJJJJ?~J&################BGP555555YGY                                       //
//                          .:~~!!!!!!!~^PG55555GB###################7~JJJJJJ?JYYJJJJJJJJJJ!7#&#################BP55555GP^~!!77777!~:.                          //
//                         ?J?77!!!!!77777?JY5P#####################!!JJJJJ?JYPGGP5JJJJJJJJJ!!&#################&#GPP5YYJJJJ???JJJYY55?                         //
//                        !5~??JJJJJJJJJ???7!~~!?YG#&#############&77JJJJJ?J5GGGGGPP55JJJJJJJ!7&############&&#BP5J??????JJJJJJJJJ???JB!                        //
//                        P~?JJJJJJJJ?JJJJJJJJJ?7~^~75B&#########&5~JJJJJJYPGGGGGGGGGPYJJJJJJJ~5&#########&BPYJ????JJJJJJJJJ?JJJJJJJJ?5P                        //
//                       .G^?JJJJJJJJJJJJJJ????JJJJ?!^^!5#&#######~?JJJJ?5PGGGGGGGGGGGGYJJJJJJ?~#########P?7??JJJJ????????JJJJ?JJJJJJ?JB.                       //
//                       .G:7JJJJJJ5PGPPPPP55YYJJJ??JJ?!^^?B&###&5~JJJJ?JPGGGGGGGGGGGGGP5JJJJJJ^5&###&BJ77?JJ???JJJYYY55555PP5JJJJJJJ??B                        //
//                        5~7JJJJJJ5GGGGGGGGGGGGP55YJJJJJ?~:?##B&77JJJJJ5GGGGGGGGGGGGGGGGPJ?JJJ~7&##BJ!7JJ??JJY55PGGGGGGGGGGGPYJJJJJJ!?5                        //
//                   .:^~~YY^JJJJJJ?5GPGGGGGGGGGGGGGGP5JJJJ?~^5&&!7JJJ?YGGGGGGGGGGGGGGGGGG5JJJJ~~&&P77JJ?JJ5PGGGGGGGGGGGGGGPG5JJJJJJJ~5Y~~^:.                   //
//               .!J5PPPPPPB~?JJJJJJ5GGGGGGGGGGGGGGGGGGGPYJJJ7^[email protected]~7JJJ?5GGGGGGGGGGGGGGGGGGGY?JJ^[email protected]?JYPGGGGGGGGGGGGGGGGGGG5JJJJJJ?~#PPPPPP5J!.               //
//             :JPP5555555YPP~JJJJJ?JGGGGGGGGGGGGGGGGGGGGGPYJJJ7G77JJJJ5GGGGGGGGGGGGGGGGGGGY?JJ^!#?JJJYPGGGGGGGGGGGGGGGGGGGGGJ?JJJJJ~PPY5555555PPJ:             //
//           .JGP55555555555BJ!JJJJJJ5GGGGGGGGGGGGGGGGGGGGGG5JJJ5Y~JJJJPGGGGGGGGGGGGGGGGGGG5?JJ:Y5?JJ5GGGGGGGGGGGGGGGGGGGGGG5JJJJJJ!Y#55555555555PGJ.           //
//         .7GP55555555555PGB&J~JJJJJJPGGGGGGGGGGGGGGGGGGGGGGPJ?JB^?JJJPGGGGGGGGGGGGGGGGGGG5?J7:BJ?JPGGGGGGGGGGGGGGGGGGGGGGPJJJJJJ~J&#BP55555555555PG7.         //
//       ^?PP55555555555PB####&J~?JJJ?JPGGGGGGGGGGGGGGGGGGGGGGPJ?PY^JJJ5GGGGGGGGGGGGGGGGGGGY?J^YP?JPGGGGGGGGGGGGGGGGGGGGGGPJ?JJJ?^Y&####GPP5555555555PP?^       //
//    :5PPP555555555555P#######&P~7JJJ?J5GGGGGGGGGGGGGGGGGGGGGG5??G?~J?YPGGGGGGGGGGGGGGGGP5JJ~?G??5GGGGGGGGGGGGGGGGGGGGGG5J?JJJ!~P&######B#G55555555555PPP5:    //
//     ^PPY555555555555B########&B7!?JJ?JYPGGGGGGGGGGGGGGGGGGGGPY?JGJ?55GGGGBBGGGGGGBBGGGG55??GJ?YPGGGGGGGGGGGGGGGGGGGGPYJ?JJ?~7B&##########G5555555555YPP^     //
//       YG55555555555G###########&P77?JJ?J5PGGGGGGGGGGGGGGGGGGG5JJPGY???????YGBGGBGY???JJJJYGPJJ5GGGGGGGGGGGGGGGGGGGP5J?JJ?!!P&#############G555555555GY       //
//       .BP5555555555B##############P?7????JYPGGGGGGGGGGGGGGGGG55G?!7YPGGGG5J7J##J7?YPGGGGPY7?G55GGGGGGGGGGGGGGGGGPYJ?JJ?77P#################P5555555PB.       //
//        YG555555555P#################G5YJ???JJY5PGGGGGGGGGGGGGBB!!JGGGGGGGGGGJGGJGGGGGGGGGGG7!BBGGGGGGGGGGGGPP5YJJ?????YG###################G5555555GY        //
//        7B555555555P####################BG5YYYYJJJYY5PPGPPGGBB#P~7GGGGGGGGGGGG#BGGGGGGGGGGGG?~P#BBGGPPP55YYJJJYYYYY5PGB#####################B5555555B7        //
//        ^#555555555G#####&&#BG5YJ????????????J?JJYY5YYJJ5G5Y???YPYPGGGGGPGGGGG&&GGGGGPGGGGGPYPY77?J5P5JJYY5YJ??77!!!!!!!!!777?Y5GB##########B5555555#^        //
//         BP55555555P####GY?7!!77????JJJJJJJ???????77?J5G57?YY555PB##GGGGGYGGGG&&GGGGYGGGGGB#BP5YYJ?775G5?!~~!77????JJJJJJ????77!!!!?YG#&####B555555PB         //
//         ~B55555555GB5?!!7??JJJJJJJ???JJJJJJJJJJYJJJJ?GJ!PGGGGGGGGB#&#BGGPJPGG&&GGPJPGGB#&#BGGGGGGGGP7JP!?JJJYJJJJJJJJJJ?????JJJJJ??7~!?P#&#G555555B~         //
//          !GP5555G5?~!??JJJJJJ???JJYY55PPPPGGGGGGPPPPGG!YGGGGGGGGGGGB#&#BGPYPP##PPYPGB#&#BGGGGGGGGGGG5!GGPPPPGGGGGGPPPPP555YYJJJJJJJJJ?7!~?GG5555PG!          //
//           :YG5GP7~7?JJJ?JJJ?JJY5PPGGGGGGGGGGGGGGGGGGBG!JGGGGGGGPPPPGGB#&#5?!~~^~!?5#&#BGGPPPPGGGGGGGJ!GBGGGGGGGGGGGGGGGGGGGGPPYJJ??JJJJJ?!:!PG5GY:           //
//             ~BJ!?JJJJ?JJJJJY5PGGGGGGGGGGGGGGGGGGGGGGG#J!JGGGGGGGGP55555G7^^^^^:.. .!G55555PGGGGGGGGJ!J#GGGGGGGGGGGGGGGGGGGGGGGPP55YJ?JJJJJ?~:JB~             //
//            .Y?7JJJJY555PPPPGGGGGGGGGGGGGGGGGGGGGGGGGGG#5??5GGGGGGGGGGYG~^^^^^^^^^.  ^GYGGGGGGGGGG5??5#GGGGGGGGGGGGGGGGGGGGGGGGGGGGP5JJJJJJJJ?^!Y.            //
//            75~JJJJJ?JYPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGB#P5GB#########P:^^^^^^^^^. . P#########GG5P#BGGGGGGGGGGGGGGGGGGGGGGGGGGGPGGPPJ?JJJJJJJ~57            //
//            .Y7~JJJJJJ?JJ5PGGGGGGGGGGGGGGGGGGGGGGGGGGGG#577YPGGGGGGGGGYG~^^^^^^^^:.. ^GYGGGGGGGGGP5??5#GGGGGGGGGGGGGGGGGGGGGGGGGGP5YJJJJJJJJJJ!?Y.            //
//             ~BJ~?JJJJJJ??JJYPPGGGGGGGGGGGGGGGGGGGGGGG#J~JPGGGGGGGP55555G7^^^^^:. ..!G55555PGGGGGGGGJ~J#GGGGGGGGGGGGGGGGGGGGGGGPYJ????JJJJJJ7~JB~             //
//           :YG5GP?7?JJJJJJJ??JJY5PPGGGGGGGGGGGGGGGGGGBG~?GGGGGGGPPPPGGB#&#5J7!~^^!?5#&#BGGPPPPGGGGGGGJ~GBGGGGGGGGGGGGGGGGGGGP5YJ?JJJJJJJJ?!^7PG5GY:           //
//          !GP5555GPJ77?JJJJJJJJJJJJYY55PPPGGGGGGGPPPPGG!?GGGGGGGGGGGB#&#BGPYPP##PPYPGB#&#BGGGGGGGGGGG5~GGPPPPGGGGGGGPPPPPPP5YJ?JJJJJJJ?7~^?PG5555PG!          //
//         ~B5555555PGGPJ????JJJJJJJJ????JJJJYYYYJYJJJJ?GJ!5GGGGGGGGB#&#BGGPJPGG&&GGPJPGGB#&#BGGGGGGGGP7JG7?JJJYJYJJYYJJJJJJJJJJJJJ?7!~^~75G#BP555555B~         //
//         BP555555GBBG###G5YJ???????JJJJJJJJ?????7777?J5G57?Y555PPGBBGGGGGYGGGG&&GGGGYGGGGGBBGP5555Y??5G5?7!~!!77???????????77!~^^^~7YG###PGBP555555PB         //
//        ^#5555555B##########BGP5YYJJ????????????JYYYYYJJ5P5J???5PYPGGGGGPGGGGG&&GGGGGPGGGGGPYPY??JY5P5JJJY5YJ?7!!~~~~~~^^~~!7?J5GB######BGBBG5555555#^        //
//        7B5555555G######################BG5YYYYYJJJYY5PPPPGGBB#P~?GGGGGGGGGGGG##GGGGGGGGGGGG?~P#BBGGPPP55YYJJJYYYJ??YG##############B##BBGGGG5555555B7        //
//        YG55555555###################G5JJJ??JJY5PPGGGGGGGGGGGGBB!7GGGGGGGGGGGYGGJGGGGGGGGGGG7!BBGGGGGGGGGGGGPP5YJJ?7!^~JG&##########B####GGBB5555555GY        //
//       .BP55555555P################P?7????JYPGGGGGGGGGGGGGGGGG55G?7YPGGGPP5J7J#B?7J5PGGGGPY7?GGPGGGGGGGGGGGGGGGGGPYJJJ7~:!P&##########B#BGBBG5555555PB.       //
//       YG5555555555B############&P7!?JJ?J5PGGGGGGGGGGGGGGGGGGG5JJPGYJJJ?77?YGBGGBPY?77???JYGPY5GGGGGGGGGGGGGGGGGGGGP5JJJ?!:~P&##########BGBBP55555555GY       //
//     ^PPY55555555555B#########&B?!?JJ?JYPGGGGGGGGGGGGGGGGGGGGPY?JGYJY5GGGBBBGGGGGGBBGGGG55?JGJYPGGGGGGGGGGGGGGGGGGGGGPYJ?J?~.7#&#######BPBBP555555555YPP^     //
//    :5PPP555555555555G##B####&P!?JJJ?J5GGGGGGGGGGGGGGGGGGGGGG5??GJ7J?YPGGGGGGGGGGGGGGGGPY?J7JGJYPGGGGGGGGGGGGGGGGGGGGGGPY?JJ?^:P&#####BGBBG5555555555PPPY:    //
//       ^?PP55555555555PB##B#&Y!?JJJ?JPGGGGGGGGGGGGGGGGGGGGGGGY?P57JJJ5GGGGGGGGGGGGGGGGGG5JJJ!5P?JPGGGGGGGGGGGGGGGGGGGGGGG5JJJJ!.J&###BBBBP555555555PP?^       //
//         .7GP55555555555PBB&J!JJJJJJPGGGGGGGGGGGGGGGGGGGGGGGY?JB~JJJJPGGGGGGGGGGGGGGGGGGPJJJJ!BJ?JPGGGGGGGGGGGGGGGGGGGGGGGPYJJJ7.?&#B#BG555555555PG7.         //
//           .JGP5555555555YBY!JJJJJJ5GGGGGGGGGGGGGGGGGGGGGGPYJ?5Y!JJ?JPGGGGGGGGGGGGGGGGGG5JJJJ755?JJ5GGGGGGGGGGGGGGGGGGGGGGGGYJJJ?:J&BGP55555555PGJ.           //
//             :JPP5555555YPP!JJJJJ?JGGGGGGGGGGGGGGGGGGGGGP5J?J?B??JJ?YGGGGGGGGGGGGGGGGGGG5?JJJ??B?JJJYPGGGGGGGGGGGGGGGGGGGGGGPYJ?J?^PG55555555PPJ:             //
//               [email protected][email protected]?JYPGGGGGGGGGGGGGGGGGGGGG5Y?JJ?~BPPPPPP5J!.               //
//                   .:^~~Y5!JJJJJ?JPGGGGGGGGGGGGGGGGG5YJ?JJ?JG&&!?JJJJPGGGGGGGGGGGGGGGGGPJ?JJJ?!&&P!7JJ?JJ5PGGGGGGGGGGGGGGGGGGPJ?JJJ^YY~~^:.                   //
//                        5!7JJJJJYPGGGGGGGGGGGGGGP5YJ??JJ??5###&?7JJJ?YGGGGGGGGGGGGGGGGGY?JJJJ7?&#&BJ~!?JJ?JJY5PGGGGGGGGGGGGGG5JJJJJ!~5                        //
//                       .G:7JJJJYPGGGGGGGGGGPP5YJJ??JJ??7YB####&5!JJJJ?YGGGGGGGGGGGGGGGYJJJJJJ!5&###&BJ~!?JJJ?JJJJYY555555PGGPYJJJJJ7:G.                       //
//                       .G:7JJJJJYPPPPP55YJJJJ??JJJ?77JP#########~?JJJJ?YPGGGGGGGGGGGGY?JJJJJ?!#######&#57~!?JJJJ?????J?JYPP5J?JJJJJ?:G.                       //
//                        P~!JJJJJ?JJJJJ???JJJJ??7!7JPB##########&5~JJJJJ?J5GGGGGGGGGGY?JJJJJJ!5&#########&B5?!!7??JJJJJJJ5YJ??JJJJJJ7!P                        //
//                        !5^?JJJJJJJJJJ???77!!7?5G#&#############&7!JJJJJ?JYPGGGGGGGY?JJJJJJ7?&###############G5?7!77??????JJJJJJJ??7P!                        //
//                         ?JJJ?777!!!!777?JY5B#############B#######77JJJJJJ?JYPGGGGPJJJJJJJ77&####################BPYJ?77777777!!77?J?                         //
//                          .:~!!7777!!~^PG5555PB####################7!JJJJJJJ?JYPGGY?JJJJJ77####################BGP555GP^~!!!!!!!~~:.                          //
//                                       YGY555555PPGBB###############J!?JJJJJJJ?JYYJJJJJ?!Y&#################BGP55555YGY                                       //
//                                       ^#555555555555PPB########BBBB#G7!?JJJJJJJ??JJJ?!7G&##############BGPP555555555#^                                       //
//                                        !B555555555555555PPPPPPPPPPP55G5?7??JJJJJJJ?!7P###########BBBGPP555555555555B!                                        //
//                                         ^PG5555555555555555555555555555PG5JJJJ????YPPP5PPPPPPPPPP5555555555555555GP^                                         //
//                                           !5GP555555555555555555555555PG5~~?YYJ?7~!5GP555555555555555555555555PG5!                                           //
//                                             ^?PP555555555555555555PPP5?^     ..     ^?5PPP555555555555555555PP?^                                             //
//                                               .7PP5555PPPP55555YYJ7~:                  :~7JYY55555PPPP5555PP7.                                               //
//                                                 .JBPPY?~:...                                    ...:~?YPPBJ.                                                 //
//                                                   YJ:                                                  :JY                                                   //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DCHNG is ERC721Creator {
    constructor() ERC721Creator("Dancheong", "DCHNG") {}
}