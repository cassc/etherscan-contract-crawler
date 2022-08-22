// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sistine
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                          //
//                                                                                                                                                                          //
//    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //
//    //                                                                                                                                                              //    //
//    //                                                                                                                                                              //    //
//    //                                  .::.       .:..   .::.       .:::  ...:::..              ..:.            ::^^:.                                             //    //
//    //                                 .B&&?       !&&#^  P&&5     ^P&&P~ :#&&&&&&##G57:        ?&&&G.       .7P#&&&&&&BY~                                          //    //
//    //                                 .#@@J       [email protected]@@^  [email protected]@P   ^[email protected]@B!   ^@@@[email protected]@@5.     [email protected]@@@@5      ?&@@P7~^^~J#@@G^                                        //    //
//    //                                 .#@@J       [email protected]@@^  [email protected]@5 ^[email protected]@G!     ^&@@!      ~#@@P    ^&@&[email protected]@J    [email protected]@@7       [email protected]@#:                                       //    //
//    //                                 .#@@[email protected]@@^  [email protected]@[email protected]@@#^      ^&@@!       [email protected]@&:  [email protected]@7 [email protected]@@7  .#@@P         :&@@J                                       //    //
//    //                                 .#@@[email protected]@@^  [email protected]@@@[email protected]@&7     ^&@@!       [email protected]@@^  [email protected]@Y   [email protected]@&^ .#@@P         :&@@J                                       //    //
//    //                                 .#@@J       [email protected]@@^  [email protected]@#~  !#@@P:   ^&@@!      ^#@@G  [email protected]@@[email protected]@@#: [email protected]@&~        [email protected]@&^                                       //    //
//    //                                 .#@@J       [email protected]@@^  [email protected]@5    :[email protected]@&7  ^&@@?:^^~75&@@P: [email protected]@#[email protected]@G  [email protected]@@5~:..^[email protected]@#~                                        //    //
//    //                                 .#@@J       [email protected]@&^  [email protected]@5      7&@@5.:&@@@&&&&&#GJ~  ~&@&!       ^#@@5  ^JB&@&&&@@#P7.                                         //    //
//    //                                  :^^.       .^^^   :^^:       :^^^. :^^^^^::.      :^^:         :^^^     .^~~~^:.                                            //    //
//    //                                                                                                                                                              //    //
//    //                                                                                                                                                              //    //
//    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //
//                                                                                                                                                                          //
//                                                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Sistine is ERC721Creator {
    constructor() ERC721Creator("Sistine", "Sistine") {}
}