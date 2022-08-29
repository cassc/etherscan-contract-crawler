// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: aiLE8NS
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    &&&&&&&&&&&&&&&&&&&&&&&######&&&&&&&&&&&&&&&&&&&&&&&&&####&&&&&&&&&########&&&&&&&##&&&@@@@&####&&&&    //
//    &&&&&&&&&&&&&&&&&#####&&&&&&&&&&&&&&&&&&&&&&########&&&&&&&&###&&&&&&&&#######&&&&&&&&&&&&@@&####&&&    //
//    &&&@@@&#&&&&&####&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#B##&&&&&&&##&&&&&&&#BYG####&&&&&&&&&&&&####&&    //
//    @@@&&&P7P#####&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@&5?#&&&###&&&&&&###&&&BJG#####&&&&&&#&&&&&&&&&&    //
//    &&&&&&#B##&&&&&&&&&&&&&&&&&######################&&&&&&&&@@@&&&###&&&&&###&&&&&######&&&&G&&&&&&&&&&    //
//    &&&&####&&&&&&&&&&&&&&&&##########&###&&&&&&&&###&&&###&#&&&&@@&&&###&&&&&##&&&&&######&&#&#&&#&&&&&    //
//    &&####&&&&&&&&&#G#&&&#########&&&&&&&&&@&&&&&&&&&&&&#########&&&&@&&&####&&&##&&&&&#B###BP####B#&&&&    //
//    ####&&&&&&&&&&&#G########&&&&&&@@@&&&&&&&&&&&&&&&&&&&&&&&&&######&&&&&&###&&&&##&&&&#####G#&&#B###&&    //
//    ###&&&&&&&&&&&&#5#####&&&&@@@@&&&&&G7G&#########&&&&&&&&&&&&&&&&####&&&&&###&@&&#&&&&&#####&&&&####&    //
//    #&&&&&&##BB#BGPJ^JPGB&##&@@&&&&####BPB###################&&&&&&&&&&####&&&&##&@&&##&&&&##P###@&#####    //
//    &&&&#########BBB?#&&&&&&&&&########B##BYYYYYYYYYYY5#&&&&#######&&&&&&&###&&&##&&&&###########&&&####    //
//    &&###############&&&&&&&#######BBY?:...            .^YJJ5#&&&#####&&&&&###&&B##&&@&############&&###    //
//    &############&&&P#&&&&######BJ7:.                        .^?5B#&#####&&&&########&&&############&###    //
//    ########BB#&&&&##&&##BBBB#B?.      :^~PGGGG5~^^^^:           .:7YGB####&&&#######&&&&#######B##B#&#B    //
//    ######BBB#&&&&#&&#BBBBB#G7. ^!!!PBB&&&&###&#&&&&&#GBP~!^         .:P&#####&&######&&&#######BBBBB###    //
//    #####BBB#&&&&#&&#BBBBB#B^ ^P&&&&&###BBBBBBB###B######&&&P^         .?G#####&&######&&&######BBBBBB##    //
//    BBBBBBBB&&&####BBBBB#B! ^B&&#B##BBBBBBBBBBBBBBBBBBBBB####&G!         .!G##BB#######&&&&#######BBBB##    //
//    BBBBBB##&&####BBBBB#B^  [email protected]####BBBBBBBBBBBBBBBBBBBBBBBBBBBB&&G5!:.      .!G#BB##BBBBB&&&#BBBBBBBBBBBB    //
//    BBBGGB###B###GGGGB&G:  [email protected]##B#BBBBBBBBBBBBBBBBBBGBBBBBBBBBBBB###&B7.      ^5BBBBBBBBB&&&BBBBBBBBBBBBB    //
//    BBGGGBBBBB##BGGGG#P:  7&&###BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB##~      .JGGBBBBBG#&&BBBBBBBBBBGGB    //
//    BGGGGGGBBBBGGGGG#P:   [email protected]##BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB##J.     .?GGBBBBG###BBBBBBBBBBGGB    //
//    GGGGGGG5GBBGGGGBB~    [email protected]##[email protected]?      .7GGGGGG###BGGGGGBGGGGGG    //
//    GPPGGG575BGPPPGB?.    5&##BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB#P.     .!GGGGG##BBGGGBGGGGGGGG    //
//    PPPGGGGGBGPPPPBY.   .7&&##BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB&G~      !PGPBBBBGGGGBGGGGPPPG    //
//    55PPPPPGGGP55PG7.  [email protected]#BBBBBBBBBBBBBBBBB####&&&&&&&&&&#BBBBBB#####[email protected]^     .JPGBBBPPPGGGGGPPPPGG    //
//    55PPPPPGGG5555J.   [email protected]#&&#####B#&&&&&&&@@&BBB#&#&#&&&&&#B#B7.    :PBBBPPPPPBPPPPP55PP    //
//    5555555PPP5555J.   [email protected]#BBBB&&&&&&&&&&&&&&&@&#B#&&&&&&@@@&&&&&:   .JGGP555PGGGPP5555P5    //
//    YY55555YPPYYY5?.   [email protected]&&##&Y?..!P5YY5J:[email protected]&&#&G?YPPPPG#&&@^    :P55555PGP555555555    //
//    YYYYYYYY55YYYYY^   :B&BBBBBBBBBBBBBBBBB##&P^    :@@#  [email protected]@5 Y#7^..!#5~~B#!~&B.    .JY5Y5PPP555YYY5YYY    //
//    YJYYYYYY55Y5YJ5Y~   7&&#####BBBBBBBBBBB&&&&#Y:: .&@@GP#@@J ?G.. [email protected]@Y.:#@&.^&:     :YY55555YYYY5YYYYY    //
//    YJJJJJJJYYYYJJJ5?:   :~YG&@&BBBBBBBBBBBBBB#&&&&G5!5Y!!!~~^7#@&BG?^5###?J!~7B:     :JY5555YYJJYYYJJJY    //
//    YJ?JJJJJJJYJJJ?JY7.     :B&#BBBBBBBBBBBBB&&&&&&&&&&#GGGGB&&##&&#&#GGGGG#&#:       :YYYYYYJJJJJJJJJYY    //
//    J?????????JJJ???JJ~.    [email protected]&&#&&#BBB###&&&&&&&&&&&BBBBBB&&&#&&&&&B!        .~YY?JJJJJJJ????JYY    //
//    JJ?7???????JJ??7?J?:    [email protected]@&&@&&@@@&&&##########[email protected]&BB#BB&@~       ^JJJ???????????JJJJ    //
//    ???77777777????777??:   [email protected]#BBBBB&#@&&&@&&&@&@@&&&&&&&####BBBBBBBBBBB##&&@@^     :????7????7777?JJJ??    //
//    7??7777777777??777777^  :#&BBBBBBB#&@&@#5G55#&@&&@@&&@@@@@&&&@@@@@&@@@&&@Y.     .777!~!7777777????77    //
//    77777777777777777!7777^  .B&#BBBBBBB#&@&&&#J!5GGGYYP#######&&GBBBG&@@@B!~      :~7777!7777777?777777    //
//    !7777!!!!77!!!!!!~!!!!^.  .?B&#BBBBBBB#&&@&@&@5J~YY?JJ?!~~~!G?    .?#&&&:     .!7777!!!!!!7777777777    //
//    !!!77!!!!!7!!!!!!!!~^~~..:.~J&@&&##BBBBBB#&&&@&&##BJPP55GGGPG7 .. ^7Y&&@~    .~!!!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!^[email protected]&&&&&&&&&&&&&&#BBBBBBB#&&@@&@@@&&@@@@@&&&&&@@@@&P.  .^~!!!!!!!!!!!!!!!!!!!!!!    //
//    ~~~~!!!~~~~~!!~~~!~^[email protected]#&&&&&&&&&##&&&&&###BBBBBB#&&&&&@&&&&&&&&&&@&&Y:   .^!~!!!!!!!~~~~~!!!!!!!!!!    //
//    ~~~~~~~~~~~~~~~~~::[email protected]&&&&&&&&&&&@BPP&###&&&&&&&&#############&@#G?~.   .^~~~!!!!!!!~~~~~!!!!~~~~~~~    //
//    ~~~~~~~~~~~~~~~~^. [email protected]&#&&&&&&&&&&@:  &&#######&&&&&&&&&&&&&&&&&&#BJ.  ..~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ~~~~~~~~~~~~~~~~^. [email protected]#&&&&&&&&&&&@:  &&&&#################&BJYJB&&&&~  :~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ~~~~~~~~~~~~~^:.~5?#@#&&&&&&&&&PJYJJJ&&&&&#############&&&@5   [email protected]##@7  .^~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ~~~~~~~~~~~~~^. [email protected]&&&&&&&&&&&&@^  &&&&&&&&&&&#######&&&&&#@5   [email protected]##@7  :^~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ~~~~~~~~~~~~~^. [email protected]#&&&&&&&&&&&@^  #&&&&&&&&&&&&&&&&&&&&&&#@5   [email protected]##@7  :^~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract aiLE8NS is ERC1155Creator {
    constructor() ERC1155Creator() {}
}