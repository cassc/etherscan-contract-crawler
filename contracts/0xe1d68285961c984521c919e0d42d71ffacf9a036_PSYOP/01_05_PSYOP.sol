// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SOUL PUPPET
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                    ^  ..                                                       //
//                                                                !!^7^7~:!:.~^  ..                                               //
//                                                             : ??7B^.5?:^57:!??7?                                               //
//                                                            ^JY#P#PJBB5P#GPY5BP!JJ^:7                                           //
//                                                        ..::JPGGPP555YJYYP&BGG##B5?7P~^                                         //
//                                                 .:^~~~!7?JY5PPGBBBGPPY: 7GG5YJJYPBBPYPY!:                                      //
//                                            .^!77!!7?J5G#&@@@@@@@@@@PJ??5B#@@@@@&#BGGPG5JYJYYJ?J7~^:...                         //
//                                        .^!!~^^~?5G&@@@@@@@@@@@@@&@@&B&@@@@@@@@@@@@@@@#G5Y5PB&@&&#GPY55Y?7!^:.                  //
//                                   .:~77!^:^[email protected]@@@@@#BGG5J5&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#P55B#@@@@#G5YJ??????!:               //
//                              :^~7YP5?^:7P###PY?JY?!^::^!?YP&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#^^5GB&@&&BP5J?7!!!7?!             //
//                           :!!~^!?7^   ^77!!!77?GG5YPG#@@@@@@@@@@&&#GPP5PBBB#@@@@@@@@@@@@@@@@&G?^!55G&&#BGP5J?77!!7?:           //
//                       :!?J~:     .~77~:[email protected]@@@@@@@@@@@&B5J??????~!P57.?P5?~^JPG#@@@@@@@@@@@@@@@#5?JGB&#BP5Y?7!!~~::Y.          //
//                      !?~^   .^7YGBY~^~5BGG5J?775B##GJ7~^ .!Y!^B&P^&@@[email protected]@@&J!:.!JP5555P&@@@@@@@@@&G?GB####G5Y?77!!^Y7          //
//                    :7!    :[email protected]@@P7^^77~:..~!7J5&@@@@@P: ~#@@&J&@@P^#@@[email protected]@@@@#~G&&5^  ^[email protected]@@@@@@@@@@B!G#&&#G5J?!~^^:57          //
//              .^!~~7?~  !J5PG5P55BP?~!~!7~7J#@@@@&&&##Y  ^[email protected]@[email protected]@@[email protected]@@[email protected]@@@[email protected]@@@^^~:Y&@@@@@@@@@@G~#&@&G5Y?!~^^!G.          //
//             ^J7??:    ^5GGY?^Y5^BPP#@@@@@@#[email protected]@GY7^::!^ ~.!.7! [email protected]@?^[email protected]@^ [email protected]@#^[email protected]@@@#@@5 ^[email protected]@@@@@7J&@@#5J7!~^!G~           //
//             ^7Y5BB!~.~J5Y7^7?JP?Y7~~!!?!7GB!7Y!^  ~J? ^Y J^      ?J: .5J ^@@B~^@@@@&[email protected]#.!YJ^.:[email protected]@@@@#[email protected]@@#G?^:^?5^            //
//              :~5JBY. ^!???^.:^7PPBB#[email protected]&^.GYJ?^              .~~  .?PB5:!&@@#@@@&? :[email protected]@@@@&&@@&BJ!7Y?.             //
//               7~G5J7. :JJ^^^: .::::!P#&&&##&@7  :BG:.5G5PB5                         7GG?G&G#@@#[email protected]@@5##G#J!~^.               //
//               7~5B?^J^  J?:^:.   .:.^JJ!!~?PP: ~~:.?GBPPJ#B~J!:..                       .: :[email protected]@@#:[email protected]&7PP 5:                   //
//               ~~~P&7:7^ .5.:?5Y?!^..~~G#B#&@!.5J?P!B#[email protected]&BP5Y7                         [email protected]@5. ~#@5Y5 Y!                   //
//               ^7 7&@P^~. 7^  !B?!??!...:::~?7JGJP#P&&^:^7YY7?###BB5J7!^:.                    :&@&P!:[email protected]:.5!                   //
//               :5 .?&@#!^ !:   ~J!!!:.~!^^^!?5JY5YYPGG^::~^:^[email protected]^7J~!7?7!~^:.   .::::..     [email protected]@@&?&?~P:!G^                   //
//                Y^ :?P&@? ^.   .~~~~~!77!~^^~~^^:.. .:!77!!7JBG?!:  :J     .:^~~^^?J777??????!^[email protected]&BJY!~&G!#G                    //
//                ~7!?7!?#@J^ .^!?7!!~^:                  .::. :?J7~. ~!           .5...:^!?Y5PGGBP5::[email protected][email protected]                    //
//                 :~!7JY5G#J!!~.                                :~7~~!            .5.:^~!JPB#@@@@#BYG&#YJ#@P                     //
//                      .:^:                                         .              Y! :^^!7J5G#@@@@&[email protected]@#:                     //
//                                                                                  :G:.^^[email protected]@#GJ!!J#@@@Y                      //
//                                                                                   ~P: ::~75#&@&GYP&@@BBPJ                      //
//                                                                                    ~5^ .^[email protected]@@@@@@#5BB~Y                      //
//                                                                                     .?7:..^Y&@@@@@P5&#J?!                      //
//                                                                                       :!7~.:[email protected]#GPG&GJ~J.                      //
//                                                                                          ~J^:P?!J~Y?~:^?                       //
//                                                                                           :5#PYJ. .7!~!.                       //
//                                                                                          !?~&&J     .                          //
//                                                                                        :Y!:^&Y                                 //
//                                                                                       !5!^?:P:                                 //
//                                                                                      J5!7J?~Y.                                 //
//                                                                                     55!?55Y!J                                  //
//                                                                                    55?JB&@PJ~                                  //
//                                                                                   [email protected]@@@PJ                                   //
//                                                                                  [email protected]@@&GP7                                    //
//                                                                                  !GJ&G5Y7:                                     //
//                                                                                  :P77?!:                                       //
//                                                                                   .~:                                          //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PSYOP is ERC1155Creator {
    constructor() ERC1155Creator("SOUL PUPPET", "PSYOP") {}
}