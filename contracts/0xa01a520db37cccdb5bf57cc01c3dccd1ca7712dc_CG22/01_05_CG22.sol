// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Chaos Glitch
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                     :!J5GBBBBBBBBBBBGPJ!:                                                                  //
//                 ^?PBBPY?!^:.......:^~7YPBB5!.                         .^!7JY5555YY?7~:.                    //
//              ^JB#P?^.                   .~JB#P~                    ^JPBBPYJ?7!!!7?J5PBBGY!:                //
//            7G&P!.                           ^5&G~               .?B#57:               :!YG#G?:             //
//          7#&Y^                                :[email protected]             ?&#7.                      :7G&P~           //
//        ^[email protected]^                     ....           [email protected]         :[email protected]?                            ^5&G~         //
//       [email protected]!.                    .?Y5YYJ?!^        [email protected]        [email protected]~        .:^^^^.                :[email protected]       //
//      [email protected]^:                      7&&&##GP5Y!       [email protected]       [email protected]      :!J5PGGG5.                  [email protected]:      //
//     [email protected]^:                ^:   .!#@@@@@@@B5PY:     .&#.     ^@B      75PB&@@@@#:    .              ~&&^     //
//    ^&#~::               :5YYGB#@@@@@@@@@@#Y5Y      [email protected]^     [email protected]     ?P5&@@@@@@@&PJ??5^              [email protected]    //
//    [email protected]:^.               [email protected]@@@@@@@@@@@@@J?Y^     [email protected]~     [email protected]    :[email protected]@@@@@@@@@@@55J              [email protected]    //
//    &&7^^:               ~J7?&@@@@@@@@@@@@B77J:     #@:     :@#    .J7J&@@@@@@@@@@B?J?              [email protected]#    //
//    @&!^^:                [email protected]@@@@@@@@&5~~77     [email protected]       [email protected]?    ~!:~5&@@@@@@&5~7J.              :^#@    //
//    &&7^:^.               .7?!~?5B###BGY:   .     [email protected]^       [email protected]~        !YY55Y?!!7!.              .:~&&    //
//    [email protected]~^^^.                :!77!!~!!!!7:         [email protected]         :#@~      .!!!!!!!!^.                ::[email protected]    //
//    ^&&!~^^^:                 .:^~~!!~~^.       [email protected]?           [email protected]       ....                  .::!&&:    //
//     [email protected]!~^^^:.                                !#&!              ?&#?:                         .::^7&&~     //
//      [email protected]#7~~^^^::.                          [email protected]:                .J&#Y~..                  .:::^[email protected]^      //
//       ^[email protected]~~^^^^::..                  ..:7G&P^               .:   .7G&BY!^:............:::^^~?P&#7        //
//         7B&P?!~~^^^^^::::..........:::~75##Y^   ::             :!!^   :?P##G5J7!~~^^^^~~!!?YG##5!          //
//           ~5##PJ7!~~^^^^^^^^^^^^^~!?YG##5!.  :~!^                :7J?~.   ^7YPBBBBBBBBBBBBG5?~.   :^.      //
//        ..   .~JGBBBP5YJJJ?JJJY5PGBBB5?^   :7J?^                     ^?Y5J!:    .::^~~~^:.     :~7!^        //
//         :^!~^.   :~7JY5PPPPP5YJ?!^.   :!J5J!.                          :!J5P5Y?!~^::..::^~!?JJ?~.          //
//            :~7?J?!~^..        .:^~7J555?~.                                 .:~7JYY55555YJ?7~:              //
//                .^!7JY5555555PPP5YJ7~:.                                                                     //
//                        ......                                            ..                                //
//                                                                      ^?PB##BP7.                            //
//                                                                  .!YB&@@&#BB#@&?                           //
//                                                              .^JG#&@#&#Y7G&B#[email protected]                         //
//                                                         .:!JPBB57:^[email protected]!   P&?^^[email protected]                        //
//                                       .^~7?JJYYYYYY55PGB#@#Y!:     ~G!.   .!:.:^[email protected]                        //
//                                    ^JGBGP5JJ??777777!!J&@P^      . ^~^..  .^.  :^[email protected]                       //
//                                  7B&G5:    :: .        75^:      ^:^~^:.  Y^   :[email protected]#.                      //
//                                !B&Y~~5?   .^5~^.      .!7::.....:^~5!:::.7#:  .^?&@@7                      //
//                              [email protected]#~:[email protected]#&G5YJ???JYB&5YJJJJY5G#&GPPPG&&^  :?#&#@P                      //
//                             :#@#&[email protected]#B#&&&##&&&&&&&&&&&&&&&&&&&&##&&&&#[email protected] ~P&&[email protected]                      //
//                            [email protected]#BB#&B#@BBB###############################BB&&P&&BBB#@J                      //
//                         ?: [email protected]&BBBBB###BBB######&&&&&&######&&&&&&#######BB###BBBB&@P.                      //
//                         G! [email protected]&BBBBBB#&&#B##&&&&BBGGGB#&&&&#BGGGG##&&&###B###B##&@B7                        //
//                         J#: [email protected]@##B#@#J?&&&@#G5J?77777?JYYJ?77???Y5GB&@@&@@#@&BPJ^                          //
//                          JB?:^?5GB#&BGG#&&&#BB###BBBBBBBBBBBBBBBBBBGPP5YJ7!^:                              //
//                           :?55J7!~:.:::::::^^^^^^^^^^^^^^^^::::...                                         //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CG22 is ERC721Creator {
    constructor() ERC721Creator("Chaos Glitch", "CG22") {}
}