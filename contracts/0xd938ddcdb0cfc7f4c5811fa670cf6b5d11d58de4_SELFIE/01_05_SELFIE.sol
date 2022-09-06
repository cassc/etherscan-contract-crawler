// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SELF PORTRAIT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                  .:~!7?JYJ????7!~^:.                                                                                           //
//                                                                                             :~7YPB#&&&&&&&&&&&&&&&#BGP5Y7~^..                                                                                  //
//                                                                                        :~?5G#&&&@&&&&&&@&&&&&&&&&&@@@@@@@&&#BGGGGGGPY7:                                                                        //
//                                                                                    .~JP#&&@&&B#&&@@@@@&@@@@@@@@@@@@@@&&&&&&&@@@@&&&&&&#P?~:.                                                                   //
//                                                                                :~JP#&&&&&&&&#&@@@@@@@@@@@@@@@@@@@@@@@@@&&&@@@&&&&&&&&&&&&&#BPJ!:                                                               //
//                                                                             .7P#&@&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&@@@@@@@&&&&&&&&&&&&&&#P7.                                                            //
//                                                                           ^YB&&&&&&&&&&@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&&&&&&&&BY!^                                                         //
//                                                                        .!P&&&&&&&&@@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@&&&@@&&#######&&&&&&&&&&&&&&&&&&&BP7:                                                      //
//                                                                     .!YB&&&&&&&&&@@@@&@&@@@@@@@@@@@@@@@@@&&@&#&&@@&######BBBBBBBBB###&&&&&&&&&&&&&&&&###G?:                                                    //
//                                                                  ^?5B&&&&&&&&&&&@@@@@&&@@@@@@@@@@@@@&B#&@@@#BB#&@@&&##BBBBBB#BBBBBGGGGGB############&####BP?:                                                  //
//                                                              .~JG#&&##&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@&##&&&#&&&&&&&&&&##BBBBBBBBGP5YY55PGGPP5YYYYY5PPGGBB#BGPY~                                                 //
//                                                            :?G&&&&&&&&@@@&&&&@@@@@@@@&&@@&@@@@@@@@@@&&@@&B&@&&&&&&&&&&&&###BBGP55YYYYYJ?7777777??JJYY5PGBBGYYY^                                                //
//                                                         .~5#&&&&&&&@@@@@@@@@@@@@@@@@&B&@&#@@@@@@@@@@@@@@&##&&&&&&&&&&&&&&##BPP5YYJ??77!!!!!7777???JYYY5PGBB5JY7                                                //
//                                                      :!JG#&##&&&&@@@@@@@@@@@@@@@@@@@@&@@&&@@@@@@@@@&&#@@&&&&######&&&#&&#BGPYJ?77!!!!!!!77777777?JJYYYY5PBBGY5J                                                //
//                                                     !B&###&B##&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##&&#GPPPGB###&&&&##BGPY?7!!!!!!!!7??JYY55YYJJJYYYYY5PBBGP5Y.                                               //
//                                                     :G&&#B#&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&PYYJ?J55PGB###BGPYJ77!!!!!777??JJYY55PGGGPP55YYY5PG#G55Y~                                                //
//                                                     ~555B&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&BJ????Y5YJJYPPP5YJ7!!!!!!!77JY5PPPPPPPGBBPYJ?JJY5GB#B7!7:                                                 //
//                                                         ?&&&##&&@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&BJ?7JYJJJ??JY55Y?7!!!!!!!!77??JY5PPPG##BBGJ7!!?YG###P.                                                    //
//                                                        ^G&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&#5???J?JJ?7?JJJ?77!!!!!!!!!7777??J55PPPPJ??7!!7?G#G5!                                                     //
//                                                      ~YB&###BBGGB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&##&#PJ??7777777??77777!!!!!!!!7777??JJY55J777!!!!7JG7                                                       //
//                                                  .^?P#&#[email protected]@@@@@@@@@@@@@@@@@@@@@@@&&&&########B5J??7777777777777!!!!!!!77777???JJJ??77!!!!77J^                                                       //
//                                               .~YG##BGGP555555PP55Y5G#&@@@@@@@@@@@@@@@@@@@@&&&&&#BGGPP5YYY5PG5??7777!!7!777777!!!77777????JJJ?77!!!77?JJ:                                                      //
//                                            .^JPB#BBGGGPPPPPPPPPPPP5YY5PG#@@@@@@@@@@@@@@@@@@&&###BGP5YJ?77777?JJ??77777777777777777777????JJYJ??7??JJJ?J5Y                                                      //
//                                          .?G#&&#&&&&&&&&&@@&&&&##BBGP55PB&&&@@@@@@@@@@@&&&&&&##BGP5YJ??77!!!7?JJ??777777777777777777????JJJ?77?JJY5PP5J7^                                                      //
//                                        .?G&&&&&&&&&&&&&&@@@@@@@@@@@@&&#&&&&&&&&@@@@@@&&##&&&&##BPYJJ??77!!!777??????777777777777777?????JJJ?7777?JYB#P                                                         //
//                                      .JB&&&&&&&&&#&&&&&@@@@@@@@@@@@@&&@@@@@@@@@@@@@@@&&&@&&&##BP5J??77!!!!!!!!77?????7777777777777777?JY5PP5555P55PB#!                                                         //
//                                     :G&#&&&&&&&&&&&&&&&@@@@@@@@@@@@@@&&&&@@@@@@@@@@@@@@@@&&&&#B5J?777!!!!!!!!!7777??????7777777777777?????JY5GGGBBBB?                                                          //
//                                     P&####&&&&&&&&&&&&&&&@@&&@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&##PJ?7777!!!!!!!!!!77777?????????777777777777?J5PPPPGBG7                                                           //
//                                    ~######&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&GY?777!!!!!!!!!!!!!!7777???????????777777777?JY5PPGG5^                                                            //
//                                    7&###&&&&&&&&&&&&&&&@&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&BY?777!!!!!!!!!!!!!!77777????JJJJJJJJJ????77777??J5G5                                                              //
//                                    ~##&&&&&&&&&&#GP5J??JP#&&&&&&@@@@@@@@@@@@@@@@@@@@@@@&&&&#Y?777!!!!!!!!!!!!!!!77777???JJYYYY55YYYYYYJJ??JJY5PGY^.                                                            //
//                                    ^BGYYJ??7!~~~^.       :7YG##&&&&@@@@@@@@@@@@@@@##BB#BB#GJ777!!!!!!!!!!!!!!!!!77777??JJYY55PPPPPPPPPP55PPPGGB#&&BJ^                                                          //
//                                     :.                      .:^75B&&&@@@@@@@@@@&#PYJJJ55YJ?777!!!!!!!!!!!!!!!!!!7777???JYY55PPGGGGBBBBBB###&&&&&&&&&#Y.                                                        //
//                                                                  !G#&&&@@@@@&&GY??777JYY?77!!!!!!!!!!!!!!!!!!!!!777777???JJJY5PGB#&&&&&@@@@@@@@&&&&&&&G:                                                       //
//                                                                   .J###&@@@&&&GJ?77?JJ?77!!!!!!!!!!!!!!!!!!!!!!!777777777???JY5G#&&&&&&@@@@@@@@@@@&&&&&B7                                                      //
//                                                                     !G&&&&&&&#5??77??7!!!!!!!!!!!!!!!!!!!!!!!!!7777777777???JYPB##&&&@@@@@@@@@@@@@@&&&&&&P~                                                    //
//                                                                      .?G#&@&&#?!77777!!!!!!!!!!!!!!!!!!!!!!!!!!!777777777??JYYYYY5PGB#&&@@@@@@@@@@@@&&&&&&&P7                                                  //
//                                                                   .755PGBB###BY?77777!!!!!!!!!!!!!!!!!!!!!!!!!!!77!!!7777????7!!?J?J5GB#&&&&&&&&@&&&&&&&&&&BJ.                                                 //
//                                                               .^~?GBBGGGGGPGPPGGP55YJJ?777!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!77775GGGBBBB#####&&&&&&&&&&&BPY7:                                               //
//                                                         :^!?YPGGGGPP55PPPPPPPPP5PPPPGG5YY?7!!!!!!!!!!!!!!!!!!!!!!!!!!!!!7YYJY555Y5PP5PGP5PBBBBBBBBBBB#######&&&#PJ~::::                                        //
//                                                 .^^^~7YPGGGGGPPPP5555YYYY555555555YYYJYY5PP5?777!!!!!~!!!!!!!!!!!!!!!!7?J5GPJ?JY5YYY5GG55PPGGGGGGGGBBBBBB##B##BBB##BBBGJ!!!~~~!77??!~:.                        //
//                                              :!YPBBBBGGGPPPPP555YYYYJJJJJJJJJYYYYYYYYJJ???JYYY5YYJ7777??77!!7777!!!77JY55PPJ?JJJJJY5PGP5P55555P5PPPPPPPGGGGGGBBBBBGGGG#PJJJ???777????7!!7~.                    //
//                                           .~YGBBBBGGGPPP5YYYY55YYYYYJJ??JJJJJJJJYYYYYYYYJ??7?JY5PP5YYY55Y?JJYYYYYJYY555555J??JJJJJY5PP55Y5PPP55555555555PPGGGGBBGGGGGGBP7JJ??5J?JYYJJJJJJJJ7!^.                //
//                                 ...:^~~~!JGBBBGGGPPPP55YJJ?JY5Y5YJJYJ??7777??JJJYYYYYYJJ??J??JJJYJJ5YJJJYYYJJJJ?JY5YJJJJJ???????JY5PP555Y5PP55555YYYYY555PGGGGGPPPPPGPPB5JYJYP5?777777777777?JJ                //
//                            :~7JYYYY55Y5P##BBBGGGPPPPP55YJJ??J?JPPYJJJ??77!77777?YYYYYYYJ?7777?JYY??Y55YJ?777777???J?????????JJ?JY5PG5YY55555555YYY5YY5555PPPPPPP55PP555B##P55YY77777!!!!!!!!!7^                //
//                         .^?YYY55YJY55PGBBBBBGP55555555YJJJJJJ7?P5!!7???JJ?777777JJJ??JYYJJ?777?JYYJJY555YJ?7?YBB#B??777?Y7?JYJ?JYPG5YY555555YYYYY55555PPPPPPPPPP5555P5PB##BY!!7777777777!!!!!7:                //
//                        ~5JJJ55PP5JJY5GBGGG5JY?JJYY5YYJ???777!!!7YY?!7?77JYYYJ777??????7???????77?JYYYYYYY55Y??5GBGYJ?77YJ!J55?JJ5G5JY5555YYYYYY55555P5YY5P55555555555PPPGBG5!777777777?????Y?5PJ7~~^.          //
//                       ~GG5J?J7?Y55PYY55YY???JYYJJJJ??777!!!!!!!!!?J?7JJ!7?JYY????7???77?????JJYJ???J555YJJY55Y?777?JJ?J5!75PJ??JGPJJY5YYYYYYYYY5555555Y?7J55YYYY55YY5555PPJ577!!!!!!!!!777?G#####BGPY7:        //
//                       :JGG5JY5?J5JYYJGBG5??Y55J???7777777!!777!!!!!7??Y??77?J???7777777777??JYP5YJ??JJYYJJ??JY5YJ77?JJYJ!YG5???55J?J5YYYYYYY5YYY5555555YJYYYYYJJJYYY5PP5Y5Y??777!!!!!!7!!75######GP55YY^       //
//                       JGBGGGPG5Y5YJY5YPGGJ77?YJJ??777777777?J??777!!7?JYY?7777!!!!!!7777777777?Y5P5YJ???JJYJJJY555PGP5J!?GGY?7YY??J5P5YYYJJY555555555555YYYYJJJ??J5J7777JPGY??777777!!!7YB######BPJJY5P?       //
//                  .:::~GGGGGGBBBBG5YJPGY??????777?77?????JJJJJJ?J777???????JJ777!!!!!!7!!77???7!!77JYPGPP5YJJJY55JJJPBPY!YBPJ?JJ???555YJYYJ?77?JY55555555YYJJYJ???55P5YJ?55YJJ??77777!?PB####BBGGG5J?YYYJ       //
//             .:~!7????J????J5PGGBBBBBGGBGY7!777?JJJJJ??JJJ?J???7!!7?YP55YJ?JJ?777!!!!!!!!!!!!77???777?J5PGBBGPYJYYJ?77JJ?PG5JJ?777JY77?JYYJ77!!7?Y555YYYJJJJJJYJJYYY555Y5J7JYYJJ?77!75B#####BGPYJJJ??YBG5:      //
//          :!7?????????77777777JY555555PPGBG5?77??JYPGGGGB5??????777?J5GGP5YJ?777!!!!!!!!!!!!!!!!77????????J5GB#BG5JJJY?7JY5YJ77!7??!!77????77!!!!?JJYJJ??JJYJ?JY5YJYY5PBB5JJ555JJ??YG######BG5J??77!7?55:       //
//         .JJ777777??77777777???????77?JJ?Y5GGPY7!777?J5PGBGGGGGG5J7777J5PGP5JJ?77!!!!!!!!!!!!!!!!77777?JYYJ??J5GB##G5JYYJYPY?7!7?7!!!77?JJ?777!!!!!77?JJY5PPY7?JYJY5P5YPPYJ5GBBG5GBGP5PGBGGP5J???77777777^      //
//          ~5J???????????77777777!777??777JJYY5GGPJ777777?5PGB####BPJ?77J5PP5Y?7777!!!!!!!!!!!!!!!7777777?JY55YYYYJYPBBPJJJ5G5JJY?!!!!!!77????7777!!!!!7?5GGGP5YY5PGP?!7P5Y????JYJJJYYJYGGP55Y?77777777?YBB~     //
//           ?B5YYYPY?777777!!!7!!!7???77?Y5JJJJYPGB5J?77777JJJ5555PGBBP5Y5PPP5J??J??7!~!!!!!!!!!!!!7777?777???JY5PP555B#BPJ?PB5Y?!!!!!!!!!!!7??JJJ?77!!77?YJ??JPB##GY775P5YJ??777!!!!!J###BPYJ??777!!7JG###5:    //
//           :GBP5YYPG5J?77777!!!!7777777?5JY55Y?7?Y5Y5YJY?7??7?7777?JYGB55PPPP55YYY?77!!!!!!!!!!!!!!!!!!!~!!!77?JYYYJ7JYYPBGYYYYJ7!!!!!!!!!!!!7?JY555YJ777!7?JJJ5P5JJ5GBGPY????7777777G###PJ77777??YPGB####P!    //
//            ~BBGP55GBBPYJ??7777777777777JJ7?J5Y777??YPGGBY?J77?JJJ???5JJJJ5P5YY?777!77!!!!!!!!!!!!!!!!~~~~~!!!77????7????YGBPJJYJ?!!!!!!!!!7?JJJJJJJ?77?JJJJJJJJYJ?YPBBGPJ?777???7JPG##B5777?J???5B#####G7.     //
//             ^5BBGPPGGBBPY??7?77777777777Y777YYY?7JJ777J5GPY??5BBBG5YJ55J??J???7!!!7?????777!!!!!!!!!~~~~~~~!!777777??????YPPGGGG5!!!!77777JYJ???????Y55YYJJJ?77JYYY5B#GPPYJ77???JB#BB#GY????7?YG#####P7.       //
//               !PBBPPPPGBBPY???JJJ????777?J77YJ?YYYY?77???5GGBBG5YPB#BGGGPP5JJ?7!!!7?Y5Y?????777777!!!!!!!!!!!!!7J????JJYPPGPB##B5JJ???J55PP5J???JJJYYJ????77?JJY5PPPG#GPPYJJ???5P5J?5GGY7!!7YPB#P5Y?^          //
//                .!PBBP55PGBBPYJJJ????JJJY5PPYJJ!7YYY??77777J555J777?PBBGP5PGP5J??????77777???77???JJ??77!!!77777?JJJ??JY5GGGBBB#BG5YJJJ?77?J55YYJ?7777?J??YYJY55555555BG55YYYYYYJ7!!?5Y?!7J5PGB#5               //
//                  .~?5GG5PGGGBG5YJ????JJJY5PBGY5B5?JY7777777777!77777JPGPYGP?7??????J???7777777777???!!!!!!!!7777??????JJYY5G##PYYJJJ?JJ7!7?J??YPGG5YYYYJ?JJYY5555PP55G#P55PPY?7!!7J5GY?YPGB####P:              //
//                      :YBGPPPGBBG5YJJJ?JJ5BPPPGBBPJYP?777777!!!!!77777?YP5P57!77!!!!7777777777??77??J7!!!!7777!77?JJY5YYJYPPG#B5J777JJY55YJJ5GBBGPPG5?777??JYY555PPPP5P###BPJ777?5GP5JYPBB####BJ!:              //
//                       .JPBBBGGBBBGPP5YPB##BPYY5Y55GGJ!!!77!!!!!!!!!77?JJYPJ!!!!!!!!!!!!!!!!77??77?????????JJJJJJYY5PPPPPGGBBB##BGJYPGGGGGGGGP5J?777777???JJYYY55PPPPPG#BPJ??JYGBBP55G########5                 //
//                         :~!7YBBBBBBBBB###&&#GPBBBPGPYJJJ??77!!!!!!!!77JYYPJ77!!!!!!!!!77!!!!777!7!!!7777777777777777?????JJYYYB########BBGP5J??77777777???JJYY55PPPPPGBP55PGP5BBGGGB#####BBBB5.                //
//                             .PGGGGGGGGPPPGGBGGGP5PBGB####BBGPP5YJJ?777JJJYJ777!!!!!!!77!!!!!!!!!77777777777777777777777??YGGG5J5PGGP5YJ??7777777777777?????JJYYPPGPPB#######GGBGGGPPPPPPGGGGBG:                //
//                           !YPGGBBBP555YJJ?JYYYY55PPGGGBBBBBBB##BB##BGP5Y557777!!!!!77777!!!!!!!!!7777777777777777777777??5B##P7????777!!!!!7!!7777777????JJJJ5PGGGGG######BGPYJJ?????JJY55PPPG~                //
//                           .:~JBBBBBBBBBGGPP55555555YYY555PPGGBBGB######BGJ777777777777777777777777777777777777777777777!777JYJ??77777777777777777777???JJJJJYPGGGGB#####BP5J?77777777???JJY55PY                //
//                              !PGGGGPPP5YJJ????7777777??JJY55PGGBB#BBBGGPY????777777777?777777777777777777777777???7777777!!7YJ?????7777??77777777777??JJJJJYPGGGBB####BGPYJ?77777777777???JYY5P.               //
//                              ?PP55YYJJJ?777777777777777??JJYYYPBBBP5YJJJ???????7777????????777777??77777777777777????????JJJ5JJJJ????????77777??????JYYYY55PPGGB??&##BGPYJ?7777777777777??JJY5P7               //
//                             .JYYYJ????7777777777777777???JYYY5BGPPPPYJJJ??????????JJ?J????????????????????????????????JJB##&GJJ?777???JJJJJJJJJ?JJJJJYYY5PPGGBB! :##BGPYJ??77777!!7777777??JJY55.              //
//                             :JJJJ???77777777777777777???JJY55?YBP5YYYJJJJJJJJ?????J?????????????????J???????JJJJJJJJJJJJ5PGBGYJJJYYYYYYYYJJJ???JJJ??JJYPGBBB#5:   Y#BP5YJ?7777777!!777777???JYYP?              //
//                             ~JJJ???77777!!!!!!77777???JJYY55J  JBG5YYJJJJ??JJJ????????J?????????????J????????JJJJJJJJJJYY??J??JJJ?????????7???JJJJJJ5PBBBBBB?     ^BGP5J??7777777777777777??JJY5P^             //
//    ::^^~!!7???JJJJ5555555P55GBGGGGGPP555P5YYYYYYYYYY55555PPY.   ^5GP5YJJJJJJJ??JJ??????JJ????????????J???????????777777777?J7777777777777????JJJJY5GBBBBBBG~       ?BP5YJ?77777777!7777777???JYYPJ             //
//    GBGB#####&&&&&BG#GBB##G5GB&&&&&Y????JP#&&BGPG###GGGB####G55YJ??G#BGPYYYYYJJJ??????????J????????????J??JJJJJJJJ?????JYGGBG?7777                                                                              //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SELFIE is ERC721Creator {
    constructor() ERC721Creator("SELF PORTRAIT", "SELFIE") {}
}