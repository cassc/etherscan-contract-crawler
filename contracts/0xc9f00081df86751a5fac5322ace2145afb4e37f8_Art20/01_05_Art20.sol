// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cosmic Waves
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                            .                                                                                 //
//                                                                       .~PP55PP!....                                                                          //
//                                                                ^7Y55PG557.^?^~BP555PP55?~!7~:                                                                //
//                                                              .P#!^.:~^7?YP#&7:!JY!..:~^!777?GB~.                                                             //
//                                                            .J#Y:77JJP&@@@@@@&@@@@&BBBP^:?!77 7YB57:                                                          //
//                                                           ^#P:!#@@@@@@@@@@@@@@@@@@@@@@&B&@&#JY^!!7PG?~:.                                                     //
//                                                         [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&5:~7JYGP5Y^                                                 //
//                                                 ~JYJ~   P&.^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&#5?:!~!#G                                                //
//                                                ?&!:!&7  5&.:&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@5&&[email protected]~                                               //
//                                                ^#575#^  [email protected]:^@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G [email protected]~                                               //
//                                                 .:~^^!P&@&[email protected]@@@@@&#GGPPGB#&@@@@@@@@@@@@@@@@@@@@@@@@@@@&G! B#                                                //
//                                                  .~G&@@@@# [email protected]@@@@GJ7~^^^^^!J5G#&&&@@@@@@@@@@@@@@@@@@@@&P7..&Y                                                //
//                                                .Y&@@@@@@@G [email protected]@@@&Y7~^^^^^^~~^~~!?JPY5P#@@@@@@@@@@@@@@@&Y. :@5                                                //
//                                              :[email protected]@@@@@@@@@P #@@@&P?7!!!!!~~^^^^^~!7!~75GG5G&&@@@@@&&&PP~.YB&@@P:                                              //
//                                            [email protected]@@@@@@@@@@@5 [email protected]@@&#&&&&&&&&#J!~~~~!J#&&&&&&&&&#@@@G.:!!^^[email protected]@@@@@@P.                                            //
//                                           ?&@@@@@@@@@@@@B.:B&&&&@@@@@@@&&&BYYYYYYB&&&@@@@@@@&&&&B:.JG#@@@@@@@@@@&?                                           //
//                                         :[email protected]@@@@@@@@@&J!!^ J#P&@@@@@#PG&@@@&######&@@@&[email protected]@@@@#P#J ^!!J&@@@@@@@@@@B:                                         //
//                                        ~&@@@@@@@@@@@:^[email protected]#@@@@@?   [email protected]@@#BYYB#@@@#.   [email protected]@@@@#@5PBPG^:@@@@@@@@@@@&!                                        //
//                                       [email protected]@@@@@@@@@@@B 5JY?7J#@&@@@@P. .^&@@##J~~Y##@@&~. [email protected]@@@&@&GPPGG5 [email protected]@@@@@@@@@@@?                                       //
//                                      [email protected]@@@@@@@@@@@@B.!PPPPGG&#&@@@@@&&@@@##J^^^~G&&@@@&&@@@@@&#&&&&#BG!.#@@@@@@@@@@@@@?                                      //
//                                     [email protected]@@@@@@@@@@@@@@&?:JGPB#&YJG##&&&&&#BGJ~~!!!YB###&&&&&&#BGP&&&##Y:J&@@@@@@@@@@@@@@@!                                     //
//                                    .&@@@@@@@@@@@@@@@@@G.?BP#@Y^^[email protected]&B#[email protected]@@@@@@@@@@@@@@@@&:                                    //
//                                    [email protected]@@@@@@@@@@@@@@@@@@P [email protected]^:::::^~!~?P&#GB#&[email protected] [email protected]@@@@@@@@@@@@@@@@@@G                                    //
//                                   ^@@@@@@@@@@@@@@@@@@@@@^:[email protected]&G7~^::^~7J5#&@@@@@@@&BB5?JYYYY5G&@PP:^@@@@@@@@@@@@@@@@@@@@@^                                   //
//                                   [email protected]@@@@@@@@@@@@@@@@@@@@&J.^&@@G?~~!J#@@@@@@@&&@@@@@@@&[email protected]@&^.J&@@@@@@@@@@@@@@@@@@@@@P                                   //
//                                   &@@@@@@@@@@@@@@@@@@@@@@@? &@@@#[email protected]@&BGP5YJ??J5PGB#&@@#PG&@@@& [email protected]@@@@@@@@@@@@@@@@@@@@@@&                                   //
//                                  [email protected]@@@@@@@@@@@@@@@@@@@@@@@Y #@@@@&&@@&Y77!!!!777JYY55G&@@@&@@@@# [email protected]@@@@@@@@@@@@@@@@@@@@@@@:                                  //
//                                  :@@@@@@@@@@@@@@@@@@@@@@@@B [email protected]@@@@@@@G~^^^~B&&&&#YYY55&@@@@@@@@P [email protected]@@@@@@@@@@@@@@@@@@@@@@@^                                  //
//                                  :@@@@@@@@@@@@@@@@@@@@@@@@@~.#@@@@@@@&[email protected]@@@@@[email protected]@@@@@@@#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@^                                  //
//                                  [email protected]@@@@@@@@@@@@@@@@@@@@@@@@&^^&@@@@@@@&#&@@@@@@@@@@@&@@@@@@@@&^^&@@@@@@@@@@@@@@@@@@@@@@@@@.                                  //
//                                   #@@@@@@@@@@@@@@@@@@@@@@@@@&!^^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@G^^!&@@@@@@@@@@@@@@@@@@@@@@@@@&                                   //
//                                   [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@G^~#@@@@@@@@@@@@@@@@@@@@@@#~^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@Y                                   //
//                                   [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Y:[email protected]@@@@@@@@@@@@@@@B~~:[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:                                   //
//                                    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@&P?.~#B&@@@@@@@@@@@&@~.?P&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Y                                    //
//                                    .#@@@@@@@@@@@@@@@@@@@@@@@@@@#7^?JYBJ^?B&@@@@@@@&#B##YY?^7#@@@@@@@@@@@@@@@@@@@@@@@@@@#.                                    //
//                                     :&@@@@@@@@@@@@@@@@@@@@@@@&?:J#BBB#~^~J7JPGBBB#&#B#@@&&#J:?&@@@@@@@@@@@@@@@@@@@@@@@&:                                     //
//                                      ^&@@@@@@@@@@@@@@@@@@@@@5:7#B####J^^^?7!7?JY5G#B###@&@&&#7:[email protected]@@@@@@@@@@@@@@@@@@@@&^                                      //
//                                       ^&@@@@@@@@@@@@@@@@@@&~^G#BP#@@B!~^^!?77?JY5B#BB##&@@&&&&G^~&@@@@@@@@@@@@@@@@@@&^                                       //
//                                        [email protected]@@@@@@@@@@@@@@@G:7&&5YPP&@&P7~~~77?JY5PBBBB#&@@@&&&&@&7:[email protected]@@@@@@@@@@@@@@@B:                                        //
//                                          [email protected]@@@@@@@@@@@@@J.YBP#[email protected]@@&P?77??JY5PBB#&@@@@&#&#&@@&[email protected]@@@@@@@@@@@@@Y                                          //
//                                           ^[email protected]@@@@@@@@@@G Y&G5P&GJG&@&&&&&#GGGPPGB#&@@@@@@&&#@@&&&@Y [email protected]@@@@@@@@@@B^                                           //
//                                             !#@@@@@@@@@@^.&&G5P&BP&&#J75&@&B&&&@@@@@&B&@&&&@@&#&@&.:&@@@@@@@@@#!                                             //
//                                               !#@@@@@@&7:J&##PGG&@@@@Y^[email protected]@! .::~7JPB#&&@@@@@&&&@@@G^[email protected]@@@@@#7                                               //
//                                                 ^[email protected]@&J:?##YY&&B&@#[email protected]@[email protected]@^ ^#G5?!^:...:[email protected]@@&@@@&@@575#@@G~                                                 //
//                                                  !&Y:7#&GPP&@@@@G.  [email protected]@@@@^ [email protected]@@@@@B?. [email protected]@@@@@@@@@@@#:[email protected]                                                  //
//                                                 !&?.G&BPJP&@@@@J .. [email protected]@@@@: [email protected]@&B?:.:?B&@@&[email protected]@@@@@@@@@B.J&~                                                 //
//                                                !&[email protected]&#&#&@@@&~ :#P .&@@@@: !P!..^Y#@@@@@@G  5G5JJ&@@@@@P.J&!                                                //
//                                               ~&?.G#GGG&@@@@#: ^#&B  [email protected]@@@.  .!P&@@@@@P^::.   ^~!J&@@@@&@5 Y&:                                               //
//                                               P&.^P555#@@@@P.  .::.  [email protected]@@@.  [email protected]@@@@@@#PG#&Y .&@@@@@&GGGGG::@?                                               //
//                                               [email protected]@@@? .G#&&&&J .&@@@. ~^ ^[email protected]@@@@@@@@@&. [email protected]@@@@#JJJJJYGP.                                               //
//                                                 ..:^[email protected]@@&^ ^&@@@@@@&  [email protected]@@. [email protected]^ ^[email protected]@@@&&&@@7 :@@#G5^::::::.                                                 //
//                                                    7&@@B. [email protected]@[email protected]@^ [email protected]@&. [email protected]@@G: ^&@P.  [email protected]#  [email protected]                                                           //
//                                                     .#@[email protected]#^     [email protected][email protected]@&. [email protected]?&@GP&@7   :@@^ [email protected]&.                                                          //
//                                                      .JGBG?.      .P&&&&@@^:#@Y .~JJ7:     [email protected]#[email protected]#                                                           //
//                                                                      ...?#&&#Y.             ~YP5!.                                                           //
//                                                                           ..                                                                                 //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Art20 is ERC1155Creator {
    constructor() ERC1155Creator() {}
}