// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pixygon PFPs
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^    //
//    ^^~YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY!^^    //
//    ^^!GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG7^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGP555555555PGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPYJJJY5YYYYYYY5JJJPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPYYYYBBBG#&&&&&&&&&BGG7~!JY5GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG?7?75&&&&&&&&&&&&&&&&&&&##J7?7!?PGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPJ!YG&&&##&&&&&&&&&&&&&&&&&&&&&&PP5JYPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGP?7?#&&#####&&&&&&&&&&&&&&&&&&&&&&&&&&PJYPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG5?~5#&&&###&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#GJYPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG5775#&&####&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&GYJ5GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGGGGGGGGGGGP577P#&&####&#&&&&&&&&&&&&&&&&&&&&&&&&###&&&&&&&&&&BYJ5GGGGGGGGGGGGGGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGGGGGGGGGGG5.5&&&####&&&&&&&&&&&&&&&&&&&&&&&&&&&#JJ55B&&&&&&&&&&#5JYGGGGGGGGGGGGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGGGGGGGGGG55P#&#####&&&&&&&&&&&&&&&&&&&&&&&&&&&[email protected]#55B&&&&&&&&&&BPJ5PGGGGGGGGGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGGGGGGGGP?7?&&##&&&&&&&&&&&&&&&&&&&&&&&&#&&&##G55&@@@@&55B&&&&&&&&&&#7JGGGGGGGGGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGGGGGGGG5 [email protected]&#&&&&&&&&&&&&&&&&&&&&&&#&&&&#BGPYG&@@@@@@@@&GYPB#&&&&&&&BY7PGGGGGGGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGGGGGGG57!G&&#&&&&&&&&&&&&&&&&&&&#&&&&#P555&@@@@@@@@@@@@@@@@&GPGB&&&&&GJGGGGGGGGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGGGGGGP7:#&###&&&&&&&&&&&&&&&&&&##&&#PJB##@@@@@@@@@@@@@@@@@@@@#Y77G#&&&&7YGGGGGGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGGGGGP.~&&&##&&&&&&&&&&&&&&&#&&&&&#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@&Y!7B&&&YJYPGGGGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGGGGY^YB&&#&&&&&&&&&&&&&&&&&##&&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&G7YB&&J~GGGGGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGGGG? B&##&&&&&&&&&&&&&&&#&&&&G55#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&75&&GJ?5GGGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGGG??P#&###&&&&&&&&&&&&&#&&#B5P#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@7Y#&@# JGGGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGGG!?&&###&&&&&&&&&&&&&&&#B5!#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@?!J#@&7J5GGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGGG!7&&##&&&&&&&&&&&&&&&##7?#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&Y~#&&@?!GGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGPYJP&&##&&&&&&&&&&&&&#&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@5~G#&@?7GGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGG5~B&&####&&&&&#B#&&&##&G~&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B?!P&@?7GGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGG5~B&&#####&&G5PPPP#&&&&G~&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&~P&@?7GGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGPYJ5&&###&##BGYJPB5Y5B&G!#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&7P&@?7GGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGGG??5#&&&&B!#&^^[email protected][email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@P!#&&@?!GGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGGGGJ.G#BBPJ!&&^^Y&~^[email protected]?!#G55&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@5!&@&JJ5GGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGGGGG5^~55PB&#GY~~?^[email protected]?!#&#BYP#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&G5B&@#575GGGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGGGG57G&@@[email protected][email protected]?B&&&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&P5B&&#77JGGGGGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGGGGY~&&[email protected]@[email protected]&GJJ!^^#&~B&@@@&[email protected]@@@@@@&&#######&&&&@@@@@@@@#G5#&@G?!YPGGGGGGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGGGGY~&B^?G#&#GJ!~^^7YPPPG&&&#[email protected]@@@PGB&&B77YGGGGGGGGGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGGGGY~&&J!~~~~~^~!!GGGPP5!!~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^!JB##&B5!!75GGGGGGGGGGGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGGGGY~&@@&#BBBBB#&#5PG5~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^?J5&!:PGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGGGGY~&@@@@@@@@@@@@[email protected]?!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~5&&:7PGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGGGGY~&@@@@@@@@@@@@[email protected]&&&#BGGB5?!~~^^^^^^^^^^^^^^^^^^^^~~?B&@&:7PGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGGGGY~&@@@@@@@@@@@@!?GBBB&&&&&&&&&#PYJJJJJJJJJJJJJJJJJ5#&&@&&&&GYYPGGGGGGGGGGGGGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGGGGY~&@@@@@@@@@@@@~^7#&#G##&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@&BYJPGGGGGGGGGGGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGGGGY~&@@@@@@@@@@@@[email protected]@@@@#BGPPPB#&&&&&&&&&&&&&&&&&&&&#BPPPBB#&&&@@B~5GGGGGGGGGGGGGGGGGGGGGGGGGG!^^    //
//    ^^[email protected]@@@@@@@@@@@@@@@@@@@@@#[email protected]#5&&&&@&G?YGGGGGGGGGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGGGGGG.^@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&5#@&&&&!?GGGGGGGGGGGGGGGGGGGGGGGGG!^^    //
//    ^^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&GG&&&&BY7PGGGGGGGGGGGGGGGGGGGGGGG!^^    //
//    ^^!PGGGGGGGGGGGGGGGP?7?#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#G#&&&@5^PGGGGGGGGGGGGGGGGGGGGGGG!^^    //
//    ^^!GGGGGGGGGGGGGGPJ!5PB&&#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Y#@@@5~PGGGGGGGGGGGGGGGGGGGGGGG7^^    //
//    ^^~JYYYYYYYYYYYYJ^!5J5PPP57PBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBG?PGGG7^JYYYYYYYYYYYYYYYYYYYYYYY!^^    //
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PXGPFP is ERC1155Creator {
    constructor() ERC1155Creator("Pixygon PFPs", "PXGPFP") {}
}