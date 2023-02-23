// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OnlyInDreams
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                          .^~J?!J?!~.                                                                         //
//                                                                        :?BG&#[email protected]#5#@#Y^                                                                       //
//                                                                       [email protected]&@&?                                                                      //
//                                                                     .5PGPBBBPG5G&5&@&&@?                                                                     //
//                                                                :^~~!JB##P#G#&&GG&B&&@&&&7:.                                                                  //
//                                                             ~JPGBB###G#&G#&B#####&&&@&@@@&#GJ7^                                                              //
//                                                           .Y#B####BBGGGPGGGBBBB#&&&&&&@@@@@@@@@Y                                                             //
//                                                           !&&&#GY??JJ5Y5PGPGBBB#&&&&&&&&&&@@@@&5                                                             //
//                                                            !5B#GYJJY5G#@@@GJP#@@@@@@@@@@@@&B57:                                                              //
//                                                               :!7JY5PGB##&?.^[email protected]&BBBBBG5Y7~:                                                                  //
//                                                                      .....^::?&#.        ^7J.                                                                //
//                                                                :^~?57~ .7 :::!G&!:.^^~:  ^77.                                                                //
//                                                              .?7?PG5~  ^J::^:!JGP:~J5BP.:.  .                                                                //
//                                                              ~YJ?!! .7 ..:~::~YB#7^^!J..:.^7~                                                                //
//                                                                  J?!PB:~~?!.:!GB#P5J!?^^~^^!!.                                                               //
//                                                                  .7YGGPPGY:[email protected]@#YGG!.                                                                    //
//                                                                 .~!7P#&@#?~?PB5PB#[email protected]#57~:                                                                  //
//                                                                 :7P##&#&&#[email protected]&PGPJB&&P^.                                                                  //
//                                                                 .^J#@@&@@@#&&&#5GPB&@@@G!                                                                    //
//                                                                   .^7Y5GB#BGGBGG##BGPPY^.                                                                    //
//                                                                           .:^^^::.                                                                           //
//                     .::^^:                ?~                    .^^                  .::..    :.                                                             //
//                  :!!^::::~J?             ~&:                   !~.P~               :~~!!?JJ?~7#.                                                             //
//                 JY^        GP            PY                   ?J  GJ               J^     .^?&B~                                                             //
//               :BY          [email protected]^          :#:                  :B. :@!               :YJ:     ~#~JP~                                                           //
//              .BG           [email protected]:          YY                   !B  Y#.                 :.    .#7  :5J  .:                                                      //
//              [email protected]~          .&5  ~..^!:  .B:  ~.  ^^           :G.:&!  ~..^!:                YP     J7 !5!:^   ::^:   .^^:~^  ^^ :!~ .~!.  .:~~                //
//              [email protected]          PG. !B~~.PY  7Y  7B  .#~            :7GY. 7G~~.G?               7P.     :Y .?!Y^ .J!:Y7  ?7: !&:  B?^:JG^^:#^ .5^.!.               //
//              [email protected]!        ^5J   G5: .G:  P:  G!  ?P             :Y!.. BY: .G.        ...   !J       !~ ^.Y~  PY:~:  P?  .P?  ~#~  GY. ~5   !YJ.                //
//               !P7:...:^7?:   ^#:  ~G:.^G:::B:.^#^      .....:~!.   ~B.  !P::     !??JY5YPY~::..:^~^   JG.^.GY:.:::&~.^^G!: 5?  ~B.  YJ:~!..J^                //
//                 ^~^^^^:.     :^   .!^  !^  ~~:?5       77!^^:.     ^:   .!^      ^^::^^:^!777!~^:     :!^. .!!^:  ^!^. ^!. ~   ::   :!::!~^.                 //
//                                              :5:                                                                                                             //
//                                          ~?~^~.                                       .                                                                      //
//                                            .                                        ^J!        .:^~:                                                         //
//                                                                   ..         :!5G5P5J~ ^~7?YPGB#PJ!.                                                         //
//                                                            .~7J5G!^GBG5J~   ?YB#B#[email protected]@@@@#P:                                                            //
//                                                          ^7GBGPPB7 ~G&&P?: .B#BBBGB#&#&[email protected]&@&7.                                                              //
//                                                         JB5G#&#BB~ ::G?^:. J&#J5#PG&BP#####B^                                                                //
//                                                        7#BGPJ5PGBP^:^~^^.~GB##BGPP5PPPP5J7!^                                                                 //
//                                                        ^J&&@G5P5YY7!!!!.:~?Y555PPGBBB##&#&&#P~                                                               //
//                                                          [email protected]&&B5PYPG~?!^??~7PBBBBBBBGBGPPJ5B#&&GP^                                                            //
//                                                          7&&&&##PY&~^7?~YGJ7PGGB#BG5?Y&@#YB&&&&&BPJ.                                                         //
//                                                         ^[email protected]&&&&&P&@?~!JY:7B5!##?5B5GGGB&&G&PYGB?~!!.                                                         //
//                                                          ^[email protected]&@@@&&@P~Y~55.?BP?&J?JPGYBG7Y7!.  .                                                              //
//                                                           :GG5?~~B&&7?G~&[email protected] !.                                                                  //
//                                                             ~?JJ?Y&&B~G?P&!!7???!J5##5#5  ~:                                                                 //
//                                                            [email protected]@@@@&&&&B?GJP#?7JYY#Y7^~~!^.                                                                    //
//                                                            [email protected]&&&&&&&&#5PJ7GG55YYYYY7^.                                                                      //
//                                                            ^P#G#&G#&&&&&#G5Y5GBG5?JPPPPPY?^                                                                  //
//                                                           75G!J?###&&&#B#B#GPPPP5YYJ77JP!~7J:                                                                //
//                                                          :YY? ^?7&&&#G#P?P5Y7!YBBP5?7:~G^  ^5                                                                //
//                                                          .YY?^Y?^[email protected]&&Y^..?!7??!!5G5YJ!~: .^??                                                                //
//                                                           :JP?~~J?#&B57~:!7..:!YJPPG57!~!!7~                                                                 //
//                                                             ^?JJ7.?&J!Y7. ^    ^ :~PYP7J!                                                                    //
//                                                                .~J!Y.::          :!Y!?..?J.                                                                  //
//                                                                   7~.             ::..  :?^                                                                  //
//                                                                   :                   .:^:.                                                                  //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract OiD is ERC721Creator {
    constructor() ERC721Creator("OnlyInDreams", "OiD") {}
}