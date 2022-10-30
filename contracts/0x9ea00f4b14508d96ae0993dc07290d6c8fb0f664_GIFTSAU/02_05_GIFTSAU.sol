// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Gifts from SAU
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////
//                                                                                   //
//                                                                                   //
//                                                                                   //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&#BPPG&&@@@@@@@@@@@@@@@@@@@@@@@&#PP&@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@BPYG#####BB#PPP5B#G#&@@@@@@@@@@@@@@P#^[email protected]@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@&5JJG#&&&&&&&&&#PG&#[email protected]@@@@@@PP.  7!! .5&@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@BB?JGB&&&#P5PPP5P555P&#PPBBB#BG5PB&@@@YY!  ::: [email protected]@@@    //
//    @@@@@@@@@@@@@@@@@@@@~5JGBGG5PP555555555555P&&555555PGG###&@@#GP??Y?Y5?&@@@@    //
//    @@@@@@@@@@@@@@@@@@P.5#5YY5555555555555555555&B5555P5555P#&B#@@@&@@@@@@@@@@@    //
//    @@@@@@@@#&@@@@@@&^~GYJ5GP5555555555555555555B&P555GGP5555P##P&@@@@@@@@@@@@@    //
//    @@@@@@@#[email protected]@@&.5B7YG#G5PP5555PG5555555555PBBG5P55PG5PP555G&##@@@@@@@@@@@@    //
//    @@@@@@@[email protected]@@~#P75B#P5PBP5555BB55555P5555P#5P555P5BG?JJ:755&#[email protected]@@@@@@@@@@    //
//    @@@@@@@@@&[email protected]@?&Y75##P5PBPPPPP5&G55555G#555G#55Y7?!JG#YJ5^.?P5#&[email protected]@@@@@@@@@    //
//    @@@@@@@@@@@@@PBP!5#BY5PGY5J7?JP&555555#@555BBGP5P5555BGP557YP55&[email protected]@@@@@@@@    //
//    @@@@@@@@@@@@@7&~5B#.!YPJ!~~?55B#[email protected]@P55#P#&[email protected][email protected]@@@@@@@@    //
//    @@@@@@@@@@@@P557P&P75P5JP5PPP5#G55555#@&55BB5&5GYP555P#[email protected]@@@@@@@@    //
//    @@@@@@@@@@@@~#7JB#5P5GY55P555P#55555B#&P5GB5BB.&JP55PP#&B&G5PG55BG @@@@@@@@    //
//    @@@@@@@@@@@@:&!J#G55PPY555555BG5555B#5&[email protected]^ &J55P#&!:&&&[email protected]^[email protected]@@@@@@    //
//    @@@@@@@@@@@@.&!JGP55PPJ55555BG555P#B!#J55G##7 ^&Y!Y#&7  [email protected]&#7^[email protected]@@@@    //
//    @@@@@@@@@@@@.&!?PP555PJ?5GP#&GBB#G!?#GYYG5!.  ^~:....    .&G5PG5P&~YJ.:@@@@    //
//    @@@@@@@@@@@@^YJ!P#55G5PBP&G77?~^:  :^~:..     :?PBBGP5J^ .&[email protected] [email protected]@@@@@@    //
//    @@@@@@@@@@@@G B~5GBJ#B&5^.  :~~~:..           YBB####&@& ~&PG555#@ #@@@@@@@    //
//    @@@@@@@@@@@@@.?PPPGBG&P..~Y#&@@&&G~                 :^!7^#B#&5P#&&:@@@@@@@@    //
//    @@@@@@@@@@@@@B G55Y5P#^ ^&@&P7^.        .:         .~^~5&G!5&5B#@[email protected]@@@@@@@    //
//    @@@@@@@@@@@@@@~:B5?55GB. ~Y~^^7:              :^!?7!: .7!  &B5&[email protected]^[email protected]&???&@@    //
//    @@@@#YY5#@@@@@# 5JG755BB..~:::..:~77!!~~!!7JG#&&&&&&&5    5&PGB## B& [email protected]@    //
//    @@@!77^.:~?5&@@ ~JGG7YGBB:    ^B#&&&&&&&&###BBBB####&#..^5&#[email protected]# [email protected][email protected]@    //
//    @B~5! ..  ~?:@Y YJY^~JG#BB?.  B&&&BGP55555555555PPGBG:!B#G?~^[email protected]@G?#@@&@@@@@    //
//    @.G. 7J5: ~??G:5P7?&?^BBB&#GJ~!B&GPPPPPPPPPPGGP5J777~^^^!?5&@@@@@@@@@@@@@@@    //
//    @?P!  .. ^[email protected]@@@@@@~75.^GP#G?:.:~!7!~~~~:::.......:[email protected]@@@@@@@@@@@@@@@@@@@@    //
//    @@&[email protected]@@@@@@@@~.:7B5#PPG#B~:^~~~~~!!!7?77?YG&@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@&BB#&@@@@@@@@@@@PYGGP5!7J7?JP&&@&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@#Y??G&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//                                                                                   //
//                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////


contract GIFTSAU is ERC721Creator {
    constructor() ERC721Creator("Gifts from SAU", "GIFTSAU") {}
}