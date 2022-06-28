// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Magnum Photos 75
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                        //
//                                                                                                                                                        //
//                                                                                                                                                        //
//                                                                                                                                                        //
//              :[email protected]@@@#       [email protected]@@@@@7       [email protected]@@@@5        .GM#@@@@@@@BB!   ^@@@@@@^     :@@@P  [email protected]@@?       [email protected]@@&  [email protected]@@@@@G       [email protected]@@@@@^              //
//              :@@@@@@@?     [email protected]@@@@@@7      ^@@@@@@&.      [email protected]@@&Y~::^7&@@@#  [email protected]@@@@@@^    :@@@G  [email protected]@@?       [email protected]@@@  [email protected]@@@@@@~     ^@@@@@@@^              //
//              :@@@[email protected]@@.    #@@[email protected]@@7     .&@@[email protected]@@G     [email protected]@@G       .B###: [email protected]@@[email protected]@@^   :@@@G  [email protected]@@?       [email protected]@@&  [email protected]@@[email protected]@&     &@@?#@@@^              //
//              :@@@G &@@G   [email protected]@& [email protected]@@7     [email protected]@@. [email protected]@@?   [email protected]@@@               [email protected]@@P [email protected]@@~  :@@@G  [email protected]@@?       [email protected]@@&  [email protected]@@[email protected]@@Y   [email protected]@B #@@@^              //
//              :@@@B ^@@@~ [email protected]@@^ [email protected]@@7    [email protected]@@~   #@@@:  [email protected]@#     7&&&###B. [email protected]@@P  [email protected]@@~ :@@@G  [email protected]@@?       [email protected]@@&  [email protected]@@Y [email protected]@@: ^@@@. &@@@^              //
//              :@@@B  [email protected]@& [email protected]@Y  [email protected]@@7   [email protected]@@&[email protected]@@&  [email protected]@@&     5###@@@@. [email protected]@@P   [email protected]@@^[email protected]@@G  [email protected]@@J       [email protected]@@&  [email protected]@@Y  [email protected]@B &@@7  &@@@^              //
//              :@@@B   &@@&@@&   [email protected]@@7  [email protected]@@@@@@@@@@@@@G .&@@@G        @@@@. [email protected]@@P    [email protected]@@[email protected]@@G  [email protected]@@B       [email protected]@@B  [email protected]@@Y  [email protected]@@&@@B   &@@@^              //
//              :@@@B   [email protected]@@@@^   [email protected]@@7  #@@@^[email protected]@@7 .#@@@@7!^::^[email protected]@@@. [email protected]@@P     [email protected]@@@@@G   [email protected]@@#?~^^[email protected]@@&.  [email protected]@@Y   [email protected]@@@@.   &@@@^              //
//              :@@@B    [email protected]@@J    [email protected]@@7 [email protected]@@7        .&@@@.  ^P&@@@@@@@@@@@#. [email protected]@@P      [email protected]@@@@M    ~G&@@@@@@@&G~    [email protected]@@J    [email protected]@@!    #@@@^              //
//               ...      ...      ...  ....           ...       .::^^::..     ...        .....        ..:::..        ...      ...      ...               //
//                                                                                                                                                        //
//               .:::                  ..   .:                  .^^^.                 :^:::^:                 .^^:                    .^^.                //
//              :@#[email protected]                &@   &@.                P&Y7J&B.               JJ#@BY?               :&&[email protected]                :&&!?&P               //
//              :@#[email protected]                &@[email protected]@.               [email protected]   [email protected]                 [email protected]~                 #@.   [email protected]^               .#&5J?^               //
//              :@&~~:                 &@^.:&@.               [email protected]   [email protected]?                 [email protected]!                 [email protected]!   &@.               ^J^:[email protected]@:              //
//              :&5                    G#   G&                 7#G5G#7                  ?&^                  Y#CRBB^                ^#BY5#J               //
//                                                                                                                                                        //
//                                                                                                                                                        //
//                                                                                                                                                        //
//                                                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MPA75 is ERC721Creator {
    constructor() ERC721Creator("Magnum Photos 75", "MPA75") {}
}