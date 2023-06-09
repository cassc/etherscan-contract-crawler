// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The World Peek Journey
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//                                      //
//                                      //
//       (             )                //
//     ( )\ (       ( /(   (            //
//     )((_))(   (  )\()) ))\ (         //
//    ((_)_(()\  )\((_)\ /((_))\ )      //
//     | _ )((_)((_) |(_|_)) _(_/(      //
//     | _ \ '_/ _ \ / // -_) ' \))     //
//     |___/_| \___/_\_\\___|_||_|      //
//                                      //
//                                      //
//                                      //
//                                      //
//////////////////////////////////////////


contract TWPJ is ERC1155Creator {
    constructor() ERC1155Creator("The World Peek Journey", "TWPJ") {}
}