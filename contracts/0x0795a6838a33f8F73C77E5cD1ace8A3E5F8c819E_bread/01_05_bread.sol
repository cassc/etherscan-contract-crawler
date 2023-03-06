// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: fancybread
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////
//                                                                              //
//                                                                              //
//            :^[email protected]@@@@@@@@@@@@@@@[email protected]@@@!:. @@@@^:[email protected]@@@~:[email protected]@@@^.            //
//        [email protected]@@@@@@@@@@@@@@@@@@@@@@@^[email protected]@@@?:[email protected]@@@!.:[email protected]@@@?^[email protected]@@P~         //
//       7#@@@@@@@@@@@@@@@@@@@@@@@@@@@@P: [email protected]@@@&Y. [email protected]@@@#7 :[email protected]@@@P: [email protected]@@G~      //
//      [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#^ [email protected]@@@@B. [email protected]@@@@Y .#@@@@#^ [email protected]@@@~     //
//    :&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@5 :&@@@@@? [email protected]@@@@@^ [email protected]@@@@5 :&@@@G      //
//    :&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@5 .&@@@@@J ^@@@@@@^ [email protected]@@@@5 .&@@@B      //
//     ?&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B^ [email protected]@@@@G. [email protected]@@@@J [email protected]@@@B^ [email protected]@@&!      //
//      :?#@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@5~ :[email protected]@@&?^ [email protected]@@[email protected]@G7:       //
//       ^#@@@@@@@@@@@@@@@@@@@@@@@@@@Y: ^#@@@@?. !&@@@#~  [email protected]@@@Y: ^#@@P:        //
//     :[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@? :[email protected]@@@&7 ^&@@@@B: [email protected]@@@@? :[email protected]@@Y       //
//     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@! [email protected]@@@@@^ [email protected]@@@@G  [email protected]@@@@! [email protected]@@@J      //
//     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B  [email protected]@@@@5 .#@@@@@! [email protected]@@@@B  [email protected]@@&:    //
//     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@^ [email protected]@@@@&: [email protected]@@@@P .#@@@@@^ [email protected]@@@7    //
//     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@7 [email protected]@@@@@~ [email protected]@@@@B. [email protected]@@@@7 [email protected]@@@Y    //
//    .#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@J ^@@@@@@7 [email protected]@@@@&: [email protected]@@@@J ^@@@@P    //
//    :&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Y :&@@@@@? [email protected]@@@@&: [email protected]@@@@Y :&@@@G    //
//    :&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@5 :&@@@@@? [email protected]@@@@&^ [email protected]@@@@5 :&@@@G    //
//    .#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Y :&@@@@@7 [email protected]@@@@&: [email protected]@@@@Y :&@@@P    //
//     :YBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBP7 .5BBBBP~ :GBBBBY: !BBBBP7 .5BBG?.    //
//                                                                              //
//                                                                              //
//////////////////////////////////////////////////////////////////////////////////


contract bread is ERC1155Creator {
    constructor() ERC1155Creator("fancybread", "bread") {}
}