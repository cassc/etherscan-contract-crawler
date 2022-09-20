// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Art Cosmic Waves
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                           ^~!!^.                                                               //
//                                                    :^~!!?Y577?Y5???7!!^:^:.                                                    //
//                                                  .?5?77?7??JG5^?J?~!77JJJJYJ^.                                                 //
//                                                 !5Y!J?J5#&&&@##&@#GPP?~?7?^?YY7~.                                              //
//                                               :JP!J#@@@@@@@@@@@@@@@@&&B&&#P5JJ?JYJ7!^:.                                        //
//                                        :^^:  ^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@BJY?7?JY5~                                       //
//                                       ~G??G~ !B^?&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#JG77B:                                      //
//                                       ~G??G~.!#^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#!!B:                                      //
//                                        :^!7YB&#^[email protected]@@&BPYYJY5P#&@@@@@@@@@@@@@@@@@@@@GJ:55                                       //
//                                        ^JB&@@@G:[email protected]@@GJ7!!!!!7?JYPPGBB#@@@@@@@@@@@@#Y~:B?                                       //
//                                     .~5#@@@@@@P^#@@#5?7!!!!!!!!!!??7J5GGB&&@@@&&BG5!7Y&G~.                                     //
//                                    ~5&@@@@@@@@5^#@@BGGGBBBGP?7!!7?PGBBBBBBB&@#[email protected]@@@&P~                                    //
//                                  :J#@@@@@@@&BP~7BB#&&&&&&&#B5YYYY5B#&&&&&&&BBG7:JP#@@@@@@@#J:                                  //
//                                 ^[email protected]@@@@@@@[email protected]@@#[email protected]&BBPPBB&@B?!?#@@@[email protected]@@@@@@@G~                                 //
//                                !#@@@@@@@@&^JJJJ5#[email protected]@@P: [email protected]@[email protected]@Y. [email protected]@@#&G555Y^&@@@@@@@@#!                                //
//                               !#@@@@@@@@@#~?555YGBB&@@BPG&&BP7~!JGB&&[email protected]@&#B#GGGPJ~#@@@@@@@@@#!                               //
//                              ~#@@@@@@@@@@@#J!55PBPJ5GBBBBGP5?777?5GGBBBBBGP5G#BGP!J#@@@@@@@@@@@#~                              //
//                             [email protected]@@@@@@@@@@@@@5~55BG7~!7777??Y5P55GPPYJJJYYJJYG#[email protected]@@@@@@@@@@@@@G.                             //
//                             [email protected]@@@@@@@@@@@@@@@?!YP#Y7~~~~!7?YB#BB#BP5Y??JJYY5#[email protected]@@@@@@@@@@@@@@@?                             //
//                            [email protected]@@@@@@@@@@@@@@@#[email protected]#57!!?P#&&&&##&&@&&B5YYYP#@Y!?#@@@@@@@@@@@@@@@@G.                            //
//                            ^&@@@@@@@@@@@@@@@@@@[email protected]@&PJP&&GP5YJJJY5PGB&&G5G&@@[email protected]@@@@@@@@@@@@@@@@@&~                            //
//                            [email protected]@@@@@@@@@@@@@@@@@@J!&@@&#@@[email protected]@&&@@&[email protected]@@@@@@@@@@@@@@@@@@7                            //
//                            [email protected]@@@@@@@@@@@@@@@@@@G^[email protected]@@@@@5!~!Y&&&&[email protected]@@@@@G^[email protected]@@@@@@@@@@@@@@@@@@7                            //
//                            [email protected]@@@@@@@@@@@@@@@@@@@[email protected]@@@@&PPB&@@@@&#BB&@@@@@[email protected]@@@@@@@@@@@@@@@@@@@!                            //
//                            ^#@@@@@@@@@@@@@@@@@@@&[email protected]@@@@@@@@@@@@@@@@@@@G?7Y&@@@@@@@@@@@@@@@@@@@&^                            //
//                            [email protected]@@@@@@@@@@@@@@@@@@@@&G7JB#@@@@@@@@@@@@@@#BJ7G&@@@@@@@@@@@@@@@@@@@@@G.                            //
//                             !&@@@@@@@@@@@@@@@@@@@@@@&Y7~P&@@@@@@@@@@&P~7Y&@@@@@@@@@@@@@@@@@@@@@@&!                             //
//                             [email protected]@@@@@@@@@@@@@@@@@@@@#Y??75?Y#&@@@@@&BGG7??Y#@@@@@@@@@@@@@@@@@@@@@5.                             //
//                              :[email protected]@@@@@@@@@@@@@@@@@&Y7YGPG5!7JJ5GGGGBGGB#BBY7Y&@@@@@@@@@@@@@@@@@@B^                              //
//                               ^[email protected]@@@@@@@@@@@@@@@P!JGGBBG7!!?7??JY5GGGG###[email protected]@@@@@@@@@@@@@@@B^                               //
//                                ^[email protected]@@@@@@@@@@@@&J!PP55#&P7!!7??JJYPGGGG#@&B#BG!J&@@@@@@@@@@@@@G^                                //
//                                 :Y&@@@@@@@@@@B77PBPJ5P&#BY?7??JY5PGGB#&&BBB#&[email protected]@@@@@@@@@&5:                                 //
//                                  [email protected]@@@@@@@&!7GP5G5YG#BB#BP5555PGB#&&&&#G#&#B#7!&@@@@@@@@B7.                                  //
//                                    :[email protected]@@@@@@J^BG55BPBBG?JB&PPGB#&&&BG&BB#&BB&#~?&@@@@@@#J:                                    //
//                                      :[email protected]@@BJ75PGGPG&#B#Y!B#^.!!!!7?Y5GG#@#####[email protected]@@B?:                                      //
//                                        :5#J75GPYG&#&P^:G&B&#:^#&#[email protected]@&@&&@&BP?#5:                                        //
//                                        [email protected]@&Y:: [email protected]@@#:^&@#P?~~?P#&P5&@@@@@@&J!G!                                        //
//                                       7G!?#BGG#@@#7:JG:~&@@B.^Y7~!YG&@&#B~.JYJJ#@@&&?!G!                                       //
//                                      ~B!?GPPG&@@B~ !55:[email protected]@B. :YB&@@@G!!!~ ^J5P&@&###!7B:                                      //
//                                      ~G??J?Y&@@P^^7???! [email protected]@B..:!G&@@@@#&&#^:#@@@&YJJJ7?G^                                      //
//                                       :!77P&@&Y:7#@@@@B.~&@G.!B?^[email protected]@@&#&@? [email protected]#G5?7777!:                                       //
//                                          ^[email protected]&7:J#P5YYB&[email protected][email protected]&G7^?&B^:~#G.~&P.                                               //
//                                          .:P#5P#?.   !&[email protected]@5?GGPBJ.  5&7^B#:                                               //
//                                            .~!!:      ~JYJG#YG#! .^^:    ^PGPGJ.                                               //
//                                                           .~7!:           .::.                                                 //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ACW21 is ERC1155Creator {
    constructor() ERC1155Creator() {}
}