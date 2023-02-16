// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Eric Pause Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                 .          //
//                                                                                             .:~7YG#&@@!    //
//                  .^~?PG:~?Y5GG57:                                                  .^!?5G#&@@@@@@@@@@@!    //
//                  [email protected]@@&~:...^J&@@&7                          ...:^       .   .:!5#@@@@@@@@@@@@@@@@@@@@!    //
//     .:^~!7 .55PGBP [email protected]@5        [email protected]@@B   P7     ...:~^       ?YP&@@@? 7PB&G: ^G##[email protected]@@@@@@@@@@@@@@@@@!    //
//    :@@@&##:[email protected]@?&@@?         [email protected]@@J #@@~   [email protected]@@@.         [email protected]@@B #@@@:  &@@@@@# :@@@@&&&@@@@@@@@@@@!    //
//    [email protected]@7~BB~ G&&.#@#@@@~         [email protected]@@BB#@@@:     [email protected]@@7         [email protected]@@@.#@@@J  .Y&@@@@[email protected][email protected]@@@@@@!    //
//     #@[email protected]@B &@@[email protected]@@@@.         [email protected]@@@Y [email protected]@&.    [email protected]@@B          [email protected]@@[email protected]@@@G.   :Y&@@#.~&@@@&?   [email protected]@@@@@!    //
//     [email protected]#[email protected]@& [email protected]@[email protected]@@@@.         [email protected]@@Y   [email protected]@&    [email protected]@@@          [email protected]@@[email protected]@@@@@B7.   !B  YPPPGB##&@@@@@@@@!    //
//     [email protected]@:&@& ^&@[email protected]@@@@?        [email protected]@@5    .&@@B    #@@@~         :@@@&&@&[email protected]@@@@@5      &@@@@@@@@@@@@@@@@!    //
//     :@@??P5: [email protected]@@@@@G!:::~J#&5&P      :@@@P   [email protected]@@5          &@@@@@P #@@@@@@P     ^&@@@@@@@@G!&&&BG:    //
//      B&&&##7 55YJ?&@@5 :~~~~^:  YP        [email protected]@@J  :@@@&          [email protected]@@@#^ .5P5YJJ:  ..   ^:::....            //
//                   &@@7       .~#@5..    [email protected]@@@5. &@@@:        :&@@@@?~:                                   //
//                  [email protected]@@^       ^77!7!~    :!7!!!!7! [email protected]@@&:    .^5B~&@@#Y~.                                   //
//                ^[email protected]@@P:.                           :G&@@&#BBPJ^  ~^                                        //
//                :^^~~!777.                             ..:..                                                //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PAUSE is ERC1155Creator {
    constructor() ERC1155Creator("Eric Pause Editions", "PAUSE") {}
}