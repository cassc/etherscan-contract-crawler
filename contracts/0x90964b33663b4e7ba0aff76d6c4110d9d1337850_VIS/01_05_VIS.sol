// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Viscous
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//          :~7?YYJ7^.                  .^!JYY?7~:          //
//        !5#@@@@@@@@#5~              ~5B&@@@@@@@&5!.       //
//      [email protected]@@@@@@@@@@@@@5.          [email protected]@@@@@@@@@@@@@G:      //
//     [email protected]@@@@@@@@@@@@@@@G.         [email protected]@@@@@@@@@@@@@@@B.     //
//     [email protected]@@@@@@@@@@@@@@@@@!        [email protected]@@@@@@@@@@@@@@@@@!     //
//     [email protected]@@@@@@@@@@@@@@@@@~        [email protected]@@@@@@@@@@@@@@@@@!     //
//      [email protected]@@@@@@@@@@@@@@@5         [email protected]@@@@@@@@@@@@@@@@G.     //
//      .J&@@@@@@@@@@@@&J          [email protected]@@@@@@@@@@@@@@@5.      //
//        :JG#@@@@@@&G?^          [email protected]@@@@@@@@@@@@&GY^        //
//           .^!!!~^.           ^[email protected]@@@@@@@@@&GJ!:           //
//                           .~5&@@@@@@@@@G7:               //
//                       .~?5#@@@@@@@@@@B!                  //
//                    :?P#@@@@@@@@@@@@@G.                   //
//                   ?#@@@@@@@@@@@@@@@&:                    //
//                  [email protected]@@@@@@@@@@@@@@@@P                     //
//                 ^@@@@@@@@@@@@@@@@@@J                     //
//                 [email protected]@@@@@@@@@@@@@@@@@7                     //
//                 [email protected]@@@@@@@@@@@@@@@B.                     //
//                  [email protected]@@@@@@@@@@@@@B^                      //
//                    !P#@@@@@@@@&P7.                       //
//                      .~?Y55Y?!:                          //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract VIS is ERC721Creator {
    constructor() ERC721Creator("Viscous", "VIS") {}
}