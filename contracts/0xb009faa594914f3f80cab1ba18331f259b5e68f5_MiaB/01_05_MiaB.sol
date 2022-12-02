// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Menina in a Box
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                            .^7J5G#BPPPP5YJ??77!!~^::..                                     //
//                                       :[email protected]@#?!~!7?JJYJJY5PPGGB##BBGPP5Y??!~:..                       //
//                                  .~?5PPY7~:    [email protected]~                 .:^^~!7?JY5PGBBGGGPPP5YY?!^.            //
//                            .^!JYP5Y7^.         ^@~                               ..::^~!!7?Y5PPGY^         //
//                       .~7J5PYJ7^.              [email protected]^                                          [email protected]@#.        //
//                  .^!J55Y?~:                    [email protected]^                                     .^7YY5PP5B&.        //
//              :!JY5Y?~:                         [email protected]^                                 .^7YYJ7^     5B         //
//          :[email protected]@?:.                             [email protected]:  ..:^^::..                  .^7JY?!:        .#J         //
//          [email protected]&5???J??77!~^::.                    [email protected]~^~77::~!~!!~:            :~7JJ7~.            :@!         //
//         ^@B.       .:^^^~!777???7!~^^:..       ?J??7!::7J?7!!!J?.     .^~7J?!^.                [email protected]~         //
//         ^@Y                  .::~!77JJYYYYYJ?7Y55?~??^7YYYJ!~!JY5^:!?JY?!:.                    [email protected]^         //
//         :@5                             ..:^^!#PPPPGGBGBGG#BPGBB#@@B7:                         ?&.         //
//         .&G                                  .G557!J7?7J?J!YGY#@@@?                            Y&.         //
//         .#B                                   [email protected]&G7BJ??!?Y.:[email protected]@5                             P#          //
//         .&B                                   [email protected]?JBPY5! [email protected]                             GB          //
//         .&B                                   [email protected]^^! .~^  7:[email protected]                            G#          //
//          BB                                   !&P?^^^    .!^[email protected]                           P#.         //
//          5&.                                  [email protected]??Y7:                          [email protected]:         //
//          [email protected]^                                  ?P7JG?PJ:~^:[email protected]?JYJ:                         [email protected]~         //
//          [email protected]!                                  J?!5??7    ~?Y: ^@! JYYP                         [email protected]!         //
//          ^@7                                  ?YY5?5    !J?:  ~&! ^J75:                        ^@7         //
//          .#Y                                  ?#PJJ!   !?!    Y&7  5Y5:                        :@?         //
//           BG                                  YBG?~5. .Y!.?. 7Y&7  JYJ~                        .&?         //
//           GB                                  P&7.~Y.  J. :.7Y:@? ~~GP.                        .&J         //
//           Y&.                                :&@Y  ^J:     .?.:@Y?^.Y:                          B5         //
//           [email protected]:                .^^~~~^^^^:::..:[email protected]@Y   P~.:...?: .#B~. J                           GG         //
//           [email protected]!              :7~:....!^::::^^~?GPG!  ^7  ^. ?~   #Y.  J                           GB         //
//           :@7             :?.      :^^~~^.    .!!  57    ~7   ~BJ^~~J::^^.                      GG         //
//           ^@7             7!           .:~!^.  :~  #B   ^?  .JYG#?77!!:.^~?J?7~^^:..            BB         //
//           :@J              !J7:            :~!^~~ ^@&:~^J:^~?7:JB         :5!7?JY555P5YYJ??!~^^[email protected]         //
//            BG          :!YPP5?~!~:.           [email protected]#J7~^..    !#          J:      ..:^~!!?JYP&@@J         //
//            P&.     :!5GG57^.    :^~~~^^:.        .:~!~^^^^     ~#.    ...:!!                 .&@G:         //
//            [email protected]?^              .:~J~~~^::.     ....^J:^^^7&^:..:::::.              .^?5GP!           //
//             [email protected]@&Y!:                   .7.  ..:^~!!..      J....^&:                   :!JPGPJ~.             //
//             .?5PYJ?!~^.              .J!~.  .:^^:..!~     7:   :&^               ^7YPG57^.                 //
//                 :~7?Y5PP5Y?!^:.       :!7!~~:       ^7:  .:7   .#~          :~J5PPJ!:                      //
//                        .^!?Y5PP55J?!~^:.::.          .?~?Y!:    B7      .!JPPY7^.                          //
//                               .:^!?JJ55PPPP55YJ?7~^:. :?7^     ^&P..^!J5P5!:                               //
//                                          ..:^^!7?J5PPP55JJ??7!J&@@B5Y?!^                                   //
//                                                      .:^~!!????7!^.                                        //
//                                                                                                            //
//                                                                                                            //
//                       __  ___           _                _                   ____                          //
//                      /  |/  /__  ____  (_)___  ____ _   (_)___     ____ _   / __ )____  _  __              //
//                     / /|_/ / _ \/ __ \/ / __ \/ __ `/  / / __ \   / __ `/  / __  / __ \| |/_/              //
//                    / /  / /  __/ / / / / / / / /_/ /  / / / / /  / /_/ /  / /_/ / /_/ />  <                //
//                   /_/  /_/\___/_/ /_/_/_/ /_/\__,_/  /_/_/ /_/   \__,_/  /_____/\____/_/|_|                //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MiaB is ERC1155Creator {
    constructor() ERC1155Creator("Menina in a Box", "MiaB") {}
}