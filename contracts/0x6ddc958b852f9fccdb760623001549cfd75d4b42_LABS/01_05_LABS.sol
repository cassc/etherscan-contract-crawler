// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 0x0labs
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                .PP:     !B?                                                //
//                                                   ::      .^.                                              //
//                                                       ~7^                                                  //
//                                               .^^....:P#5.....:^                                           //
//                                               ~#BYYJYY5P5JYJJYB#^                                          //
//                                         ^^    :5YYY5GGGGGGGYYY55:    ^^                                    //
//                             ..         .BB:...^JYPPP&&&&&&&PPPYY^ . ^#B.         ..                        //
//                            :5?         .JJJJJJJY5#[email protected]@@@@@@B#B5YYJJ?JYY.         ?P:                       //
//                                  .GG.  .???YB#[email protected]&#B#@@BGGP5B#GYJJY   .PG:                             //
//                                  .Y57!!!JGGPPPP5P###@&[email protected]@###GPGGPPGPY!!!!YP:                             //
//                            :5?   .?JJJJYYGBP5B#####&@&[email protected]@######B5GBB5YYYJJY.   ?5:                       //
//                      ..     :.   .JJJGBG55PPP#&&&&&&@&[email protected]@@@@&#&#GPP55GBGYYY:   .:     ..                 //
//                      ?Y~         .JJYPGP5G#&&##&&@@@@#!.7#&@@@@&#####G5GGG5YY:         ^YJ                 //
//                            .^^^~^~JY5GBBB#&&@&&&@@&&&#^.~B&&&@@@&&&&#BBBBB5YY!^^^^~.                       //
//                            .JJYPP5YY5###&&&@@@@@@@BGJ?:.:[email protected]@@@@@&&&&&##5YY5P5YY5^                       //
//                      !?^   .JJJB#B55P##&@@@@@@&&&#PY:.^!~.:J5#&&@@@@@@@&##G55B#B5YY^   :7!                 //
//                      ~7:   .JYJ55G#B####@@@@@@&BY?:.^^~~~~^.:7YG&@@@@@@&#####G5PYYY^   :7!                 //
//                         :!!7YYYGBB&&&&&&@@&#BPPY!~. ....... .~75PGB#@@@&&&&&&BGG5Y5?!!^                    //
//                         !YYY555###&&&&@@@@@BP:.^::^~~:^^^~7~^.:~:^[email protected]@@@@&&&&###5555YY7                    //
//                      ::.   .YYYPGB&&&&&@@@@@@7..7GPP?77?7775GG^ [email protected]@@@@@&&&&&BGG55P^   .::                 //
//                      7Y^   .YYYPPB&&&@&&&&&@&7:GGB!!PGPJ5GG^?BG5^[email protected]&@&&&&@&&&BGGYY5^   :J7                 //
//                         ~?7?555B##&&&@B7PGGGP!.J5P::7PP?5P?.^P5?:[email protected]&&###B555J77^                    //
//                         JGGG555BB#&@&&&5:.      ..   :GB5:   ..  ...  .5&@@&&##B555PGB5                    //
//                         7JJPGGGBB#&&###&^ .: ..: .::!77!?7:::  .:. :: ^&###&&#B#BBGPY5Y                    //
//                         7JJ5###&&&&&J77?^.^~  :^..7?~. ...:J?...^. ^~.~????#&&&&###PYYJ                    //
//                      ^~~?JJP#B#&&&@B.......  ...7!^.. :^. ..~?!:.  ........#@&&&###PJJJ~~^                 //
//                      ?5YJYYP###&&#Y7:GBB:  !BB5?.  .^^^:^^^  .:75B#7  ^BBB:7JB&&###PYYYY5?                 //
//                         7JPB##5PGJ .^PGP:  !GG7.  :^:??.?J~^:   7PP7  ^GGP:. 7GPY#&BG5Y                    //
//                         7JYG&#Y: .^^^:..  .^..  .^^!5G5^PBG~^^^  ..:^  ...^^~..:7#&G5YJ                    //
//                      ~!!JYYPB#@GJ..^?:   .!7    .::^~7!:7J!::::   .!7:   :J~.:JG&#BPYY5!!~                 //
//                      G#BPYJ5B#&##7 7&G7  ^Y&P^  ^!^!5PY~5GY^:!~  ~P&B!  ?G&? 7##&#BPYY5##G                 //
//                      ?JJYYJ5B#&BY^ [email protected]?  ~5&#~  ~!.^PGY:?5J:.7!  ~G&[email protected] ^?G&#BPY55YJ?                 //
//                         ?YJ5B#&B5~ ?&B?  !5&B~  ~?:^5G? ?J?::7!  ~G&BJ. [email protected]? ^JB&#BPYYY                    //
//                        .7J?5B#&P?!:Y&BJ  !5&B!  ~7~!5P?.JGY^^?!  ~B&[email protected]^~?P&#B5JJ?..                  //
//                      J5YJJJ5B#&7 .GB&G7  .5BB!  ..^~!~~!^7!~^..  !B#P.  ?G&#G: 7&#BPJJJ55J                 //
//                        .7J5G&#J!~^!!7^ .:^!7~:  :^^~^^^^^:^~~^:  :~!!^^  :!!!^:!YB&G5YJ..                  //
//                         7JYP&B:  .::      ^^      :^       ^^      ^^      :^. .:G&GJJJ                    //
//                         !YPP#G:                   ..                            :P&G55J                    //
//     :^:    ^^.          7#&B!^..^^^^^.   ^^^^^~~. :^^^^~^^~~^  :^~~^^^   .^^^^^ .:7B&#J          .^^^^     //
//    ...:^:^..:^^~.  .^~~~!!7!^::^:....~^^.......^:...........:^^:.:::.^^^^:....~~:^~!77!^^~^~~~~^^......    //
//      .    .                     .                                                                .         //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LABS is ERC1155Creator {
    constructor() ERC1155Creator("0x0labs", "LABS") {}
}