// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Working On Dying
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    @&&&@@@@@&&&@@@@@@#&&@@@@@@&#&@@@B#@@@@@&&@@@@@@@@@@@&&&@@@@@@B#@@@@@@@@@&&&&&&&@@@@@@@@@@&&&&&&&&&@    //
//    @!.^&@@@&[email protected]@@@@@[email protected]@@[email protected]&~ [email protected]@@#[email protected]@@@@@@@@&^[email protected]@@@@@? [email protected]@@@@@@@~::^~^^^[email protected]@@@@@B::^^^^^^^B    //
//    @^ .#@&&#. ^@@@@@@@P: ~B5. !#@@~ [email protected]@@&^ ~: [email protected]@@@@@@@&. ^@@@@@@&^ [email protected]@@@@@@: :&@&#~  #@@@@@G  7######@    //
//    @~  ^^^^^  ^@@@@@@@@&! . [email protected]@@P  [email protected]@@! ^@G. [email protected]@@@@@@&: ^@@@@@@@Y .#@@@@@@^ .JJJ?. !&@@@@@G  :[email protected]    //
//    @~ .B###B. ^@@@@@@@@@@!  [email protected]@@@5  #@@7  ^!!.  [email protected]@@@@@&: ^@@@@@@@5  [email protected]@@@@@^ [email protected]@@@@@@G  7&####&@    //
//    @^ .&@@@&. ^@@@@@@@@@@7  [email protected]@@@B  [email protected]?  5BGGB7  P&~:[email protected]&. ^@&~:[email protected]@? :&@@@@@@: :@@@@@@@@@@@@@G  :77777!G    //
//    @[email protected]@@@@[email protected]@@@@@@@@@GY5&@@@@@J ^#[email protected]@@@@@P5P&[email protected]@[email protected]@[email protected] [email protected]@@@@@@[email protected]@@@@@@@@@@@@&555555555#    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@J:[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@7^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@YJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ&@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@&GGG?77777777777777777777777777777777777777777777777777!~~!JJJ&@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@&@#???~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~^  :JJJ&@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@#YY?...                                                   ^J?JJJJ&@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@#GGY~~~::::::::::::::::::::::::::::::::::::::::::::::::::::::~JJJJJJ&@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@P?J!  .~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!JJJJJJ&@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@PJJ!  .~~~??????????????????????????????????????????JJJ:  ^~~!JJJJJJ&@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@PJJ!  .~~~PGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGJJJ:  :~~!JJJJJJ&@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@PJJ!  .~~~&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&JJJ:  :~~!JJJJJJ&@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@PJJ!  .~~~&@@GPPPPPP5PPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5JJJ:  :~~!JJJJJJ&@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@PJJ!  .~~~&@@G55Y??YBBBBBBBBBBBBBBBBBBBP555555555555JJJ:  :~~!JJJJJJ&@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@PJJ!  .~~~&@@[email protected]@@&&&&&&&&&&&&&@@@P555555555555JJJ:  :~~!JJJJJJ&@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@PJJ!  .~~~&@@G5PJ!!7YYJ:.......... [email protected]@@P555555555555JJJ:  :~~!JJJJJJ&@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@PJJ!  .~~~&@@G5PYJJJJJ?   7JJ??????Y&&&BGGBBBG555555JJJ:  :~~!JJJJJJ&@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@PJJ!  .~~~&@@G55PPP5JJ?   G&&#######BBBBBB&@@B555555JJJ:  :~~!JJJJJJ&@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@PJJ!  .~~~&@@G555555JJ?   [email protected]@B555555JJJ:  :~~!JJJJJJ&@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@PJJ!  .~~~&@@G55555PGGGJJJJJJ^            [email protected]@B555555JJJ:  :~~!JJJJJJ&@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@PJJ!  .~~~&@@[email protected]@@@@@YJJ^            [email protected]@B555555JJJ:  :~~!JJJJJJ&@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@PJJ!  .~~~&@@G555555PPPPPPJJJ^            [email protected]@B555555JJJ:  :~~!JJJJJJ&@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@PJJ!  .~~~&@@G555555555555GGG5JJJJJJJJJJJJ#@@B555555JJJ:  :~~!JJJJJJ&@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@PJJ!  .~~~#@&P555555555555&@@@@@@@@@@@@@@@@&@B555555JJJ:  :~~!JJJJJJ&@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@PJJ!  .~~~JYYYJJJJJJJJJJJJYYYYYYYYYYYYYYYYYYYYJJJJJJJJJ:  :~~!JJJJJJ&@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@PJJ!  .~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.  :~~!JJJJJJ&@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@PJJ!  .~~~                                                ^~~!JJJJJJ&@@@&&&&&@@@@    //
//    @@@@@@@@@@@@@@@@@@@PJJ!  .~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~~~!JJJJJJ&@@[email protected]@@    //
//    @@@@@@@@@@@@@@@@@@@PJJ7~~~77777777[email protected]@@    //
//    @@@@@@@@@@@@@@@@@@@PJYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYJ5&@&[email protected]@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#[email protected]@@    //
//    @@@@@@@@@@@@@GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG[email protected]@@    //
//    @@@@@@@@@@&@#?????????????????????[email protected]@@    //
//    @@@@@@@@@#YYJ........................................................................ [email protected]@@    //
//    @@@@@@@@@#JJ?   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::[email protected]@@    //
//    @@@@@@@@@#JJ?   ~~~~~~~~~~~~~~~~~~[email protected]@@    //
//    @@@@@@@@@#JJ?   ^~~~~~~~~~~~~~~~~~[email protected]@@    //
//    @@@@@@@@@#JJ?   ^~~~~~~!!!!!!~~~~~[email protected]@@    //
//    @@@@@@@@@#JJ?   ^~~~~~!??????~~~~~~~~~~~~~~~~~~^[email protected]&&&&&&&&&&&&&&&&&&@@@&&&&&&&&@P^[email protected]@@    //
//    @@@@@@@@@#JJ?   ^~~~~~?PPPPPP!~~~~[email protected]@@    //
//    @@@@@@@@@#JJ?   ^~~~~~!JJJJJ?~~~~~[email protected]@@    //
//    @@@@@@@@@#JJ?...~~~!!!~^^~~~~!!!~~[email protected]@@    //
//    @@@@@@@@@#[email protected]@Y  :??J&@@~  [email protected]@#.  [email protected]@5  :??J#@@!  [email protected]@#.  [email protected]@5  ^&&&[email protected]&@@@@    //
//    @@@@@@#GG5~~!JJJPGGYJJ7~~7GGGJJJ!~~JGGPJJJ~~~PGG5JJ?~~!GGGJJJ!~~JGGPJJJ~~~5GG5JJ?~~!GGGGGGGGG#@@@@@@    //
//    @@@@&@P??!  :JYY#@@7  [email protected]@&:  [email protected]@P  .YYY#@@7  [email protected]@&:  [email protected]@P  .JYY#@@?  ^YJJJJJ&@@@@@@@@@@@@    //
//    @@@PYY!  ^[email protected]@@[email protected]@#YYYJJ?#@@[email protected]@@[email protected]@#[email protected]@GYYYJJJ&@@5YYJJJJJJJJJJ&@@@@@@@@@@@@    //
//    GGG7~~:  .~~!JJJ!~~~~~7JJ?~~~~~~?JJ7~~~~~!JJJ!~~~~~7JJ?~~~~~~?JJ7~~~~~~JJJ!~~!77?JJJGGG&@@@@@@@@@@@@    //
//    JJJ:                                                                         ^[email protected]@@@@@@@@@@@@@@@    //
//    JJJ~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^[email protected]&&@@@@@@@@@@@@@@@@    //
//    GGG555555555555555[email protected]@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract HYAIPE is ERC721Creator {
    constructor() ERC721Creator("Working On Dying", "HYAIPE") {}
}